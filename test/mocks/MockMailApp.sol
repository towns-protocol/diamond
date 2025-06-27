// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

// libraries
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// contracts
import {EIP712} from "solady/utils/EIP712.sol";
import {EIP712Facet} from "src/utils/cryptography/EIP712Facet.sol";

// debuggging
import {console} from "forge-std/console.sol";

// Simple MockMailApp following the pattern from Towns protocol
contract MockMailApp is EIP712 {
    bytes32 public constant MAIL_TYPEHASH = keccak256("Mail(address to,string contents)");

    struct Mail {
        address to;
        string contents;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparator();
    }

    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "MailApp";
        version = "1.0";
    }

    function getStructHash(Mail memory mail) public pure returns (bytes32) {
        return keccak256(abi.encode(MAIL_TYPEHASH, mail.to, keccak256(bytes(mail.contents))));
    }

    function getDataHash(Mail memory mail) public view returns (bytes32) {
        return _hashTypedData(getStructHash(mail));
    }

    function _verify(
        bytes calldata signature,
        bytes32 hash,
        address claimedSigner
    )
        internal
        view
        returns (bool)
    {
        bytes4 magicValue = IERC1271(claimedSigner).isValidSignature(hash, signature);

        return magicValue == 0x1626ba7e;
    }

    function validateSignature(
        bytes calldata signature,
        bytes32 dataHash,
        address owner
    )
        external
        view
        returns (bool)
    {
        // Try to extract the nested signature data (last 2 bytes should contain length)
        bool isNestedSignature;
        /// @solidity memory-safe-assembly
        assembly {
            // Check if signature has the nested format by looking at the last 2 bytes
            // which should contain the contentsDescription length
            if gt(signature.length, 0x42) {
                // 0x42 = minimum length for nested format
                let c := shr(240, calldataload(add(signature.offset, sub(signature.length, 2))))
                // Verify the signature has valid nested format
                isNestedSignature := and(gt(signature.length, add(0x42, c)), gt(c, 0))
            }
        }

        bytes32 hash;
        if (isNestedSignature) {
            // Use validator's domain for nested signatures
            bytes32 domainSeparator = EIP712Facet(owner).DOMAIN_SEPARATOR();
            hash = MessageHashUtils.toTypedDataHash(domainSeparator, dataHash);
        } else {
            // Use app's domain for regular signatures
            hash = _hashTypedData(dataHash);
        }

        return _verify(signature, hash, owner);
    }
}
