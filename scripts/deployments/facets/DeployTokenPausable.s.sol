// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";

//contracts
import {TokenPausableFacet} from "../../../src/facets/pausable/token/TokenPausableFacet.sol";

library DeployTokenPausable {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](3);
        _selectors[0] = TokenPausableFacet.pause.selector;
        _selectors[1] = TokenPausableFacet.unpause.selector;
        _selectors[2] = TokenPausableFacet.paused.selector;
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
        return abi.encodeCall(TokenPausableFacet.__Pausable_init, ());
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("TokenPausableFacet.sol", "");
    }
}
