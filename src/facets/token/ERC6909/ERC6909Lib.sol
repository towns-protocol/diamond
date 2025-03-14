// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IERC6909Base} from "./IERC6909.sol";

// libraries
import {ERC6909Storage} from "./ERC6909Storage.sol";

/// @title ERC6909Lib
/// @notice Library implementing ERC6909 logic for multi-token standard
/// @dev Implements core functionality for ERC6909 token standard
library ERC6909Lib {
  /// @notice Returns the total supply of a specific token ID
  /// @param id The token ID to query
  /// @return The total supply of the token
  function totalSupply(uint256 id) internal view returns (uint256) {
    return ERC6909Storage.getLayout().supply[id];
  }

  /// @notice Returns the balance of a specific token ID for an account
  /// @param owner The address to query the balance of
  /// @param id The token ID to query
  /// @return The balance of the specified token for the owner
  function balanceOf(
    address owner,
    uint256 id
  ) internal view returns (uint256) {
    return ERC6909Storage.getLayout().balances[owner][id];
  }

  /// @notice Returns the allowance of a spender for a specific token ID
  /// @param owner The address that owns the tokens
  /// @param spender The address that can spend the tokens
  /// @param id The token ID to query
  /// @return The remaining allowance of the spender
  function allowance(
    address owner,
    address spender,
    uint256 id
  ) internal view returns (uint256) {
    return ERC6909Storage.getLayout().allowances[owner][spender][id];
  }

  /// @notice Checks if an address is an approved operator for an owner
  /// @param owner The address that owns the tokens
  /// @param spender The address to check operator status for
  /// @return True if the spender is an approved operator for the owner
  function isOperator(
    address owner,
    address spender
  ) internal view returns (bool) {
    return ERC6909Storage.getLayout().operatorApprovals[owner][spender];
  }

  /// @notice Transfers tokens from the caller to another address
  /// @param to The address to transfer tokens to
  /// @param id The token ID to transfer
  /// @param amount The amount of tokens to transfer
  /// @return True if the transfer was successful
  function transfer(
    address to,
    uint256 id,
    uint256 amount
  ) internal returns (bool) {
    _transfer(msg.sender, to, id, amount);
    return true;
  }

  /// @notice Transfers tokens from one address to another using an allowance
  /// @dev Requires the caller to have sufficient allowance or be an operator
  /// @param from The address to transfer tokens from
  /// @param to The address to transfer tokens to
  /// @param id The token ID to transfer
  /// @param amount The amount of tokens to transfer
  /// @return True if the transfer was successful
  /// @custom:error InsufficientPermission Thrown if caller has insufficient allowance
  function transferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) internal returns (bool) {
    if (!isOperator(from, msg.sender)) {
      uint256 currentAllowance = allowance(from, msg.sender, id);
      if (currentAllowance != type(uint256).max) {
        if (currentAllowance < amount) {
          revert IERC6909Base.InsufficientPermission();
        }
        _approve(from, msg.sender, id, currentAllowance - amount);
      }
    }
    _transfer(from, to, id, amount);
    return true;
  }

  /// @notice Approves a spender to spend tokens on behalf of the caller
  /// @param spender The address to approve
  /// @param id The token ID to approve
  /// @param amount The amount of tokens to approve
  /// @return True if the approval was successful
  function approve(
    address spender,
    uint256 id,
    uint256 amount
  ) internal returns (bool) {
    _approve(msg.sender, spender, id, amount);
    return true;
  }

  /// @notice Sets or revokes operator status for an address
  /// @dev Operators can transfer any token ID owned by the caller
  /// @param operator The address to set operator status for
  /// @param approved True to approve the operator, false to revoke approval
  /// @return True if the operation was successful
  function setOperator(
    address operator,
    bool approved
  ) internal returns (bool) {
    ERC6909Storage.getLayout().operatorApprovals[msg.sender][
      operator
    ] = approved;
    emit IERC6909Base.OperatorSet(msg.sender, operator, approved);
    return true;
  }

  /// @notice Mints new tokens to a specified address
  /// @dev Increases the total supply and the recipient's balance
  /// @param to The address to mint tokens to
  /// @param id The token ID to mint
  /// @param amount The amount of tokens to mint
  /// @custom:error BalanceOverflow Thrown if the recipient's balance would overflow
  function mint(address to, uint256 id, uint256 amount) internal {
    if (amount > 0) {
      ERC6909Storage.Layout storage ds = ERC6909Storage.getLayout();

      uint256 toBalanceBefore = ds.balances[to][id];
      uint256 toBalanceAfter = toBalanceBefore + amount;
      if (toBalanceAfter < toBalanceBefore)
        revert IERC6909Base.BalanceOverflow();

      ds.supply[id] += amount;
      ds.balances[to][id] = toBalanceAfter;
      emit IERC6909Base.Transfer(msg.sender, address(0), to, id, amount);
    }
  }

  /// @notice Burns tokens from a specified address
  /// @dev Decreases the total supply and the holder's balance
  /// @param from The address to burn tokens from
  /// @param id The token ID to burn
  /// @param amount The amount of tokens to burn
  /// @custom:error InsufficientBalance Thrown if the holder has insufficient balance
  function burn(address from, uint256 id, uint256 amount) internal {
    if (amount > 0) {
      ERC6909Storage.Layout storage ds = ERC6909Storage.getLayout();

      uint256 fromBalance = ds.balances[from][id];
      if (fromBalance < amount) revert IERC6909Base.InsufficientBalance();

      unchecked {
        ds.balances[from][id] = fromBalance - amount;
        ds.supply[id] -= amount;
      }
      emit IERC6909Base.Transfer(msg.sender, from, address(0), id, amount);
    }
  }

  /// @notice Internal function to transfer tokens between addresses
  /// @dev Handles the actual transfer logic for transfer and transferFrom
  /// @param from The address to transfer tokens from
  /// @param to The address to transfer tokens to
  /// @param id The token ID to transfer
  /// @param amount The amount of tokens to transfer
  /// @custom:error InsufficientBalance Thrown if the sender has insufficient balance
  /// @custom:error BalanceOverflow Thrown if the recipient's balance would overflow
  function _transfer(
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) private {
    if (amount > 0) {
      ERC6909Storage.Layout storage ds = ERC6909Storage.getLayout();

      uint256 fromBalance = ds.balances[from][id];
      if (fromBalance < amount) revert IERC6909Base.InsufficientBalance();

      unchecked {
        ds.balances[from][id] = fromBalance - amount;
      }

      uint256 toBalanceBefore = ds.balances[to][id];
      uint256 toBalanceAfter = toBalanceBefore + amount;
      if (toBalanceAfter < toBalanceBefore)
        revert IERC6909Base.BalanceOverflow();

      ds.balances[to][id] = toBalanceAfter;
      emit IERC6909Base.Transfer(msg.sender, from, to, id, amount);
    }
  }

  /// @notice Internal function to approve a spender
  /// @dev Sets the allowance and emits an Approval event
  /// @param owner The address that owns the tokens
  /// @param spender The address that can spend the tokens
  /// @param id The token ID to approve
  /// @param amount The amount of tokens to approve
  function _approve(
    address owner,
    address spender,
    uint256 id,
    uint256 amount
  ) private {
    ERC6909Storage.getLayout().allowances[owner][spender][id] = amount;
    emit IERC6909Base.Approval(owner, spender, id, amount);
  }
}
