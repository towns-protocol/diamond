// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {StoragePointer} from "../../src/libraries/StoragePointer.sol";
import {TestUtils} from "../TestUtils.sol";

contract StoragePointerTest is TestUtils {
    mapping(bytes32 => uint256) private uint256Mapping;
    mapping(bytes32 => bytes) private bytesMapping;
    mapping(bytes32 => bytes32) private bytes32Mapping;
    mapping(bytes32 => string) private stringMapping;

    function test_get_bytes32_uint256(bytes32 key, uint256 value) public {
        // Get storage reference and assign value
        StoragePointer.Uint256 storage ref = StoragePointer.get(uint256Mapping, key);
        ref.value = value;

        // Verify storage consistency
        assertEq(uint256Mapping[key], value, "Storage assignment failed");
        assertEq(ref.value, value, "Storage reference inconsistent");

        // Test deletion
        delete ref.value;
        assertEq(uint256Mapping[key], 0, "Deletion failed");
        assertEq(ref.value, 0, "Storage reference after deletion inconsistent");
    }

    function test_get_bytes32_bytes32(bytes32 key, bytes32 value) public {
        // Get storage reference and assign value
        StoragePointer.Bytes32 storage ref = StoragePointer.get(bytes32Mapping, key);
        ref.value = value;

        // Verify storage consistency
        assertEq(bytes32Mapping[key], value, "Storage assignment failed");
        assertEq(ref.value, value, "Storage reference inconsistent");

        // Test deletion
        delete ref.value;
        assertEq(bytes32Mapping[key], bytes32(0), "Deletion failed");
        assertEq(ref.value, bytes32(0), "Storage reference after deletion inconsistent");
    }

    function test_get_bytes32_bytes(bytes32 key, bytes memory value) public {
        // Get storage reference and assign value
        StoragePointer.Bytes storage ref = StoragePointer.get(bytesMapping, key);
        ref.value = value;

        // Verify storage consistency
        assertEq(bytesMapping[key], value, "Storage assignment failed");
        assertEq(ref.value, value, "Storage reference inconsistent");

        // Test deletion via struct field
        delete ref.value;
        assertEq(bytesMapping[key], "", "Deletion failed");
        assertEq(ref.value, "", "Storage reference after deletion inconsistent");
    }

    function test_get_bytes32_string(bytes32 key, string memory value) public {
        // Get storage reference and assign value
        StoragePointer.String storage ref = StoragePointer.get(stringMapping, key);
        ref.value = value;

        // Verify storage consistency
        assertEq(stringMapping[key], value, "Storage assignment failed");
        assertEq(ref.value, value, "Storage reference inconsistent");

        // Test deletion via struct field
        delete ref.value;
        assertEq(stringMapping[key], "", "Deletion failed");
        assertEq(ref.value, "", "Storage reference after deletion inconsistent");
    }
}
