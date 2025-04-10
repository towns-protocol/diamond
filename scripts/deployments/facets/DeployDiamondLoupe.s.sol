// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";

//contracts
import {DiamondLoupeFacet} from "../../../src/facets/loupe/DiamondLoupeFacet.sol";

library DeployDiamondLoupe {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](4);
        _selectors[0] = DiamondLoupeFacet.facets.selector;
        _selectors[1] = DiamondLoupeFacet.facetAddress.selector;
        _selectors[2] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        _selectors[3] = DiamondLoupeFacet.facetAddresses.selector;
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
