// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712Facet} from "../../../src/utils/cryptography/EIP712Facet.sol";
import {Test} from "forge-std/Test.sol";

// Example facet that overrides domain name and version
contract CustomEIP712Facet is EIP712Facet {
// Override to return constant values for gas optimization
//    function _domainNameAndVersion()
//        internal
//        pure
//        override
//        returns (string memory name, string memory version)
//    {
//        name = "CustomDomain";
//        version = "2.0";
//    }
}

contract EIP712OverrideTest is Test {
    CustomEIP712Facet public customFacet;

    function setUp() public {
        customFacet = new CustomEIP712Facet();
    }

    function test_customFacetReturnsOverriddenValues() public view {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            ,
        ) = customFacet.eip712Domain();

        assertEq(name, "CustomDomain");
        assertEq(version, "2.0");
        assertEq(fields, hex"0f"); // 01111
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, address(customFacet));
    }

    function test_domainSeparatorUsesOverriddenValues() public view {
        bytes32 separator = customFacet.DOMAIN_SEPARATOR();

        // Calculate expected separator
        bytes32 expectedSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("CustomDomain")),
                keccak256(bytes("2.0")),
                block.chainid,
                address(customFacet)
            )
        );

        assertEq(separator, expectedSeparator);
    }
}
