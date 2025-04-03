// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interfaces

// libraries
import {DeployLib} from "./DeployLib.sol";

// contracts
import {DeployBase} from "./DeployBase.s.sol";

contract DeployFacet is DeployBase {
    string private artifactPath;

    /// @dev Wrapper function that captures artifactPath in its closure
    function _deployWrapper(address) internal returns (address) {
        return DeployLib.deployCode(artifactPath, "");
    }

    /// @notice Deploys a facet contract using the contract name from environment variables
    /// @dev This function:
    ///      - Reads CONTRACT_NAME from environment variables
    ///      - Constructs the artifact path and version name
    ///      - Uses DeployBase's deploy function with a curried deployment wrapper
    /// @return The address of the deployed facet contract
    function run() external broadcastWith(msg.sender) returns (address) {
        string memory name = vm.envString("CONTRACT_NAME");
        artifactPath = string.concat(outDir(), name, ".sol/", name, ".json");
        string memory versionName = string.concat("facets/", name);

        // call the base deploy function with our curried function
        return deploy(msg.sender, versionName, _deployWrapper);
    }
}
