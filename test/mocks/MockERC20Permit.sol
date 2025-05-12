// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces

// libraries

// contracts
import {ERC20PermitBase} from "../../src/facets/token/ERC20/permit/ERC20PermitBase.sol";

contract MockERC20Permit is ERC20PermitBase {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
