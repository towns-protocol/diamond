// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

// libraries
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// contracts

// Simple mock contract that implements ERC1271 with raw ECDSA validation
contract MockERC1271Signer is IERC1271 {
    address public immutable signer;

    constructor(address _signer) {
        signer = _signer;
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view override returns (bytes4 magicValue) {
        // For testing purposes, accept any signature that recovers to the expected signer
        // This handles the case where the main diamond transforms the hash via nested EIP-712
        address recovered = ECDSA.recover(hash, signature);
        if (recovered == signer) {
            return 0x1626ba7e; // ERC1271_MAGIC_VALUE
        }
        return 0xffffffff; // Invalid signature
    }
}
