// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

// libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";

// contracts
import {ERC1271Facet} from "../../../src/facets/accounts/ERC1271Facet.sol";

library DeployERC1271Facet {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](2);
        _selectors[0] = ERC1271Facet.isValidSignature.selector;
        _selectors[1] = ERC1271Facet.erc1271Signer.selector;
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

    function makeInitData(address signer) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(ERC1271Facet.__ERC1271_init.selector, signer);
    }

    function deploy() internal returns (address) {
        return LibDeploy.deployCode("ERC1271Facet.sol", "");
    }
}
