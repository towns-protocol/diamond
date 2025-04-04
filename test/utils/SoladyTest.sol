// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TestPlus.sol";
import "forge-std/Test.sol";

contract SoladyTest is Test, TestPlus {
    /// @dev Alias for `_hem`.
    function _bound(
        uint256 x,
        uint256 min,
        uint256 max
    )
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        return _hem(x, min, max);
    }
}
