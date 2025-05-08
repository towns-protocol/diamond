// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interfaces
import {Vm} from "forge-std/Vm.sol";

// libraries
import {LibDeploy} from "../../src/utils/LibDeploy.sol";
import {LibClone} from "solady/utils/LibClone.sol";
import {LibString} from "solady/utils/LibString.sol";

// contracts
import {DeployBase} from "./DeployBase.s.sol";

contract DeployFacet is DeployBase {
    using LibString for *;

    /// @dev Constants for gas estimation
    uint256 internal constant BLOCK_GAS_LIMIT = 30_000_000;
    uint256 internal constant BASE_TX_COST = 21_000;
    uint256 internal constant CONTRACT_CREATION_COST = 32_000;
    uint256 internal constant STORAGE_VARIABLE_COST = 22_100;
    uint256 internal constant DEPLOYED_BYTECODE_COST_PER_BYTE = 200;

    /// @dev Queue for batch deployments
    string[] internal deploymentQueue;
    bytes32[] internal saltQueue;

    /// @dev Cache for init code hashes to avoid recomputing
    mapping(string => bytes32) internal initCodeHashes;

    string private artifactPath;

    /// @dev Cache for artifact paths to avoid redundant lookups
    mapping(string => string) private artifactPathCache;

    /// @notice Running total of estimated gas for deployment batch
    uint256 public batchGasEstimate;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         DEPLOYMENT                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Deploys a facet contract using the contract name from environment variables
    /// @dev This function:
    ///      - Reads CONTRACT_NAME from environment variables
    ///      - Constructs the artifact path and version name
    ///      - Uses DeployBase's deploy function with a curried deployment wrapper
    /// @return The address of the deployed facet contract
    function run() external returns (address) {
        string memory name = vm.envString("CONTRACT_NAME");
        return deploy(name, msg.sender);
    }

    /// @notice Deploys a facet contract using the provided name and deployer address
    function deploy(
        string memory name,
        address deployer
    )
        public
        broadcastWith(deployer)
        returns (address)
    {
        artifactPath = getArtifactPath(name);
        string memory versionName = string.concat("facets/", name);

        // call the base deploy function with our curried function
        return deploy(deployer, versionName, _deployWrapper);
    }

    /// @notice Add a contract to the deployment queue with default salt (0)
    /// @param name Name of the contract to queue
    function add(string memory name) public {
        add(name, bytes32(0));
    }

    /// @notice Add a contract to the deployment queue if it's not already deployed
    /// @param name Name of the contract to queue
    /// @param salt The salt to use for CREATE2 deployment
    function add(string memory name, bytes32 salt) public {
        // check if we already have the init code hash cached
        bytes32 initCodeHash = initCodeHashes[name];

        // if not cached, get bytecode and cache its hash
        bytes memory bytecode;
        if (initCodeHash == bytes32(0)) {
            bytecode = vm.getCode(getArtifactPath(name));
            initCodeHash = keccak256(bytecode);
            initCodeHashes[name] = initCodeHash;
        }

        // only add to queue if not already deployed
        if (isDeployed(name, salt)) return;

        // get bytecode for gas estimation if we didn't already load it
        // i.e. if adding the same contract multiple times
        if (bytecode.length == 0) {
            bytecode = vm.getCode(getArtifactPath(name));
        }

        // estimate gas cost for this deployment
        batchGasEstimate += estimateDeploymentGas(bytecode);

        // check if adding this contract would exceed block gas limit
        if (batchGasEstimate > BLOCK_GAS_LIMIT) {
            warn(
                string.concat(
                    "DeployFacet: Adding contract ",
                    name,
                    " may exceed block gas limit 30_000_000. Deploy current batch first."
                )
            );
        }

        // add to the queue and update gas estimate
        deploymentQueue.push(name);
        saltQueue.push(salt);
    }

    /// @notice Deploy all contracts in the queue using batch deployment
    /// @param deployer Address to deploy from
    function deployBatch(address deployer) external broadcastWith(deployer) {
        uint256 queueLength = deploymentQueue.length;
        if (queueLength == 0) return;

        if (!isTesting()) {
            require(MULTICALL3_ADDRESS.code.length > 0, "DeployFacet: Multicall3 is not deployed");

            info(
                string.concat(
                    unicode"batch deploying \n\t📜 ",
                    queueLength.toString(),
                    " contracts",
                    unicode"\n\t⚡️ on ",
                    chainIdAlias(),
                    unicode"\n\t📬 from deployer address",
                    unicode"\n\t⛽ estimated gas: ",
                    batchGasEstimate.toString()
                ),
                deployer.toHexStringChecksummed()
            );

            // log each contract being deployed
            for (uint256 i; i < queueLength; ++i) {
                string memory name = deploymentQueue[i];
                bytes32 salt = saltQueue[i];
                string memory saltStr = uint256(salt).toMinimalHexString();
                debug(string.concat("  ", unicode"📄 ", name, " (", saltStr, ")"));
            }
        } else {
            if (MULTICALL3_ADDRESS.code.length == 0) {
                debug(unicode"🔄 Deploying Multicall3");
                vm.etch(MULTICALL3_ADDRESS, LibDeploy.MULTICALL3_BYTECODE);
            }
        }

        bytes[] memory bytecodes = new bytes[](queueLength);
        bytes32[] memory salts = new bytes32[](queueLength);

        for (uint256 i; i < queueLength; ++i) {
            string memory name = deploymentQueue[i];
            string memory path = getArtifactPath(name);
            bytecodes[i] = vm.getCode(path);
            salts[i] = saltQueue[i];
        }

        address[] memory deployedAddresses = LibDeploy.deployMultiple(bytecodes, salts);

        if (!isTesting()) {
            // log successful deployments
            for (uint256 i; i < queueLength; ++i) {
                string memory name = deploymentQueue[i];
                address deployedAddr = deployedAddresses[i];

                info(
                    string.concat(unicode"✅ ", name, " deployed at"),
                    deployedAddr.toHexStringChecksummed()
                );
            }
        }

        clearQueue();
    }

    /// @notice Clear the deployment queue without deploying
    function clearQueue() public {
        delete deploymentQueue;
        delete saltQueue;
        batchGasEstimate = 0;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           GETTERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Get the artifact path for a contract name with validation and caching
    function getArtifactPath(string memory name) public returns (string memory) {
        // check cache first
        string memory cachedPath = artifactPathCache[name];
        if (bytes(cachedPath).length > 0) return cachedPath;

        // try the standard path first
        string memory standardPath = string.concat(outDir(), "/", name, ".sol/", name, ".json");
        if (vm.exists(standardPath)) {
            artifactPathCache[name] = standardPath;
            return standardPath;
        }

        // if standard path doesn't exist, search all artifacts
        // depth 2 for out/ContractDir/Contract.json
        Vm.DirEntry[] memory entries = vm.readDir(outDir(), 2);
        string memory jsonFileName = string.concat("/", name, ".json");

        for (uint256 i; i < entries.length; ++i) {
            Vm.DirEntry memory entry = entries[i];

            // skip directories and files with errors
            if (entry.isDir || bytes(entry.errorMessage).length > 0) continue;

            // check if filename matches
            if (entry.path.endsWith(jsonFileName)) {
                debug(string.concat("DeployFacet: Found artifact for ", name, " at ", entry.path));
                artifactPathCache[name] = entry.path;
                return entry.path;
            }
        }

        // no matching artifact found
        revert(
            string.concat(
                "DeployFacet: Could not find artifact for '",
                name,
                "'. Ensure the contract exists and has been compiled."
            )
        );
    }

    /// @notice Get the current deployment queue
    /// @return names Array of contract names in the queue
    /// @return salts Array of salts for each contract
    /// @return gasEstimate Current estimated gas for the batch
    function getQueue()
        external
        view
        returns (string[] memory names, bytes32[] memory salts, uint256 gasEstimate)
    {
        return (deploymentQueue, saltQueue, batchGasEstimate);
    }

    /// @notice Get the deployed address for a contract by name using default salt (0)
    /// @param name Name of the contract
    /// @return The deployed address of the contract (address(0) if not deployed)
    function getDeployedAddress(string memory name) public returns (address) {
        return getDeployedAddress(name, bytes32(0));
    }

    /// @notice Get the deployed address for a contract by name and salt
    /// @param name Name of the contract
    /// @param salt The salt used for deployment
    /// @return The deployed address of the contract (address(0) if not deployed)
    function getDeployedAddress(string memory name, bytes32 salt) public returns (address) {
        address predictedAddress = predictAddress(name, salt);

        // check if the contract is actually deployed at this address
        if (predictedAddress.code.length > 0) return predictedAddress;

        return address(0); // not deployed
    }

    /// @notice Predict the address where a contract would be deployed using default salt (0)
    /// @param name Name of the contract
    /// @return The predicted address where the contract would be deployed
    function predictAddress(string memory name) public returns (address) {
        return predictAddress(name, bytes32(0));
    }

    /// @notice Predict the address where a contract would be deployed
    /// @param name Name of the contract
    /// @param salt The salt to use for deployment
    /// @return The predicted address where the contract would be deployed
    function predictAddress(string memory name, bytes32 salt) public returns (address) {
        bytes32 initCodeHash = initCodeHashes[name];
        // check if we have the init code hash cached
        if (initCodeHash == bytes32(0)) {
            initCodeHash = keccak256(vm.getCode(getArtifactPath(name)));
        }
        return LibClone.predictDeterministicAddress(initCodeHash, salt, CREATE2_FACTORY);
    }

    /// @notice Check if a contract is deployed
    /// @param name Name of the contract
    /// @return True if deployed, false otherwise
    function isDeployed(string memory name) public returns (bool) {
        return getDeployedAddress(name) != address(0);
    }

    /// @notice Check if a contract is deployed with a specific salt
    /// @param name Name of the contract
    /// @param salt The salt used for deployment
    /// @return True if deployed, false otherwise
    function isDeployed(string memory name, bytes32 salt) public returns (bool) {
        return getDeployedAddress(name, salt) != address(0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           INTERNAL                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Wrapper function that captures artifactPath in its closure
    function _deployWrapper(address) internal returns (address) {
        return LibDeploy.deployCode(artifactPath, "");
    }

    /// @notice Estimate gas cost for deploying a contract
    /// @param bytecode The contract bytecode
    /// @return gas Estimated gas cost
    function estimateDeploymentGas(bytes memory bytecode) internal view returns (uint256 gas) {
        if (deploymentQueue.length == 0) gas = BASE_TX_COST;
        gas += CONTRACT_CREATION_COST + STORAGE_VARIABLE_COST
            + bytecode.length * DEPLOYED_BYTECODE_COST_PER_BYTE;
    }
}
