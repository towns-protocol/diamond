// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";
import {DynamicArrayLib} from "solady/utils/DynamicArrayLib.sol";

//contracts
import {OwnablePendingFacet} from "../../../src/facets/ownable/pending/OwnablePendingFacet.sol";

library DeployOwnablePending {
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;

    function selectors() internal pure returns (bytes4[] memory res) {
        DynamicArrayLib.DynamicArray memory arr = DynamicArrayLib.p().reserve(4);
        arr.p(OwnablePendingFacet.startTransferOwnership.selector);
        arr.p(OwnablePendingFacet.acceptOwnership.selector);
        arr.p(OwnablePendingFacet.currentOwner.selector);
        arr.p(OwnablePendingFacet.pendingOwner.selector);
        bytes32[] memory selectors_ = arr.asBytes32Array();
        assembly ("memory-safe") {
            res := selectors_
        }
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
        return DeployLib.deployCode("OwnablePendingFacet.sol", "");
    }
}
