// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";
import {DynamicArrayLib} from "solady/utils/DynamicArrayLib.sol";

//contracts
import {PausableFacet} from "../../../src/facets/pausable/PausableFacet.sol";

library DeployPausable {
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;

    function selectors() internal pure returns (bytes4[] memory res) {
        DynamicArrayLib.DynamicArray memory arr = DynamicArrayLib.p().reserve(3);
        arr.p(PausableFacet.pause.selector);
        arr.p(PausableFacet.unpause.selector);
        arr.p(PausableFacet.paused.selector);
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

    function makeInitData() internal pure returns (bytes memory) {
        return abi.encodeCall(PausableFacet.__Pausable_init, ());
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("PausableFacet.sol", "");
    }
}
