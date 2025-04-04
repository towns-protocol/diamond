// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ERC6909 Base Interface
/// @notice Contains the core events used by the ERC6909 token standard
interface IERC6909Base {
    /// @notice Thrown when owner balance for id is insufficient.
    /// @param owner The address of the owner.
    /// @param id The id of the token.
    error InsufficientBalance(address owner, uint256 id);

    /// @notice Thrown when spender allowance for id is insufficient.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    error InsufficientPermission(address spender, uint256 id);

    /// @notice The event emitted when a transfer occurs.
    /// @param caller The caller of the transfer.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    event Transfer(
        address caller,
        address indexed sender,
        address indexed receiver,
        uint256 indexed id,
        uint256 amount
    );

    /// @notice The event emitted when an operator is set.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param approved The approval status.
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    /// @notice The event emitted when an approval occurs.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id, uint256 amount
    );
}

/// @title ERC6909 Core Interface
interface IERC6909 is IERC6909Base {
    /// @notice Name of a given token.
    /// @param id The id of the token.
    /// @return name The name of the token.
    function name(uint256 id) external view returns (string memory);

    /// @notice Symbol of a given token.
    /// @param id The id of the token.
    /// @return symbol The symbol of the token.
    function symbol(uint256 id) external view returns (string memory);

    /// @notice Decimals of a given token.
    /// @param id The id of the token.
    /// @return decimals The decimals of the token.
    function decimals(uint256 id) external view returns (uint8);

    /// @notice Contract level URI
    /// @return uri The contract level URI.
    function contractURI() external view returns (string memory);

    /// @notice Token level URI
    /// @param id The id of the token.
    /// @return uri The token level URI.
    function tokenURI(uint256 id) external view returns (string memory);

    /// @notice Total supply of a token
    /// @param id The id of the token.
    /// @return supply The total supply of the token.
    function totalSupply(uint256 id) external view returns (uint256 supply);

    /// @notice Owner balance of an id.
    /// @param owner The address of the owner.
    /// @param id The id of the token.
    /// @return amount The balance of the token.
    function balanceOf(address owner, uint256 id) external view returns (uint256 amount);

    /// @notice Spender allowance of an id.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @return amount The allowance of the token.
    function allowance(
        address owner,
        address spender,
        uint256 id
    )
        external
        view
        returns (uint256 amount);

    /// @notice Checks if a spender is approved by an owner as an operator
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @return approved The approval status.
    function isOperator(address owner, address spender) external view returns (bool approved);

    /// @notice Transfers an amount of an id from the caller to a receiver.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);

    /// @notice Transfers an amount of an id from a sender to a receiver.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transferFrom(
        address sender,
        address receiver,
        uint256 id,
        uint256 amount
    )
        external
        returns (bool);

    /// @notice Approves an amount of an id to a spender.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);

    /// @notice Sets or removes a spender as an operator for the caller.
    /// @param spender The address of the spender.
    /// @param approved The approval status.
    function setOperator(address spender, bool approved) external returns (bool);
}
