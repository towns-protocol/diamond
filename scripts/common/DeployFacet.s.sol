// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interfaces
import {Vm} from "forge-std/Vm.sol";

// libraries
import {LibDeploy} from "../../src/utils/LibDeploy.sol";
import {DynamicArrayLib} from "solady/utils/DynamicArrayLib.sol";
import {LibClone} from "solady/utils/LibClone.sol";
import {LibString} from "solady/utils/LibString.sol";

// contracts
import {DeployBase} from "./DeployBase.s.sol";

contract DeployFacet is DeployBase {
    using LibString for *;
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;

    /// @dev Constants for gas estimation
    uint256 internal constant PER_TRANSACTION_GAS_LIMIT = 1 << 24; // gas limit per EIP-7825
    uint256 internal constant BASE_TX_COST = 21_000;
    uint256 internal constant CONTRACT_CREATION_COST = 32_000;
    uint256 internal constant STORAGE_VARIABLE_COST = 22_100;
    uint256 internal constant DEPLOYED_BYTECODE_COST_PER_BYTE = 200;

    /// @dev Entry in the deployment queue
    struct Deployment {
        string name;
        bytes32 salt;
        uint256 gasEstimate;
        address addr;
    }

    /// @dev Queue for batch deployments
    Deployment[] internal deploymentQueue;

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
        uint256 contractGas = estimateDeploymentGas(bytecode);
        batchGasEstimate += contractGas;

        // compute predicted address
        address predicted =
            LibClone.predictDeterministicAddress(initCodeHash, salt, CREATE2_FACTORY);

        // add to the queue
        deploymentQueue.push(Deployment(name, salt, contractGas, predicted));
    }

    /// @notice Deploy all contracts in the queue, automatically splitting into batches if needed
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

            for (uint256 i; i < queueLength; ++i) {
                Deployment storage entry = deploymentQueue[i];
                string memory saltStr = uint256(entry.salt).toMinimalHexString();
                debug(string.concat("  ", unicode"📄 ", entry.name, " (", saltStr, ")"));
            }
        } else {
            if (MULTICALL3_ADDRESS.code.length == 0) {
                debug(unicode"🔄 Deploying Multicall3");
                vm.etch(MULTICALL3_ADDRESS, LibDeploy.MULTICALL3_BYTECODE);
            }
        }

        // Calculate batch boundaries and deploy each batch
        uint256[] memory batchEndIndices = _calculateBatchBoundaries();
        uint256 startIdx;
        for (uint256 i; i < batchEndIndices.length; ++i) {
            uint256 endIdx = batchEndIndices[i];
            _deploySingleBatch(startIdx, endIdx);
            startIdx = endIdx;
        }

        clearQueue();
    }

    /// @notice Clear the deployment queue without deploying
    function clearQueue() public {
        delete deploymentQueue;
        batchGasEstimate = 0;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           GETTERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Get the artifact path for a contract name with validation and caching
    function getArtifactPath(string memory name) public returns (string memory path) {
        // check cache first
        string memory cachedPath = artifactPathCache[name];
        if (bytes(cachedPath).length > 0) return cachedPath;

        // if not in cache, use LibDeploy.getArtifactPath and cache the result
        path = LibDeploy.getArtifactPath(outDir(), name);
        debug(string.concat("DeployFacet: Found artifact for ", name, " at ", path));

        // cache the result for future use
        artifactPathCache[name] = path;
    }

    /// @notice Get the current deployment queue
    /// @return entries Array of deployments with predicted addresses
    /// @return totalGasEstimate Total estimated gas for all contracts
    function getQueue()
        external
        view
        returns (Deployment[] memory entries, uint256 totalGasEstimate)
    {
        return (deploymentQueue, batchGasEstimate);
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
    function _deployWrapper(address) private returns (address) {
        return LibDeploy.deployCode(artifactPath, "");
    }

    /// @notice Estimate gas cost for deploying a contract (excluding base tx cost)
    /// @dev BASE_TX_COST is handled per-batch in _calculateBatchBoundaries
    /// @param bytecode The contract bytecode
    /// @return gas Estimated gas cost for this contract only
    function estimateDeploymentGas(bytes memory bytecode) internal pure returns (uint256 gas) {
        gas = CONTRACT_CREATION_COST + STORAGE_VARIABLE_COST + bytecode.length
            * DEPLOYED_BYTECODE_COST_PER_BYTE;
    }

    /// @notice Calculate batch boundaries based on gas limits
    /// @return batchEndIndices Array of end indices (exclusive) for each batch
    function _calculateBatchBoundaries() private view returns (uint256[] memory batchEndIndices) {
        uint256 queueLength = deploymentQueue.length;
        if (queueLength == 0) return new uint256[](0);

        DynamicArrayLib.DynamicArray memory arr = DynamicArrayLib.p();
        uint256 currentBatchGas = BASE_TX_COST;

        for (uint256 i; i < queueLength; ++i) {
            uint256 contractGas = deploymentQueue[i].gasEstimate;

            // check if adding this contract would exceed limit
            if (currentBatchGas + contractGas > PER_TRANSACTION_GAS_LIMIT) {
                // start new batch (unless this is the first contract in current batch)
                if (currentBatchGas > BASE_TX_COST) {
                    arr.p(i);
                    currentBatchGas = BASE_TX_COST;
                }
            }
            currentBatchGas += contractGas;
        }
        arr.p(queueLength); // final batch ends at queue length

        batchEndIndices = arr.asUint256Array();
    }

    /// @notice Deploy a subset of the queue as a single batch
    /// @param startIdx Start index (inclusive)
    /// @param endIdx End index (exclusive)
    function _deploySingleBatch(uint256 startIdx, uint256 endIdx) private {
        uint256 batchSize = endIdx - startIdx;

        // prepare bytecodes and salts for this batch
        bytes[] memory bytecodes = new bytes[](batchSize);
        bytes32[] memory salts = new bytes32[](batchSize);

        for (uint256 i = startIdx; i < endIdx; ++i) {
            Deployment storage entry = deploymentQueue[i];
            bytecodes[i - startIdx] = vm.getCode(getArtifactPath(entry.name));
            salts[i - startIdx] = entry.salt;
        }

        // deploy via Multicall3
        address[] memory deployedAddresses = LibDeploy.deployMultiple(bytecodes, salts);

        // log successful deployments
        if (!isTesting()) {
            for (uint256 i; i < batchSize; ++i) {
                info(
                    string.concat(
                        unicode"✅ ", deploymentQueue[startIdx + i].name, " deployed at"
                    ),
                    deployedAddresses[i].toHexStringChecksummed()
                );
            }
        }
    }
}
