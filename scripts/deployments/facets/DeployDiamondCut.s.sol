// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces

//libraries

//contracts
import {DiamondCutFacet} from "../../../src/facets/cut/DiamondCutFacet.sol";
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "../../common/helpers/FacetHelper.s.sol";

contract DeployDiamondCut is FacetHelper, SimpleDeployer {
    constructor() {
        addSelector(DiamondCutFacet.diamondCut.selector);
    }

    function initializer() public pure override returns (bytes4) {
        return DiamondCutFacet.__DiamondCut_init.selector;
    }

    function versionName() public pure override returns (string memory) {
        return "diamondCutFacet";
    }

    function __deploy(address deployer) public override returns (address) {
        vm.startBroadcast(deployer);
        DiamondCutFacet diamondCut = new DiamondCutFacet();
        vm.stopBroadcast();
        return address(diamondCut);
    }
}
