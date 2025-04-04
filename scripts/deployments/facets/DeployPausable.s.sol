// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces

//libraries

//contracts
import {PausableFacet} from "../../../src/facets/pausable/PausableFacet.sol";
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "../../common/helpers/FacetHelper.s.sol";

contract DeployPausable is FacetHelper, SimpleDeployer {
    constructor() {
        addSelector(PausableFacet.pause.selector);
        addSelector(PausableFacet.unpause.selector);
        addSelector(PausableFacet.paused.selector);
    }

    function versionName() public pure override returns (string memory) {
        return "pausableFacet";
    }

    function __deploy(address deployer) public override returns (address) {
        vm.startBroadcast(deployer);
        PausableFacet facet = new PausableFacet();
        vm.stopBroadcast();
        return address(facet);
    }

    function initializer() public pure override returns (bytes4) {
        return PausableFacet.__Pausable_init.selector;
    }
}
