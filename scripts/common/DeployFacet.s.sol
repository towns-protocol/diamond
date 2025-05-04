// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interfaces

// libraries
import {LibDeploy} from "../../src/utils/LibDeploy.sol";
import {LibClone} from "solady/utils/LibClone.sol";
import {LibString} from "solady/utils/LibString.sol";

// contracts
import {DeployBase} from "./DeployBase.s.sol";

contract DeployFacet is DeployBase {
    using LibString for *;

    /// @dev Queue for batch deployments
    string[] private deploymentQueue;
    bytes32[] private saltQueue;

    /// @dev Cache for init code hashes to avoid recomputing
    mapping(string => bytes32) private initCodeHashes;

    string private artifactPath;

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
        add(name, 0);
    }

    /// @notice Add a contract to the deployment queue if it's not already deployed
    /// @param name Name of the contract to queue
    /// @param salt Optional salt to use for CREATE2 deployment (defaults to bytes32(0) if not provided)
    function add(string memory name, bytes32 salt) public {
        // only add to queue if not already deployed
        if (!isDeployed(name, salt)) {
            deploymentQueue.push(name);
            saltQueue.push(salt);
        }
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
                    unicode"\n\t📬 from deployer address"
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

            // cache the init code hash for this contract for future lookups
            initCodeHashes[name] = keccak256(bytecodes[i]);
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
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           GETTERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Get the current deployment queue
    /// @return names Array of contract names in the queue
    /// @return salts Array of salts for each contract
    function getQueue() external view returns (string[] memory names, bytes32[] memory salts) {
        return (deploymentQueue, saltQueue);
    }

    /// @notice Get the deployed address for a contract by name using default salt (0)
    /// @param name Name of the contract
    /// @return The deployed address of the contract (address(0) if not deployed)
    function getDeployedAddress(string memory name) public view returns (address) {
        return getDeployedAddress(name, 0);
    }

    /// @notice Get the deployed address for a contract by name and salt
    /// @param name Name of the contract
    /// @param salt The salt used for deployment
    /// @return The deployed address of the contract (address(0) if not deployed)
    function getDeployedAddress(string memory name, bytes32 salt) public view returns (address) {
        address predictedAddress;

        // check if we have the init code hash cached
        bytes32 initCodeHash = initCodeHashes[name];
        if (initCodeHash != bytes32(0)) {
            predictedAddress =
                LibClone.predictDeterministicAddress(initCodeHash, salt, CREATE2_FACTORY);
        } else {
            string memory path = getArtifactPath(name);
            bytes memory bytecode = vm.getCode(path);
            predictedAddress =
                LibClone.predictDeterministicAddress(keccak256(bytecode), salt, CREATE2_FACTORY);
        }

        // check if the contract is actually deployed at this address
        if (predictedAddress.code.length > 0) return predictedAddress;

        return address(0); // not deployed
    }

    /// @notice Check if a contract is deployed
    /// @param name Name of the contract
    /// @return True if deployed, false otherwise
    function isDeployed(string memory name) public view returns (bool) {
        return getDeployedAddress(name) != address(0);
    }

    /// @notice Check if a contract is deployed with a specific salt
    /// @param name Name of the contract
    /// @param salt The salt used for deployment
    /// @return True if deployed, false otherwise
    function isDeployed(string memory name, bytes32 salt) public view returns (bool) {
        return getDeployedAddress(name, salt) != address(0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           INTERNAL                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Wrapper function that captures artifactPath in its closure
    function _deployWrapper(address) internal returns (address) {
        return LibDeploy.deployCode(artifactPath, "");
    }

    function getArtifactPath(string memory name) internal pure returns (string memory) {
        return string.concat(outDir(), "/", name, ".sol/", name, ".json");
    }
}
