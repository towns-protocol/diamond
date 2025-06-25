// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct EIP712Storage {
    bytes32 hashedName;
    bytes32 hashedVersion;
    string name;
    string version;
}

/// @notice EIP712 library
/// @dev Modified from OpenZeppelin Upgradeable Contracts v5.1.0
/// [utils/cryptography/EIP712.sol](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/36ec7079af1a68bd866f6b9f4cf2f4dddee1e7bc/contracts/utils/cryptography/EIP712Upgradeable.sol)
library EIP712Lib {
    bytes32 private constant TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 private constant EMPTY_STRING_HASH = keccak256("");

    /// @dev Returns the domain separator for the current chain.
    function domainSeparatorV4(EIP712Storage storage self) internal view returns (bytes32) {
        return _buildDomainSeparator(self);
    }

    function _buildDomainSeparator(EIP712Storage storage self) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                TYPE_HASH,
                _EIP712NameHash(self),
                _EIP712VersionHash(self),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of
     * EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    )
        internal
        pure
        returns (bytes32 digest)
    {
        assembly ("memory-safe") {
            mstore(0, hex"1901")
            mstore(0x02, domainSeparator)
            mstore(0x22, structHash)
            digest := keccak256(0, 0x42)
            mstore(0x22, 0)
        }
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed
     * struct], this function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For
     * example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function hashTypedDataV4(
        EIP712Storage storage self,
        bytes32 structHash
    )
        internal
        view
        returns (bytes32)
    {
        return toTypedDataHash(domainSeparatorV4(self), structHash);
    }

    /// @dev See {IERC-5267}.
    /// Note: This function is kept for backward compatibility but is not used by the updated EIP712Facet
    /// which now uses virtual functions to allow overrides.
    function eip712Domain(EIP712Storage storage self)
        internal
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        // If the hashed name and version in storage are non-zero, the contract hasn't been properly initialized
        // and the EIP712 domain is not reliable, as it will be missing name and version.
        require(self.hashedName == 0 && self.hashedVersion == 0, "EIP712: Uninitialized");

        return (
            hex"0f", // 01111
            _EIP712Name(self),
            _EIP712Version(self),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Name(EIP712Storage storage self) internal view returns (string memory) {
        return self.name;
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Version(EIP712Storage storage self) internal view returns (string memory) {
        return self.version;
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was . In this version you should override `_EIP712Name` instead.
     */
    function _EIP712NameHash(EIP712Storage storage self) internal view returns (bytes32) {
        string memory name = _EIP712Name(self);
        if (bytes(name).length > 0) {
            return keccak256(bytes(name));
        } else {
            // If the name is empty, the contract may have been upgraded without initializing the new storage.
            // We return the name hash in storage if non-zero, otherwise we assume the name is empty by design.
            bytes32 hashedName = self.hashedName;
            if (hashedName != 0) {
                return hashedName;
            } else {
                return EMPTY_STRING_HASH;
            }
        }
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was . In this version you should override `_EIP712Version` instead.
     */
    function _EIP712VersionHash(EIP712Storage storage self) internal view returns (bytes32) {
        string memory version = _EIP712Version(self);
        if (bytes(version).length > 0) {
            return keccak256(bytes(version));
        } else {
            // If the version is empty, the contract may have been upgraded without initializing the new storage.
            // We return the version hash in storage if non-zero, otherwise we assume the version is empty by design.
            bytes32 hashedVersion = self.hashedVersion;
            if (hashedVersion != 0) {
                return hashedVersion;
            } else {
                return EMPTY_STRING_HASH;
            }
        }
    }
}
