// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDeploy} from "../../src/utils/LibDeploy.sol";
import {MockFacet} from "../mocks/MockFacet.sol";
import {Test} from "forge-std/Test.sol";
import {LibClone} from "solady/utils/LibClone.sol";

contract LibDeployTest is Test {
    bytes32 private constant TEST_SALT = bytes32(uint256(1));
    string private constant MOCK_FACET_PATH = "test/mocks/MockFacet.sol:MockFacet";

    function setUp() public {
        vm.createSelectFork(getChain(1).rpcUrl, 14_353_601);
    }

    function test_deployCode() public {
        // Test deployCode with default salt (0)
        address addr1 = LibDeploy.deployCode(MOCK_FACET_PATH, "");

        assertTrue(addr1 != address(0), "Contract should be deployed");

        // Test deployCode with custom salt
        address addr2 = LibDeploy.deployCode(MOCK_FACET_PATH, "", TEST_SALT);

        assertTrue(addr2 != address(0), "Contract should be deployed");

        // Test deployCode with same salt returns existing contract
        address addr3 = LibDeploy.deployCode(MOCK_FACET_PATH, "", TEST_SALT);

        assertEq(addr2, addr3, "Should return the existing contract address");
    }

    function test_predictDeployCode() public {
        // Test predictDeployCode
        address predicted = LibDeploy.predictDeployCode(MOCK_FACET_PATH, "", TEST_SALT);

        // Actually deploy and verify prediction
        address deployed = LibDeploy.deployCode(MOCK_FACET_PATH, "", TEST_SALT);

        assertEq(predicted, deployed, "Predicted address should match deployed address");
    }

    function test_deployWithCreate2Factory() public {
        // Prepare a contract bytecode
        bytes memory bytecode = vm.getCode(MOCK_FACET_PATH);

        // Deploy with CREATE2
        address addr = LibDeploy.deployWithCreate2Factory(bytecode, TEST_SALT);

        assertTrue(addr != address(0), "Contract should be deployed");
    }

    function test_deployMultiple_revertIf_lengthMismatch() public {
        bytes[] memory bytecodes = new bytes[](2);
        bytes32[] memory salts = new bytes32[](3);

        // Should revert with length mismatch
        vm.expectRevert();
        this.deployMultiple(bytecodes, salts);
    }

    function test_deployMultiple_revertIf_illFormedBytecode() public {
        // Create array with one well-formed bytecode and one ill-formed bytecode
        bytes[] memory bytecodes = new bytes[](2);
        bytes32[] memory salts = new bytes32[](2);

        // Ill-formed bytecode (invalid EVM bytecode)
        bytecodes[0] = hex"aabbcc"; // Invalid bytecode
        salts[0] = bytes32(uint256(2));

        // Well-formed bytecode
        bytecodes[1] = vm.getCode(MOCK_FACET_PATH);
        salts[1] = bytes32(uint256(1));

        // This should revert when trying to process the return data
        vm.expectRevert("Multicall3: call failed");
        this.deployMultiple(bytecodes, salts);
    }

    function test_deployMultiple() public {
        // Prepare three contract deployments
        bytes[] memory bytecodes = new bytes[](3);
        bytes32[] memory salts = new bytes32[](3);

        bytes memory mockFacetBytecode = vm.getCode(MOCK_FACET_PATH);
        for (uint256 i; i < 3; ++i) {
            bytecodes[i] = mockFacetBytecode;
            salts[i] = bytes32(uint256(i + 10));
        }

        // Calculate expected addresses before deployment
        address[] memory expectedAddresses = new address[](3);
        for (uint256 i; i < 3; ++i) {
            expectedAddresses[i] = LibClone.predictDeterministicAddress(
                keccak256(bytecodes[i]), salts[i], CREATE2_FACTORY
            );
        }

        // Deploy multiple contracts with multicall
        address[] memory addresses = LibDeploy.deployMultiple(bytecodes, salts);

        // Verify all contracts were deployed correctly
        assertEq(addresses.length, 3, "Should deploy 3 contracts");

        for (uint256 i; i < 3; ++i) {
            assertTrue(addresses[i] != address(0), "Contract should be deployed");
            assertEq(addresses[i], expectedAddresses[i], "Address should match predicted address");
            assertTrue(addresses[i].code.length > 0, "Contract should have code");
        }
    }

    function deployMultiple(
        bytes[] memory bytecodes,
        bytes32[] memory salts
    )
        external
        returns (address[] memory)
    {
        return LibDeploy.deployMultiple(bytecodes, salts);
    }
}
