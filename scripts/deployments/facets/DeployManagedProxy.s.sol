// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces

//libraries

//contracts
import {ManagedProxyFacet} from "../../../src/proxy/managed/ManagedProxyFacet.sol";
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "../../common/helpers/FacetHelper.s.sol";

contract DeployManagedProxy is FacetHelper, SimpleDeployer {
    constructor() {
        addSelector(ManagedProxyFacet.getManager.selector);
        addSelector(ManagedProxyFacet.setManager.selector);
    }

    function initializer() public pure override returns (bytes4) {
        return ManagedProxyFacet.__ManagedProxy_init.selector;
    }

    function versionName() public pure override returns (string memory) {
        return "managedProxyFacet";
    }

    function __deploy(address deployer) public override returns (address) {
        vm.startBroadcast(deployer);
        ManagedProxyFacet managedProxy = new ManagedProxyFacet();
        vm.stopBroadcast();
        return address(managedProxy);
    }
}
