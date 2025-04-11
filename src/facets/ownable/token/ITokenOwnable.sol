// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces

// libraries

// contracts
import {IOwnableBase} from "../IERC173.sol";

interface ITokenOwnableBase is IOwnableBase {
    struct TokenOwnable {
        address collection;
        uint256 tokenId;
    }
}

interface ITokenOwnable is ITokenOwnableBase {}
