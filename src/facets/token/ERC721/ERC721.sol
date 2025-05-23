// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces

// libraries

import {ERC721Lib, MinimalERC721Storage} from "../../../primitive/ERC721.sol";
import {ERC721Storage} from "./ERC721Storage.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// contracts
import {Facet} from "../../Facet.sol";

abstract contract ERC721 is Facet {
    using ERC721Lib for MinimalERC721Storage;

    function __ERC721_init(
        string memory name_,
        string memory symbol_
    )
        external
        virtual
        onlyInitializing
    {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal virtual {
        ERC721Storage.layout().name = name_;
        ERC721Storage.layout().symbol = symbol_;
    }

    function name() external view virtual returns (string memory) {
        return ERC721Storage.layout().name;
    }

    function symbol() external view virtual returns (string memory) {
        return ERC721Storage.layout().symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        ERC721Storage.layout().inner.requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, Strings.toString(tokenId)) : "";
    }

    function totalSupply() external view virtual returns (uint256) {
        return ERC721Storage.layout().inner.totalSupply;
    }

    function balanceOf(address account) external view virtual returns (uint256) {
        return ERC721Storage.layout().inner.balanceOf(account);
    }

    function ownerOf(uint256 tokenId) external view virtual returns (address) {
        return ERC721Storage.layout().inner.ownerOf(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        external
        virtual
    {
        ERC721Storage.layout().inner.safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual {
        ERC721Storage.layout().inner.safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external virtual {
        ERC721Storage.layout().inner.transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external virtual {
        ERC721Storage.layout().inner.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) external view virtual returns (address) {
        return ERC721Storage.layout().inner.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external virtual {
        ERC721Storage.layout().inner.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(
        address owner,
        address operator
    )
        external
        view
        virtual
        returns (bool)
    {
        return ERC721Storage.layout().inner.isApprovedForAll(owner, operator);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           INTERNAL                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _mint(address to, uint256 tokenId) internal virtual {
        ERC721Storage.layout().inner.mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        ERC721Storage.layout().inner.burn(tokenId);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}
