// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces

// libraries

// contracts
import {ERC721} from "../../src/facets/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() {
        __ERC721_init_unchained("MockERC721", "MKR");
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
