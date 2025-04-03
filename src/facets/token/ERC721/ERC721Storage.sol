// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries
import {MinimalERC721Storage} from "../../../primitive/ERC721.sol";

// contracts

library ERC721Storage {
    // keccak256(abi.encode(uint256(keccak256("diamond.facets.token.ERC721")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 internal constant STORAGE_SLOT =
        0xb3935e6a49215857160396d02e0af5246d59e8af6ff7be9c479686d5bc4bee00;

    struct Layout {
        MinimalERC721Storage inner;
        string name;
        string symbol;
    }

    function layout() internal pure returns (Layout storage l) {
        assembly {
            l.slot := STORAGE_SLOT
        }
    }
}
