// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

// interfaces

// libraries
import {EIP712Storage, EIP712Lib} from "../../primitive/EIP712.sol";

// contracts

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP-712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding scheme specified in the EIP requires a domain separator and a hash of the typed structured data, whose
 * encoding is very generic and therefore its implementation in Solidity is not feasible, thus this contract
 * does not implement the encoding itself. Protocols need to implement the type-specific encoding they need in order to
 * produce the hash of their typed data using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP-712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the {_domainSeparatorV4} function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 */
abstract contract EIP712Base {
  using EIP712Lib for EIP712Storage;

  bytes32 private constant TYPE_HASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

  // keccak256(abi.encode(uint256(keccak256("diamond.utils.cryptography.eip712.storage")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 internal constant STORAGE_SLOT =
    0x219639d1c7dec7d049ffb8dc11e39f070f052764b142bd61682a7811a502a600;

  function _getEIP712Storage() internal pure returns (EIP712Storage storage $) {
    assembly {
      $.slot := STORAGE_SLOT
    }
  }

  function __EIP712_init_unchained(
    string memory name,
    string memory version
  ) internal {
    EIP712Storage storage $ = _getEIP712Storage();
    $.name = name;
    $.version = version;

    // Reset prior values in storage if upgrading
    $.hashedName = 0;
    $.hashedVersion = 0;
  }

  /**
   * @dev Returns the domain separator for the current chain.
   */
  function _domainSeparatorV4() internal view returns (bytes32) {
    return _getEIP712Storage().domainSeparatorV4();
  }

  /**
   * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
   * function returns the hash of the fully encoded EIP712 message for this domain.
   *
   * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
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
  function _hashTypedDataV4(
    bytes32 structHash
  ) internal view virtual returns (bytes32) {
    return _getEIP712Storage().hashTypedDataV4(structHash);
  }

  /**
   * @dev The name parameter for the EIP712 domain.
   *
   * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
   * are a concern.
   */
  function _EIP712Name() internal view virtual returns (string memory) {
    return _getEIP712Storage()._EIP712Name();
  }

  /**
   * @dev The version parameter for the EIP712 domain.
   *
   * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
   * are a concern.
   */
  function _EIP712Version() internal view virtual returns (string memory) {
    return _getEIP712Storage()._EIP712Version();
  }

  /**
   * @dev The hash of the name parameter for the EIP712 domain.
   *
   * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Name` instead.
   */
  function _EIP712NameHash() internal view returns (bytes32) {
    return _getEIP712Storage()._EIP712NameHash();
  }

  /**
   * @dev The hash of the version parameter for the EIP712 domain.
   *
   * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Version` instead.
   */
  function _EIP712VersionHash() internal view returns (bytes32) {
    return _getEIP712Storage()._EIP712VersionHash();
  }
}
