// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MinimalERC20Storage} from "./ERC20.sol";
import {IERC6909Base} from "../facets/token/ERC6909/IERC6909.sol";

using ERC6909 for MinimalERC6909Storage global;

/// @notice Minimal storage layout for ERC6909
/// @dev Do not modify the layout of this struct especially if it's nested in another struct
/// or used in a linear storage layout
struct MinimalERC6909Storage {
  mapping(uint256 id => MinimalERC20Storage) tokens;
  mapping(address owner => mapping(address spender => bool)) operatorApprovals;
}

/// @title ERC6909
/// @notice Minimal ERC6909 implementation
library ERC6909 {
  /// @notice Returns the total supply of a specific token ID
  /// @param id The token ID to query
  /// @return The total supply of the token
  function totalSupply(
    MinimalERC6909Storage storage self,
    uint256 id
  ) internal view returns (uint256) {
    return self.tokens[id].totalSupply;
  }

  /// @notice Returns the balance of a specific token ID for an account
  /// @param owner The address to query the balance of
  /// @param id The token ID to query
  /// @return The balance of the specified token for the owner
  function balanceOf(
    MinimalERC6909Storage storage self,
    address owner,
    uint256 id
  ) internal view returns (uint256) {
    return self.tokens[id].balanceOf(owner);
  }

  /// @notice Returns the allowance of a spender for a specific token ID
  /// @param owner The address that owns the tokens
  /// @param spender The address that can spend the tokens
  /// @param id The token ID to query
  /// @return The remaining allowance of the spender
  function allowance(
    MinimalERC6909Storage storage self,
    address owner,
    address spender,
    uint256 id
  ) internal view returns (uint256) {
    return self.tokens[id].allowance(owner, spender);
  }

  /// @notice Checks if an address is an approved operator for an owner
  /// @param owner The address that owns the tokens
  /// @param spender The address to check operator status for
  /// @return True if the spender is an approved operator for the owner
  function isOperator(
    MinimalERC6909Storage storage self,
    address owner,
    address spender
  ) internal view returns (bool) {
    return self.operatorApprovals[owner][spender];
  }

  /// @notice Transfers tokens from the caller to another address
  /// @param to The address to transfer tokens to
  /// @param id The token ID to transfer
  /// @param amount The amount of tokens to transfer
  function transfer(
    MinimalERC6909Storage storage self,
    address to,
    uint256 id,
    uint256 amount
  ) internal returns (bool) {
    _transfer(self, msg.sender, to, id, amount);
    return true;
  }

  /// @notice Transfers tokens from one address to another using an allowance
  /// @dev Requires the caller to have sufficient allowance or be an operator
  /// @param from The address to transfer tokens from
  /// @param to The address to transfer tokens to
  /// @param id The token ID to transfer
  /// @param amount The amount of tokens to transfer
  function transferFrom(
    MinimalERC6909Storage storage self,
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) internal returns (bool) {
    MinimalERC20Storage storage token = self.tokens[id];
    if (msg.sender != from && !isOperator(self, from, msg.sender)) {
      uint256 slot = token.allowances.slot(from, msg.sender);
      uint256 currentAllowance;
      assembly {
        currentAllowance := sload(slot)
      }
      if (currentAllowance != type(uint256).max) {
        if (currentAllowance < amount) {
          revert IERC6909Base.InsufficientPermission();
        }
        assembly {
          sstore(slot, sub(currentAllowance, amount))
        }
      }
    }
    token._deductBalance(from, amount);
    token._increaseBalance(to, amount);
    emit IERC6909Base.Transfer(msg.sender, from, to, id, amount);
    return true;
  }

  /// @notice Approves a spender to spend tokens on behalf of the caller
  /// @param spender The address to approve
  /// @param id The token ID to approve
  /// @param amount The amount of tokens to approve
  function approve(
    MinimalERC6909Storage storage self,
    address spender,
    uint256 id,
    uint256 amount
  ) internal returns (bool) {
    _approve(self, msg.sender, spender, id, amount);
    return true;
  }

  /// @notice Sets or revokes operator status for an address
  /// @dev Operators can transfer any token ID owned by the caller
  /// @param operator The address to set operator status for
  /// @param approved True to approve the operator, false to revoke approval
  function setOperator(
    MinimalERC6909Storage storage self,
    address operator,
    bool approved
  ) internal returns (bool) {
    self.operatorApprovals[msg.sender][operator] = approved;
    emit IERC6909Base.OperatorSet(msg.sender, operator, approved);
    return true;
  }

  /// @notice Mints new tokens to a specified address
  /// @dev Increases the total supply and the recipient's balance
  /// @param to The address to mint tokens to
  /// @param id The token ID to mint
  /// @param amount The amount of tokens to mint
  function mint(
    MinimalERC6909Storage storage self,
    address to,
    uint256 id,
    uint256 amount
  ) internal {
    MinimalERC20Storage storage token = self.tokens[id];
    // Overflow check required: The rest of the code assumes that totalSupply never overflows
    token.totalSupply += amount;
    token._increaseBalance(to, amount);
    emit IERC6909Base.Transfer(msg.sender, address(0), to, id, amount);
  }

  /// @notice Burns tokens from a specified address
  /// @dev Decreases the total supply and the holder's balance
  /// @param from The address to burn tokens from
  /// @param id The token ID to burn
  /// @param amount The amount of tokens to burn
  function burn(
    MinimalERC6909Storage storage self,
    address from,
    uint256 id,
    uint256 amount
  ) internal {
    MinimalERC20Storage storage token = self.tokens[id];
    token._deductBalance(from, amount);
    unchecked {
      // Overflow not possible: amount <= totalSupply or amount <= fromBalance <= totalSupply.
      token.totalSupply -= amount;
    }
    emit IERC6909Base.Transfer(msg.sender, from, address(0), id, amount);
  }

  /// @notice Internal function to approve a spender
  /// @dev Sets the allowance and emits an Approval event
  /// @param owner The address that owns the tokens
  /// @param spender The address that can spend the tokens
  /// @param id The token ID to approve
  /// @param amount The amount of tokens to approve
  function _approve(
    MinimalERC6909Storage storage self,
    address owner,
    address spender,
    uint256 id,
    uint256 amount
  ) internal {
    self.tokens[id].allowances.set(owner, spender, amount);
    emit IERC6909Base.Approval(owner, spender, id, amount);
  }

  /// @notice Internal function to transfer tokens between addresses
  /// @dev Handles the actual transfer logic for transfer and transferFrom
  /// @param from The address to transfer tokens from
  /// @param to The address to transfer tokens to
  /// @param id The token ID to transfer
  /// @param amount The amount of tokens to transfer
  function _transfer(
    MinimalERC6909Storage storage self,
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) internal {
    MinimalERC20Storage storage token = self.tokens[id];
    token._deductBalance(from, amount);
    token._increaseBalance(to, amount);
    emit IERC6909Base.Transfer(msg.sender, from, to, id, amount);
  }
}
