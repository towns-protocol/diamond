// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";

//contracts
import {IntrospectionFacet} from "../../../src/facets/introspection/IntrospectionFacet.sol";

library DeployIntrospection {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](1);
        _selectors[0] = IntrospectionFacet.supportsInterface.selector;
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
        return abi.encodeCall(IntrospectionFacet.__Introspection_init, ());
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("IntrospectionFacet.sol", "");
    }
}
