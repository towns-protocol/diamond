// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces

// libraries

// contracts
import {ERC721} from "solady/tokens/ERC721.sol";

contract MockToken is ERC721 {
    uint256 public tokenId;

    function name() public pure override returns (string memory) {
        return "MockToken";
    }

    function symbol() public pure override returns (string memory) {
        return "MTK";
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "MockTokenURI";
    }

    function mintTo(address to) external returns (uint256) {
        tokenId++;
        _mint(to, tokenId);
        return tokenId;
    }

    function mint(address to, uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            _mint(to, tokenId);
            tokenId++;
        }
    }

    function burn(uint256 token) external {
        _burn(token);
    }
}
