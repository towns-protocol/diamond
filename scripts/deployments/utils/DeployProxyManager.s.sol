// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces

//libraries

//contracts
import {ProxyManager} from "../../../src/proxy/manager/ProxyManager.sol";
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "../../common/helpers/FacetHelper.s.sol";

contract DeployProxyManager is FacetHelper, SimpleDeployer {
    constructor() {
        addSelector(ProxyManager.getImplementation.selector);
        addSelector(ProxyManager.setImplementation.selector);
    }

    function initializer() public pure override returns (bytes4) {
        return ProxyManager.__ProxyManager_init.selector;
    }

    function makeInitData(address implementation) public pure returns (bytes memory) {
        return abi.encodeWithSelector(initializer(), implementation);
    }

    function versionName() public pure override returns (string memory) {
        return "proxyManagerFacet";
    }

    function __deploy(address deployer) public override returns (address) {
        vm.startBroadcast(deployer);
        ProxyManager proxyManager = new ProxyManager();
        vm.stopBroadcast();
        return address(proxyManager);
    }
}
