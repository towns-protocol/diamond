// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

// libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";

// contracts
import {ERC1271Facet} from "../../../src/facets/accounts/ERC1271Facet.sol";

library DeployERC1271 {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](3);
        _selectors[0] = ERC1271Facet.isValidSignature.selector;
        _selectors[1] = ERC1271Facet.erc1271Signer.selector;
        _selectors[2] = bytes4(keccak256("__ERC1271_init(address)"));
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
        return abi.encodeWithSelector(bytes4(keccak256("__ERC1271_init(address)")), signer);
    }

    function deploy() internal returns (address) {
        return LibDeploy.deployCode("ERC1271Facet.sol", "");
    }
}
