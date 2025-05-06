// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

//libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";

//contracts
import {MultiInit} from "../../../src/initializers/MultiInit.sol";

library DeployMultiInit {
    function deploy() internal returns (address) {
        return LibDeploy.deployCode("MultiInit.sol", "");
    }

    function makeInitData(
        address[] memory initAddresses,
        bytes[] memory initDatas
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(MultiInit.multiInit, (initAddresses, initDatas));
    }
}
