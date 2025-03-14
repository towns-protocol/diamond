// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC6909} from "./IERC6909.sol";

// libraries
import {ERC6909Lib} from "./ERC6909Lib.sol";

// contracts
import {Facet} from "../../Facet.sol";

abstract contract ERC6909 is Facet, IERC6909 {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      ERC6909 METADATA                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  function __ERC6909_init() internal {
    _addInterface(0x0f632fb3);
  }

  /// @inheritdoc IERC6909
  function name(uint256 id) public view virtual returns (string memory);

  /// @inheritdoc IERC6909
  function symbol(uint256 id) public view virtual returns (string memory);

  /// @inheritdoc IERC6909
  function decimals(uint256 id) public view virtual returns (uint8) {
    id = id; // Silence compiler warning.
    return 18;
  }

  /// @inheritdoc IERC6909
  function contractURI() public view virtual returns (string memory) {
    return "";
  }

  /// @inheritdoc IERC6909
  function tokenURI(uint256 id) public view virtual returns (string memory);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          ERC6909                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @inheritdoc IERC6909
  function totalSupply(uint256 id) public view virtual returns (uint256) {
    return ERC6909Lib.totalSupply(id);
  }

  /// @inheritdoc IERC6909
  function balanceOf(
    address owner,
    uint256 id
  ) public view virtual returns (uint256 balance) {
    return ERC6909Lib.balanceOf(owner, id);
  }

  /// @inheritdoc IERC6909
  function allowance(
    address owner,
    address spender,
    uint256 id
  ) public view virtual returns (uint256 remaining) {
    return ERC6909Lib.allowance(owner, spender, id);
  }

  /// @inheritdoc IERC6909
  function isOperator(
    address owner,
    address spender
  ) public view virtual returns (bool status) {
    return ERC6909Lib.isOperator(owner, spender);
  }

  /// @inheritdoc IERC6909
  function transfer(
    address to,
    uint256 id,
    uint256 amount
  ) external returns (bool) {
    return ERC6909Lib.transfer(to, id, amount);
  }

  /// @inheritdoc IERC6909
  function transferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) external returns (bool) {
    return ERC6909Lib.transferFrom(from, to, id, amount);
  }

  /// @inheritdoc IERC6909
  function approve(
    address spender,
    uint256 id,
    uint256 amount
  ) external returns (bool) {
    return ERC6909Lib.approve(spender, id, amount);
  }

  /// @inheritdoc IERC6909
  function setOperator(
    address operator,
    bool approved
  ) external returns (bool) {
    return ERC6909Lib.setOperator(operator, approved);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           MINTING                          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  function _mint(address to, uint256 id, uint256 amount) internal virtual {
    return ERC6909Lib.mint(to, id, amount);
  }

  function _burn(address from, uint256 id, uint256 amount) internal virtual {
    return ERC6909Lib.burn(from, id, amount);
  }
}
