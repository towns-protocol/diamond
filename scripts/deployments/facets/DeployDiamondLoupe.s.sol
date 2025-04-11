// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";
import {DynamicArrayLib} from "solady/utils/DynamicArrayLib.sol";

//contracts
import {DiamondLoupeFacet} from "../../../src/facets/loupe/DiamondLoupeFacet.sol";

library DeployDiamondLoupe {
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;

    function selectors() internal pure returns (bytes4[] memory res) {
        DynamicArrayLib.DynamicArray memory arr = DynamicArrayLib.p().reserve(4);
        arr.p(DiamondLoupeFacet.facets.selector);
        arr.p(DiamondLoupeFacet.facetAddress.selector);
        arr.p(DiamondLoupeFacet.facetFunctionSelectors.selector);
        arr.p(DiamondLoupeFacet.facetAddresses.selector);
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
        return abi.encodeCall(DiamondLoupeFacet.__DiamondLoupe_init, ());
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("DiamondLoupeFacet.sol", "");
    }
}
