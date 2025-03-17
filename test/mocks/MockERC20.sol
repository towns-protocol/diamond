// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// libraries
import {ERC20Storage} from "src/facets/token/ERC20/ERC20Storage.sol";

// contracts
import {ERC20PermitBase} from "src/facets/token/ERC20/permit/ERC20PermitBase.sol";

contract MockERC20 is ERC20PermitBase {
  function initialize(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) external initializer {
    __ERC20_init_unchained(name_, symbol_, decimals_);
    __ERC20PermitBase_init_unchained(name_);
  }

  function mint(address to, uint256 amount) external {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external {
    _burn(from, amount);
  }

  function directTransfer(address from, address to, uint256 amount) public {
    ERC20Storage.layout().inner._transfer(from, to, amount);
    emit IERC20.Transfer(from, to, amount);
  }

  function directSpendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) public {
    ERC20Storage.layout().inner._spendAllowance(owner, spender, amount);
  }
}
