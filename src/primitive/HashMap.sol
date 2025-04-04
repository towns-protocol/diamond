/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

using HashMapLib for AddressToUint256Map global;
using HashMapLib for Uint256ToAddressMap global;

struct AddressToUint256Map {
    // no direct access
    uint256 placeholder;
}

struct Uint256ToAddressMap {
    // no direct access
    uint256 placeholder;
}

library HashMapLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     AddressToUint256Map                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function slot(
        AddressToUint256Map storage self,
        address key
    )
        internal
        pure
        returns (uint256 _slot)
    {
        assembly ("memory-safe") {
            mstore(0, key)
            mstore(0x20, self.slot)
            _slot := keccak256(0, 0x40)
        }
    }

    function get(
        AddressToUint256Map storage self,
        address key
    )
        internal
        view
        returns (uint256 value)
    {
        uint256 _slot = self.slot(key);
        assembly ("memory-safe") {
            value := sload(_slot)
        }
    }

    function set(AddressToUint256Map storage self, address key, uint256 value) internal {
        uint256 _slot = self.slot(key);
        assembly ("memory-safe") {
            sstore(_slot, value)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     Uint256ToAddressMap                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function slot(
        Uint256ToAddressMap storage self,
        uint256 key
    )
        internal
        pure
        returns (uint256 _slot)
    {
        assembly ("memory-safe") {
            mstore(0, key)
            mstore(0x20, self.slot)
            _slot := keccak256(0, 0x40)
        }
    }

    function get(
        Uint256ToAddressMap storage self,
        uint256 key
    )
        internal
        view
        returns (address value)
    {
        uint256 _slot = self.slot(key);
        assembly ("memory-safe") {
            value := sload(_slot)
        }
    }

    function set(Uint256ToAddressMap storage self, uint256 key, address value) internal {
        uint256 _slot = self.slot(key);
        assembly ("memory-safe") {
            sstore(_slot, value)
        }
    }
}
