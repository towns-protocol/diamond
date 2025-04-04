// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces

//libraries

//contracts
import {OwnableFacet} from "../../../src/facets/ownable/OwnableFacet.sol";
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "../../common/helpers/FacetHelper.s.sol";

contract DeployOwnable is FacetHelper, SimpleDeployer {
    constructor() {
        addSelector(OwnableFacet.owner.selector);
        addSelector(OwnableFacet.transferOwnership.selector);
    }

    function versionName() public pure override returns (string memory) {
        return "ownableFacet";
    }

    function __deploy(address deployer) public override returns (address) {
        vm.startBroadcast(deployer);
        OwnableFacet facet = new OwnableFacet();
        vm.stopBroadcast();
        return address(facet);
    }

    function initializer() public pure override returns (bytes4) {
        return OwnableFacet.__Ownable_init.selector;
    }

    function makeInitData(address owner) public pure returns (bytes memory) {
        return abi.encodeWithSelector(OwnableFacet.__Ownable_init.selector, owner);
    }
}
