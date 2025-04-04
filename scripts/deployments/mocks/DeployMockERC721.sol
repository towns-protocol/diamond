// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

// libraries
import {DeployLib} from "../../common/DeployLib.sol";

// contracts
import {ERC721} from "../../../src/facets/token/ERC721/ERC721.sol";
import {MockERC721} from "../../../test/mocks/MockERC721.sol";

library DeployMockERC721 {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](10);
        // ERC721
        _selectors[0] = ERC721.totalSupply.selector;
        _selectors[1] = ERC721.balanceOf.selector;
        _selectors[2] = ERC721.ownerOf.selector;
        _selectors[3] = ERC721.approve.selector;
        _selectors[4] = ERC721.getApproved.selector;
        _selectors[5] = ERC721.setApprovalForAll.selector;
        _selectors[6] = ERC721.isApprovedForAll.selector;
        _selectors[7] = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
        _selectors[8] = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
        _selectors[9] = ERC721.transferFrom.selector;
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

    function makeInitData(
        string memory name,
        string memory symbol
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(ERC721.__ERC721_init, (name, symbol));
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("MockERC721.sol", "");
    }
}
