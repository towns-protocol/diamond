// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";
import {ITokenOwnableBase} from "../../../src/facets/ownable/token/ITokenOwnable.sol";

//libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";

//contracts
import {TokenOwnableFacet} from "../../../src/facets/ownable/token/TokenOwnableFacet.sol";

library DeployTokenOwnable {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](2);
        _selectors[0] = TokenOwnableFacet.owner.selector;
        _selectors[1] = TokenOwnableFacet.transferOwnership.selector;
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

    function makeInitData(ITokenOwnableBase.TokenOwnable memory tokenOwnable)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(TokenOwnableFacet.__TokenOwnable_init, (tokenOwnable));
    }

    function deploy() internal returns (address) {
        return LibDeploy.deployCode("TokenOwnableFacet.sol", "");
    }
}
