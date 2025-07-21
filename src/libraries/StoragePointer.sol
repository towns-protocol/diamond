// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title StoragePointer
 * @dev Library for direct storage slot manipulation of mapping values.
 *
 * Provides wrapper structs and functions to compute storage references for mapping
 * entries without redundant slot calculations. Enables efficient direct storage
 * access patterns commonly used in diamond storage and gas-optimized contracts.
 *
 * The `get()` functions compute storage slots using keccak256(key, mapping.slot) and
 * return struct wrappers that allow direct manipulation of the underlying storage.
 *
 * Usage with syntactic sugar:
 *   using StoragePointer for mapping(bytes32 => bytes);
 *   StoragePointer.Bytes storage ptr = myMapping.get(key);
 *   delete ptr.value; // Direct storage deletion
 *
 * Note: Solidity restricts delete and assignment operations on storage pointers to
 * dynamic types (string/bytes). The struct wrapper pattern enables these operations
 * via struct field access: use wrapper.value for assignment and deletion.
 */
library StoragePointer {
    /// @dev Storage reference wrapper for bytes32 values
    struct Bytes32 {
        bytes32 value;
    }

    /// @dev Storage reference wrapper for uint256 values
    struct Uint256 {
        uint256 value;
    }

    /// @dev Storage reference wrapper for bytes values, required for assignment and deletion
    struct Bytes {
        bytes value;
    }

    /// @dev Storage reference wrapper for string values, required for assignment and deletion
    struct String {
        string value;
    }

    /// @dev Returns storage pointer for mapping(bytes32 => bytes32) at key
    function get(
        mapping(bytes32 => bytes32) storage map,
        bytes32 key
    )
        internal
        pure
        returns (Bytes32 storage ptr)
    {
        assembly ("memory-safe") {
            mstore(0, key)
            mstore(0x20, map.slot)
            ptr.slot := keccak256(0, 0x40)
        }
    }

    /// @dev Returns storage pointer for mapping(bytes32 => uint256) at key
    function get(
        mapping(bytes32 => uint256) storage map,
        bytes32 key
    )
        internal
        pure
        returns (Uint256 storage ptr)
    {
        assembly ("memory-safe") {
            mstore(0, key)
            mstore(0x20, map.slot)
            ptr.slot := keccak256(0, 0x40)
        }
    }

    /// @dev Returns storage pointer for mapping(bytes32 => bytes) at key
    function get(
        mapping(bytes32 => bytes) storage map,
        bytes32 key
    )
        internal
        pure
        returns (Bytes storage ptr)
    {
        assembly ("memory-safe") {
            mstore(0, key)
            mstore(0x20, map.slot)
            ptr.slot := keccak256(0, 0x40)
        }
    }

    /// @dev Returns storage pointer for mapping(bytes32 => string) at key
    function get(
        mapping(bytes32 => string) storage map,
        bytes32 key
    )
        internal
        pure
        returns (String storage ptr)
    {
        assembly ("memory-safe") {
            mstore(0, key)
            mstore(0x20, map.slot)
            ptr.slot := keccak256(0, 0x40)
        }
    }
}
