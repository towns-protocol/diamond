// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library ERC1271Storage {
    // keccak256(abi.encode(uint256(keccak256("diamond.facets.accounts.erc1271.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 internal constant STORAGE_SLOT =
        0xe208bfd80cbc710d4b3bd6e67400c6fccf276f9b15d4c387c507d953a65f6400;

    struct Layout {
        // Custom signer address if needed for specific implementations
        address signer;
    }

    function layout() internal pure returns (Layout storage ds) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            ds.slot := slot
        }
    }
}
