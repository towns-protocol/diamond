// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// utils
import {TestUtils} from "test/TestUtils.sol";

//interfaces

//libraries

//contracts
import {MultiInit} from "src/initializers/MultiInit.sol";
import {AddressAndCalldataLengthDoNotMatch} from "src/initializers/MultiInit.sol";

import {MockFacet} from "test/mocks/MockFacet.sol";

contract MultiInitTest is TestUtils {
    MultiInit internal diamondMultiInit;

    function setUp() external {
        diamondMultiInit = new MultiInit();
    }

    function test_multiInit() external {
        address[] memory addresses = new address[](1);
        bytes[] memory calldata_ = new bytes[](1);

        MockFacet mockFacet = new MockFacet();

        addresses[0] = address(mockFacet);
        calldata_[0] = abi.encodeWithSelector(mockFacet.mockFunction.selector);

        diamondMultiInit.multiInit(addresses, calldata_);
    }

    function test_revert_when_length_mismatch() external {
        address[] memory addresses = new address[](1);
        bytes[] memory calldata_ = new bytes[](2);

        vm.expectRevert(
            abi.encodeWithSelector(
                AddressAndCalldataLengthDoNotMatch.selector, addresses.length, calldata_.length
            )
        );
        diamondMultiInit.multiInit(addresses, calldata_);
    }
}
