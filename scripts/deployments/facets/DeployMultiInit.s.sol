// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {MultiInit} from "../../../src/initializers/MultiInit.sol";
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";

contract DeployMultiInit is SimpleDeployer {
    function versionName() public pure override returns (string memory) {
        return "multiInit";
    }

    function __deploy(address deployer) public override returns (address) {
        vm.broadcast(deployer);
        return address(new MultiInit());
    }

    function makeInitData(
        address[] memory initAddresses,
        bytes[] memory initDatas
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(MultiInit.multiInit.selector, initAddresses, initDatas);
    }
}
