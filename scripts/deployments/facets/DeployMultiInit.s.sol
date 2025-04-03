// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

//libraries
import {DeployLib} from "../../common/DeployLib.sol";

//contracts
import {MultiInit} from "../../../src/initializers/MultiInit.sol";

library DeployMultiInit {
    function deploy() internal returns (address) {
        return DeployLib.deployCode("MultiInit.sol", "");
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
