// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC6909Base} from "../facets/token/ERC6909/IERC6909.sol";
import {MinimalERC20Storage} from "./ERC20.sol";

/// @title ERC6909Lib
/// @notice Minimal ERC6909 implementation
/// @dev The library implements the core functionality of an ERC6909 token without emitting events
library ERC6909Lib {
    /// @notice Minimal storage layout for ERC6909
    /// @dev Do not modify the layout of this struct especially if it's nested in another struct
    /// or used in a linear storage layout
    struct MinimalERC6909Storage {
        mapping(uint256 id => MinimalERC20Storage) tokens;
        mapping(address owner => mapping(address spender => bool)) operatorApprovals;
    }

    /// @notice Returns the total supply of a specific token ID
    /// @param id The token ID to query
    /// @return The total supply of the token
    function totalSupply(
        MinimalERC6909Storage storage self,
        uint256 id
    )
        internal
        view
        returns (uint256)
    {
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
    )
        internal
        view
        returns (uint256)
    {
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
    )
        internal
        view
        returns (uint256)
    {
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
    )
        internal
        view
        returns (bool)
    {
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
    )
        internal
    {
        MinimalERC20Storage storage token = self.tokens[id];
        _deductBalance(token, msg.sender, id, amount);
        token._increaseBalance(to, amount);
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
    )
        internal
    {
        MinimalERC20Storage storage token = self.tokens[id];
        if (msg.sender != from && !isOperator(self, from, msg.sender)) {
            (bool insufficient,) = token._spendAllowanceNoRevert(from, msg.sender, amount);
            if (insufficient) {
                revert IERC6909Base.InsufficientPermission(msg.sender, id);
            }
        }
        _deductBalance(token, from, id, amount);
        token._increaseBalance(to, amount);
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
    )
        internal
    {
        _approve(self, msg.sender, spender, id, amount);
    }

    /// @notice Sets or revokes operator status for an address
    /// @dev Operators can transfer any token ID owned by the caller
    /// @param operator The address to set operator status for
    /// @param approved True to approve the operator, false to revoke approval
    function setOperator(
        MinimalERC6909Storage storage self,
        address operator,
        bool approved
    )
        internal
    {
        self.operatorApprovals[msg.sender][operator] = approved;
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
    )
        internal
    {
        MinimalERC20Storage storage token = self.tokens[id];
        // Overflow check required: The rest of the code assumes that totalSupply never overflows
        token.totalSupply += amount;
        token._increaseBalance(to, amount);
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
    )
        internal
    {
        MinimalERC20Storage storage token = self.tokens[id];
        _deductBalance(token, from, id, amount);
        unchecked {
            // Overflow not possible: amount <= totalSupply or amount <= fromBalance <= totalSupply.
            token.totalSupply -= amount;
        }
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
    )
        internal
    {
        self.tokens[id].allowances.set(owner, spender, amount);
    }

    /// @notice Internal function to deduct balance
    /// @dev Reverts if the deduction would result in an underflow
    /// @param token The token storage to deduct from
    /// @param from The address to deduct from
    /// @param id The token ID to deduct
    /// @param amount The amount to deduct
    function _deductBalance(
        MinimalERC20Storage storage token,
        address from,
        uint256 id,
        uint256 amount
    )
        internal
    {
        (bool underflow,) = token._deductBalanceNoRevert(from, amount);
        if (underflow) {
            revert IERC6909Base.InsufficientBalance(from, id);
        }
    }
}
