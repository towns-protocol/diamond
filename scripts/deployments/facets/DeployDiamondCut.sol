// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";

//contracts
import {DiamondCutFacet} from "../../../src/facets/cut/DiamondCutFacet.sol";

library DeployDiamondCut {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](1);
        _selectors[0] = DiamondCutFacet.diamondCut.selector;
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
        return abi.encodeCall(DiamondCutFacet.__DiamondCut_init, ());
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("DiamondCutFacet.sol", "");
    }
}
