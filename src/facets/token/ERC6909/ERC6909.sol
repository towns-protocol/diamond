// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC6909} from "./IERC6909.sol";

// libraries
import {ERC6909Storage} from "./ERC6909Storage.sol";
import {ERC6909Lib} from "../../../primitive/ERC6909.sol";

// contracts
import {Facet} from "../../Facet.sol";

abstract contract ERC6909 is Facet, IERC6909 {
  using ERC6909Lib for ERC6909Lib.MinimalERC6909Storage;

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
    return ERC6909Storage.getLayout().totalSupply(id);
  }

  /// @inheritdoc IERC6909
  function balanceOf(
    address owner,
    uint256 id
  ) public view virtual returns (uint256) {
    return ERC6909Storage.getLayout().balanceOf(owner, id);
  }

  /// @inheritdoc IERC6909
  function allowance(
    address owner,
    address spender,
    uint256 id
  ) public view virtual returns (uint256) {
    return ERC6909Storage.getLayout().allowance(owner, spender, id);
  }

  /// @inheritdoc IERC6909
  function isOperator(
    address owner,
    address spender
  ) public view virtual returns (bool) {
    return ERC6909Storage.getLayout().isOperator(owner, spender);
  }

  /// @inheritdoc IERC6909
  function transfer(
    address to,
    uint256 id,
    uint256 amount
  ) external returns (bool) {
    ERC6909Storage.getLayout().transfer(to, id, amount);
    emit Transfer(msg.sender, msg.sender, to, id, amount);
    return true;
  }

  /// @inheritdoc IERC6909
  function transferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) external returns (bool) {
    ERC6909Storage.getLayout().transferFrom(from, to, id, amount);
    emit Transfer(msg.sender, from, to, id, amount);
    return true;
  }

  /// @inheritdoc IERC6909
  function approve(
    address spender,
    uint256 id,
    uint256 amount
  ) external returns (bool) {
    ERC6909Storage.getLayout().approve(spender, id, amount);
    emit Approval(msg.sender, spender, id, amount);
    return true;
  }

  /// @inheritdoc IERC6909
  function setOperator(
    address operator,
    bool approved
  ) external returns (bool) {
    ERC6909Storage.getLayout().setOperator(operator, approved);
    emit OperatorSet(msg.sender, operator, approved);
    return true;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           MINTING                          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  function _mint(address to, uint256 id, uint256 amount) internal virtual {
    ERC6909Storage.getLayout().mint(to, id, amount);
    emit Transfer(msg.sender, address(0), to, id, amount);
  }

  function _burn(address from, uint256 id, uint256 amount) internal virtual {
    ERC6909Storage.getLayout().burn(from, id, amount);
    emit Transfer(msg.sender, from, address(0), id, amount);
  }
}
