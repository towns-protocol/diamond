// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";

//contracts
import {PausableFacet} from "../../../src/facets/pausable/PausableFacet.sol";

library DeployPausable {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](3);
        _selectors[0] = PausableFacet.pause.selector;
        _selectors[1] = PausableFacet.unpause.selector;
        _selectors[2] = PausableFacet.paused.selector;
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
        return LibDeploy.deployCode("PausableFacet.sol", "");
    }
}
