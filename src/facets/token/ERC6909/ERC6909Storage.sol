// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library ERC6909Storage {
  // keccak256(abi.encode(uint256(keccak256("diamond.facets.token.ERC6909")) - 1)) & ~bytes32(uint256(0xff))
  bytes32 internal constant STORAGE_SLOT =
    0xf9f33862612718f5941a42fb684d74a72854935271a5691c69162b83a46f6d00;

  struct Layout {
    // Mapping from (owner, id) to balance
    mapping(address => mapping(uint256 => uint256)) balances;
    // Mapping from (owner, spender, id) to allowance
    mapping(address => mapping(address => mapping(uint256 => uint256))) allowances;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) operatorApprovals;
    // Mapping from token id to total supply
    mapping(uint256 => uint256) supply;
  }

  function getLayout() internal pure returns (Layout storage l) {
    assembly {
      l.slot := STORAGE_SLOT
    }
  }
}
