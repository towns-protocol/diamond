// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MinimalERC6909Storage} from "../../../primitive/ERC6909.sol";

library ERC6909Storage {
    // keccak256(abi.encode(uint256(keccak256("diamond.facets.token.ERC6909")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 internal constant STORAGE_SLOT =
        0xf9f33862612718f5941a42fb684d74a72854935271a5691c69162b83a46f6d00;

    function getLayout() internal pure returns (MinimalERC6909Storage storage l) {
        return getLayout(STORAGE_SLOT);
    }

    function getLayout(bytes32 slot) internal pure returns (MinimalERC6909Storage storage l) {
        assembly {
            l.slot := slot
        }
    }
}
