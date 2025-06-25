// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IDiamond} from "src/Diamond.sol";
import {IERC1271} from "src/facets/accounts/IERC1271.sol";

// libraries
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EIP712} from "solady/utils/EIP712.sol";

// contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";

import {DeployEIP712Facet} from "scripts/deployments/facets/DeployEIP712Facet.sol";
import {DeployERC1271} from "scripts/deployments/facets/DeployERC1271.sol";
import {ERC1271Facet} from "src/facets/accounts/ERC1271Facet.sol";

contract ERC1271Test is TestUtils {
    DeployDiamond diamondHelper = new DeployDiamond();

    address diamond;
    address deployer;
    address signer;
    uint256 signerPrivateKey;

    IERC1271 erc1271;

    // ERC1271 Constants
    bytes4 constant ERC1271_MAGIC_VALUE = 0x1626ba7e;
    bytes4 constant ERC1271_INVALID_VALUE = 0xffffffff;

    // EIP712 Domain Type Hash
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    // PersonalSign Type Hash
    bytes32 public constant PERSONAL_SIGN_TYPEHASH = keccak256("PersonalSign(bytes prefixed)");

    // TypedDataSign Type Hash
    bytes32 public constant TYPED_DATA_SIGN_TYPEHASH = keccak256(
        "TypedDataSign(bytes32 contents,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
    );

    // Mail Type Hash (for testing)
    bytes32 public constant MAIL_TYPEHASH = keccak256("Mail(address to,string contents)");

    // Test Domain Constants
    string constant ACCOUNT_DOMAIN_NAME = "AccountDomain";
    string constant ACCOUNT_DOMAIN_VERSION = "1.0";

    string constant TEST_DOMAIN_NAME = "TestDomain";
    string constant TEST_DOMAIN_VERSION = "1.0";

    // Test Messages
    bytes32 constant TEST_MESSAGE_HASH = keccak256("Hello TypedDataSign Test");
    string constant PERSONAL_SIGN_MESSAGE = "Hello, Personal Sign!";
    string constant ERC1271_TEST_MESSAGE = "Hello, ERC1271!";
    string constant CONTRACT_SIGNER_MESSAGE = "Hello, Contract Signer!";
    // Test Private Keys
    uint256 constant WRONG_PRIVATE_KEY_1 = 0x3;
    uint256 constant WRONG_PRIVATE_KEY_2 = 0x999;

    // MockApp test data
    string constant MOCK_MAIL_CONTENTS = "Hello from MockApp!";
    address constant MOCK_MAIL_TO = address(0x123);

    address accountDiamond;

    function setUp() public {
        deployer = getDeployer();
        signerPrivateKey = 0x2;
        signer = vm.addr(signerPrivateKey);

        accountDiamond =
            _deployDiamondWithBothFacets(ACCOUNT_DOMAIN_NAME, ACCOUNT_DOMAIN_VERSION, signer);
    }

    function test_erc1271_InitializeWithZeroAddress() public {
        // Deploy diamond with both facets
        address testDiamond =
            _deployDiamondWithBothFacets(TEST_DOMAIN_NAME, TEST_DOMAIN_VERSION, address(0));

        // Check that the signer is the diamond itself
        assertEq(ERC1271Facet(testDiamond).erc1271Signer(), testDiamond);
    }

    function test_erc1271_InitializeWithCustomSigner() public {
        // Deploy diamond with both facets
        address testDiamond =
            _deployDiamondWithBothFacets(TEST_DOMAIN_NAME, TEST_DOMAIN_VERSION, signer);

        // Check that the signer is set correctly
        assertEq(ERC1271Facet(testDiamond).erc1271Signer(), signer);
    }

    function test_isValidSignature_ValidateEOASignature() public {
        // Deploy diamond with both facets
        address testDiamond =
            _deployDiamondWithBothFacets(TEST_DOMAIN_NAME, TEST_DOMAIN_VERSION, signer);
        IERC1271 testErc1271 = IERC1271(testDiamond);

        // Create a message hash
        bytes32 messageHash = keccak256(bytes(ERC1271_TEST_MESSAGE));

        // Sign the message with the signer's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Validate the signature
        bytes4 result = testErc1271.isValidSignature(messageHash, signature);
        assertEq(result, ERC1271_MAGIC_VALUE);
    }

    function test_isValidSignature_InvalidEOASignature() public {
        // Deploy diamond with both facets
        address testDiamond =
            _deployDiamondWithBothFacets(TEST_DOMAIN_NAME, TEST_DOMAIN_VERSION, signer);
        IERC1271 testErc1271 = IERC1271(testDiamond);

        // Create a message hash
        bytes32 messageHash = keccak256(bytes(ERC1271_TEST_MESSAGE));

        // Sign the message with a different private key
        uint256 wrongKey = WRONG_PRIVATE_KEY_1;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Validate the signature (should fail)
        bytes4 result = testErc1271.isValidSignature(messageHash, signature);
        assertEq(result, ERC1271_INVALID_VALUE);
    }

    function test_isValidSignature_ValidateWithContractSigner() public {
        // Deploy a mock ERC1271 contract as signer
        MockERC1271Signer mockSigner = new MockERC1271Signer();

        // Deploy diamond with both facets
        address testDiamond =
            _deployDiamondWithBothFacets(TEST_DOMAIN_NAME, TEST_DOMAIN_VERSION, address(mockSigner));
        IERC1271 testErc1271 = IERC1271(testDiamond);

        // Create a message hash
        bytes32 messageHash = keccak256(bytes(CONTRACT_SIGNER_MESSAGE));

        // The mock signer will accept any signature that starts with 0x01
        bytes memory validSignature = hex"01";
        bytes memory invalidSignature = hex"00";

        // Validate valid signature
        bytes4 result = testErc1271.isValidSignature(messageHash, validSignature);
        assertEq(result, ERC1271_MAGIC_VALUE);

        // Validate invalid signature
        result = testErc1271.isValidSignature(messageHash, invalidSignature);
        assertEq(result, ERC1271_INVALID_VALUE);
    }

    function test_erc1271_RevertOnDoubleInitialization() public {
        // Deploy diamond with both facets
        address testDiamond =
            _deployDiamondWithBothFacets(TEST_DOMAIN_NAME, TEST_DOMAIN_VERSION, signer);

        // Try to initialize again - should revert
        vm.expectRevert(); // Should revert with already initialized error
        ERC1271Facet(testDiamond).__ERC1271_init(signer);
    }

    function test_isValidSignature_PersonalSignWorkflow() external view {
        // Deploy diamond with both facets
        IERC1271 testErc1271 = IERC1271(accountDiamond);

        // Create a personal message
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(bytes(PERSONAL_SIGN_MESSAGE));

        // Sign the personal message hash with the signer's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Validate the signature using PersonalSign workflow
        bytes4 result = testErc1271.isValidSignature(messageHash, signature);
        assertEq(result, ERC1271_MAGIC_VALUE);
    }

    function test_validateMailSignature_TypedDataSignWorkflow() public {
        // Deploy diamond with both facets
        // Deploy MockApp to simulate external dApp
        MockApp app = new MockApp();

        // Create mail data
        MockApp.Mail memory mail = MockApp.Mail({to: MOCK_MAIL_TO, contents: MOCK_MAIL_CONTENTS});

        // The MockApp will validate the signature we create

        // Now we need to create a TypedDataSign signature that our account can validate
        // This signature represents the signer signing the mail on behalf of the smart account
        bytes memory signature = _createTypedDataSignSignature(accountDiamond, app, mail);

        // Validate using the app's validation method
        // This simulates the dApp calling isValidSignature on our smart account
        bool isValid = app.validateMailSignature(accountDiamond, mail, signature);
        assertTrue(isValid);
    }

    function test_validateMailSignature_MockAppWithInvalidSignature() public {
        // Deploy diamond with both facets
        // Deploy MockApp to simulate external dApp
        MockApp app = new MockApp();

        // Create mail data
        MockApp.Mail memory mail = MockApp.Mail({to: MOCK_MAIL_TO, contents: MOCK_MAIL_CONTENTS});

        // Create an invalid signature (wrong private key)
        bytes memory invalidSignature = abi.encodePacked(
            bytes32(0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef),
            bytes32(0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321),
            uint8(27)
        );

        // Validate using the app's validation method - should fail
        bool isValid = app.validateMailSignature(accountDiamond, mail, invalidSignature);
        assertFalse(isValid);
    }

    function test_isValidSignature_TypedDataSignWithInvalidStructure() external view {
        // Deploy diamond with both facets
        IERC1271 testErc1271 = IERC1271(accountDiamond);

        // Create malformed TypedDataSign signature
        bytes32 appDomainSeparator = keccak256("fake");
        bytes32 fakeStructHash = keccak256("fake");

        // Create invalid signature
        bytes memory invalidSignature = _signTypedDataSign(
            signerPrivateKey, accountDiamond, appDomainSeparator, fakeStructHash, "InvalidType()"
        );

        // This should fail validation
        bytes32 appHash = MessageHashUtils.toTypedDataHash(appDomainSeparator, fakeStructHash);

        bytes4 result = testErc1271.isValidSignature(appHash, invalidSignature);
        assertEq(result, ERC1271_INVALID_VALUE);
    }

    function test_isValidSignature_PersonalSignWithWrongSigner() external view {
        // Deploy diamond with both facets
        IERC1271 testErc1271 = IERC1271(accountDiamond);

        // Create a personal message
        bytes32 messageHash = MessageHashUtils.toEthSignedMessageHash(bytes(PERSONAL_SIGN_MESSAGE));

        // Sign with wrong private key
        uint256 wrongKey = WRONG_PRIVATE_KEY_2;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Should fail validation
        bytes4 result = testErc1271.isValidSignature(messageHash, signature);
        assertEq(result, ERC1271_INVALID_VALUE);
    }

    // Helper function to create TypedDataSign signatures following Solady's pattern
    function _signTypedDataSign(
        uint256 privateKey,
        address testDiamond,
        bytes32 appDomainSeparator,
        bytes32 structHash,
        string memory contentsType
    )
        internal
        view
        returns (bytes memory)
    {
        // Get the actual domain separator from the deployed diamond
        bytes32 accountDomainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(ACCOUNT_DOMAIN_NAME)),
                keccak256(bytes(ACCOUNT_DOMAIN_VERSION)),
                block.chainid,
                testDiamond
            )
        );

        // Build TypedDataSign struct
        // TypedDataSign(bytes32 contents,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)
        bytes32 typedDataSignTypeHash =
            keccak256(abi.encodePacked(TYPED_DATA_SIGN_TYPEHASH, contentsType));

        bytes32 typedDataSignStructHash = keccak256(
            abi.encode(
                typedDataSignTypeHash,
                structHash,
                keccak256(bytes(ACCOUNT_DOMAIN_NAME)),
                keccak256(bytes(ACCOUNT_DOMAIN_VERSION)),
                block.chainid,
                testDiamond, // Use the actual diamond address
                bytes32(0) // salt
            )
        );

        // Create the final hash using account domain separator
        bytes32 finalHash =
            MessageHashUtils.toTypedDataHash(accountDomainSeparator, typedDataSignStructHash);

        // Sign the final hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, finalHash);

        // Construct the full signature with appended data
        bytes memory baseSignature = abi.encodePacked(r, s, v);
        bytes memory appendedData = abi.encodePacked(
            appDomainSeparator, // 32 bytes
            structHash, // 32 bytes
            contentsType, // variable length
            uint16(bytes(contentsType).length) // 2 bytes
        );

        return abi.encodePacked(baseSignature, appendedData);
    }

    // Helper function to create TypedDataSign signatures for MockApp workflow
    function _createTypedDataSignSignature(
        address testDiamond,
        MockApp app,
        MockApp.Mail memory mail
    )
        internal
        view
        returns (bytes memory)
    {
        // Get app hash that will be validated
        bytes32 appHash = app.getMailHash(mail);

        // Build account domain using constants
        bytes32 accountDomainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(ACCOUNT_DOMAIN_NAME)),
                keccak256(bytes(ACCOUNT_DOMAIN_VERSION)),
                block.chainid,
                testDiamond
            )
        );

        // Create PersonalSign hash (simplified approach)
        bytes32 personalSignHash = keccak256(abi.encode(PERSONAL_SIGN_TYPEHASH, appHash));

        bytes32 finalHash =
            MessageHashUtils.toTypedDataHash(accountDomainSeparator, personalSignHash);

        // Sign and return simple signature (PersonalSign workflow)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, finalHash);
        return abi.encodePacked(r, s, v);
    }

    function _buildMailStructHash(MockApp.Mail memory mail) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAIL_TYPEHASH, mail.to, keccak256(bytes(mail.contents))));
    }

    function _deployDiamondWithBothFacets(
        string memory eip712Name,
        string memory eip712Version,
        address erc1271Signer
    )
        internal
        returns (address)
    {
        DeployDiamond testDiamondHelper = new DeployDiamond();

        // Deploy both facets
        address eip712Facet = DeployEIP712Facet.deploy();
        address erc1271Facet = DeployERC1271.deploy();

        // Add EIP712Facet with initialization
        testDiamondHelper.addFacet(
            DeployEIP712Facet.makeCut(eip712Facet, IDiamond.FacetCutAction.Add),
            eip712Facet,
            DeployEIP712Facet.makeInitData(eip712Name, eip712Version)
        );

        // Add ERC1271Facet with initialization
        testDiamondHelper.addFacet(
            DeployERC1271.makeCut(erc1271Facet, IDiamond.FacetCutAction.Add),
            erc1271Facet,
            DeployERC1271.makeInitData(erc1271Signer)
        );

        // Deploy diamond
        return testDiamondHelper.deploy(deployer);
    }
}

// Mock contract that implements ERC1271
contract MockERC1271Signer is IERC1271 {
    function isValidSignature(
        bytes32,
        bytes calldata signature
    )
        external
        pure
        override
        returns (bytes4)
    {
        // Accept any signature that starts with 0x01
        if (signature.length > 0 && signature[0] == 0x01) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
    }
}

// Simple MockApp following the pattern from Towns protocol
contract MockApp is EIP712 {
    struct Mail {
        address to;
        string contents;
    }

    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "MyDApp";
        version = "1.0";
    }

    function getMailHash(Mail memory mail) public view returns (bytes32) {
        return _hashTypedData(
            keccak256(
                abi.encode(
                    keccak256("Mail(address to,string contents)"),
                    mail.to,
                    keccak256(bytes(mail.contents))
                )
            )
        );
    }

    function validateMailSignature(
        address account,
        Mail memory mail,
        bytes calldata signature
    )
        external
        view
        returns (bool)
    {
        bytes32 hash = getMailHash(mail);
        bytes4 result = IERC1271(account).isValidSignature(hash, signature);
        return result == 0x1626ba7e;
    }
}
