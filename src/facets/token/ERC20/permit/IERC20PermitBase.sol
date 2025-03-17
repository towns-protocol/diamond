// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts

interface IERC20PermitBase {
  /// @dev The permit is invalid.
  error InvalidPermit();

  /// @dev The permit has expired.
  error PermitExpired();

  /// @dev Permit deadline has expired.
  error ERC2612ExpiredSignature(uint256 deadline);

  /// @dev Mismatched signature.
  error ERC2612InvalidSigner(address signer, address owner);
}
