// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC6909} from "src/facets/token/ERC6909/ERC6909.sol";

contract MockERC6909 is ERC6909 {
  constructor() {
    __ERC6909_init();
  }

  function name(uint256) public pure override returns (string memory) {
    return "Mock ERC6909";
  }

  function symbol(uint256) public pure override returns (string memory) {
    return "MOCK6909";
  }

  function decimals(uint256) public pure override returns (uint8) {
    return 18;
  }

  function contractURI() public pure override returns (string memory) {
    return "";
  }

  function tokenURI(uint256) public pure override returns (string memory) {
    return "";
  }

  function mint(address to, uint256 id, uint256 amount) public {
    _mint(to, id, amount);
  }

  function burn(address from, uint256 id, uint256 amount) public {
    _burn(from, id, amount);
  }
}
