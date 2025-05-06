// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";

//contracts
import {OwnablePendingFacet} from "../../../src/facets/ownable/pending/OwnablePendingFacet.sol";

library DeployOwnablePending {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](4);
        _selectors[0] = OwnablePendingFacet.startTransferOwnership.selector;
        _selectors[1] = OwnablePendingFacet.acceptOwnership.selector;
        _selectors[2] = OwnablePendingFacet.currentOwner.selector;
        _selectors[3] = OwnablePendingFacet.pendingOwner.selector;
    }

    function makeCut(
        address facetAddress,
        IDiamond.FacetCutAction action
    )
        internal
        pure
        returns (IDiamond.FacetCut memory)
    {
        return IDiamond.FacetCut({
            action: action,
            facetAddress: facetAddress,
            functionSelectors: selectors()
        });
    }

    function makeInitData(address owner) internal pure returns (bytes memory) {
        return abi.encodeCall(OwnablePendingFacet.__OwnablePending_init, (owner));
    }

    function deploy() internal returns (address) {
        return LibDeploy.deployCode("OwnablePendingFacet.sol", "");
    }
}
