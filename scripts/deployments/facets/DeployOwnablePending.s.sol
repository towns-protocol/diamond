// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces

//libraries

//contracts
import {OwnablePendingFacet} from "../../../src/facets/ownable/pending/OwnablePendingFacet.sol";
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "../../common/helpers/FacetHelper.s.sol";

contract DeployOwnablePending is FacetHelper, SimpleDeployer {
    constructor() {
        addSelector(OwnablePendingFacet.startTransferOwnership.selector);
        addSelector(OwnablePendingFacet.acceptOwnership.selector);
        addSelector(OwnablePendingFacet.currentOwner.selector);
        addSelector(OwnablePendingFacet.pendingOwner.selector);
    }

    function versionName() public pure override returns (string memory) {
        return "ownablePendingFacet";
    }

    function __deploy(address deployer) public override returns (address) {
        vm.startBroadcast(deployer);
        OwnablePendingFacet facet = new OwnablePendingFacet();
        vm.stopBroadcast();
        return address(facet);
    }

    function initializer() public pure override returns (bytes4) {
        return OwnablePendingFacet.__OwnablePending_init.selector;
    }

    function makeInitData(address owner) public pure returns (bytes memory) {
        return abi.encodeWithSelector(OwnablePendingFacet.__OwnablePending_init.selector, owner);
    }
}
