// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts

contract ERC1271OverrideTest {

}

// import {ERC1271Facet} from "../../../src/facets/accounts/ERC1271Facet.sol";
// import {IERC1271} from "../../../src/facets/accounts/IERC1271.sol";
// import {Test} from "forge-std/Test.sol";

// // Example facet that overrides signer to return a constant address
// contract CustomERC1271Facet is ERC1271Facet {
//     address private constant CONSTANT_SIGNER = 0x1234567890123456789012345678901234567890;

//     // Override to return constant signer for gas optimization
//     function _erc1271Signer() internal pure override returns (address) {
//         return CONSTANT_SIGNER;
//     }
// }

// contract ERC1271OverrideTest is Test {
//     CustomERC1271Facet public customFacet;
//     ERC1271Facet public standardFacet;

//     address private constant CONSTANT_SIGNER = 0x1234567890123456789012345678901234567890;
//     address private storageSigner;
//     uint256 private signerPrivateKey;

//     bytes4 constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

//     function setUp() public {
//         customFacet = new CustomERC1271Facet();
//         standardFacet = new ERC1271Facet();

//         signerPrivateKey = 0x123;
//         storageSigner = vm.addr(signerPrivateKey);

//         // Manually set storage for standard facet (for testing only)
//         vm.store(
//             address(standardFacet),
//             bytes32(0xe208bfd80cbc710d4b3bd6e67400c6fccf276f9b15d4c387c507d953a65f6400), // ERC1271 signer slot
//             bytes32(uint256(uint160(storageSigner)))
//         );
//     }

//     function test_customFacetReturnsConstantSigner() public view {
//         // Custom facet should return the constant signer
//         assertEq(customFacet.erc1271Signer(), CONSTANT_SIGNER);
//     }

//     function test_standardFacetReturnsStorageSigner() public view {
//         // Standard facet should return the storage signer
//         assertEq(standardFacet.erc1271Signer(), storageSigner);
//     }

//     function test_constantSignerOptimization() public view {
//         // The constant signer should be more gas efficient
//         // We can't measure gas in a view function, but we can verify the behavior

//         // Both should return their respective signers
//         address customSigner = customFacet.erc1271Signer();
//         address standardSigner = standardFacet.erc1271Signer();

//         assertEq(customSigner, CONSTANT_SIGNER);
//         assertEq(standardSigner, storageSigner);
//         assertTrue(customSigner != standardSigner);
//     }

//     function test_overrideDoesNotAffectOtherFunctionality() public {
//         // Both facets should handle signature validation differently due to different signers
//         bytes32 messageHash = keccak256("Hello, ERC1271!");

//         // Sign with the storage signer
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, messageHash);
//         bytes memory signature = abi.encodePacked(r, s, v);

//         // Standard facet should validate this signature (correct signer)
//         bytes4 standardResult = standardFacet.isValidSignature(messageHash, signature);
//         assertEq(standardResult, ERC1271_MAGIC_VALUE);

//         // Custom facet should reject this signature (wrong signer)
//         bytes4 customResult = customFacet.isValidSignature(messageHash, signature);
//         assertEq(customResult, bytes4(0xffffffff)); // Invalid signature
//     }
// }
