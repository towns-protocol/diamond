// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

// libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";
import {DynamicArrayLib} from "solady/utils/DynamicArrayLib.sol";

// contracts
import {ERC721} from "../../../src/facets/token/ERC721/ERC721.sol";
import {MockERC721} from "../../../test/mocks/MockERC721.sol";

library DeployMockERC721 {
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;

    function selectors() internal pure returns (bytes4[] memory res) {
        DynamicArrayLib.DynamicArray memory arr = DynamicArrayLib.p().reserve(10);
        arr.p(ERC721.totalSupply.selector);
        arr.p(ERC721.balanceOf.selector);
        arr.p(ERC721.ownerOf.selector);
        arr.p(ERC721.approve.selector);
        arr.p(ERC721.getApproved.selector);
        arr.p(ERC721.setApprovalForAll.selector);
        arr.p(ERC721.isApprovedForAll.selector);
        arr.p(bytes4(keccak256("safeTransferFrom(address,address,uint256)")));
        arr.p(bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")));
        arr.p(ERC721.transferFrom.selector);

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
            action: action, facetAddress: facetAddress, functionSelectors: selectors()
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
        return LibDeploy.deployCode("MockERC721.sol", "");
    }
}
