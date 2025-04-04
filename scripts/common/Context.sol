// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CommonBase} from "forge-std/Base.sol";

abstract contract Context is CommonBase {
    function isAnvil() internal view virtual returns (bool) {
        return block.chainid == 31_337 || block.chainid == 31_338;
    }

    function getDeploymentContext() internal view returns (string memory) {
        return vm.envOr("DEPLOYMENT_CONTEXT", string(""));
    }

    function shouldSaveDeployments() internal view returns (bool) {
        return vm.envOr("SAVE_DEPLOYMENTS", uint256(0)) != 0;
    }

    function isTesting() internal view virtual returns (bool) {
        return vm.envOr("IN_TESTING", false);
    }
}
