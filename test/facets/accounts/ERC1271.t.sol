// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces

import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {IDiamond} from "src/Diamond.sol";

// libraries
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";

import {DeployEIP712Facet} from "scripts/deployments/facets/DeployEIP712Facet.sol";
import {DeployERC1271Facet} from "scripts/deployments/facets/DeployERC1271Facet.sol";
import {ERC1271Facet} from "src/facets/accounts/ERC1271Facet.sol";
import {EIP712Facet} from "src/utils/cryptography/EIP712Facet.sol";
import {MockERC1271Signer} from "test/mocks/MockERC1271Signer.sol";
import {MockMailApp} from "test/mocks/MockMailApp.sol";

// debuggging
import {console} from "forge-std/console.sol";

contract ERC1271Test is TestUtils {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // ERC1271 Standard Values
    bytes4 private constant MAGIC_VALUE = 0x1626ba7e;
    bytes4 private constant INVALID_VALUE = 0xffffffff;

    // EIP712 Type Hashes
    bytes32 private constant PERSONAL_SIGN_TYPEHASH = keccak256("PersonalSign(bytes prefixed)");

    // Default Test Values
    string private constant DEFAULT_DOMAIN_NAME = "Diamonds";
    string private constant DEFAULT_DOMAIN_VERSION = "1";
    string private constant DEFAULT_TEST_MESSAGE = "Hello, ERC1271!";

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         STORAGE                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    address private diamond;
    address private deployer;
    address private signer;
    uint256 private signerPrivateKey;

    ERC1271Facet private erc1271;
    EIP712Facet private eip712;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         SETUP                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function setUp() public {
        deployer = getDeployer();
        vm.txGasPrice(1);
    }

    modifier givenDiamondIsDeployed() {
        signerPrivateKey = boundPrivateKey(_randomUint256());
        signer = vm.addr(signerPrivateKey);
        diamond = _createDiamond(DEFAULT_DOMAIN_NAME, DEFAULT_DOMAIN_VERSION, signer);
        erc1271 = ERC1271Facet(diamond);
        eip712 = EIP712Facet(diamond);
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         TESTS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_erc1271_customSigner() external givenDiamondIsDeployed {
        assertEq(erc1271.erc1271Signer(), signer);
    }

    function test_erc1271_zeroSigner() external givenDiamondIsDeployed {
        address zeroDiamond = _createDiamond("MockEIP712", "1.0", address(0));
        assertEq(ERC1271Facet(zeroDiamond).erc1271Signer(), zeroDiamond);
    }

    function test_erc1271_rejectInvalidSignature() external givenDiamondIsDeployed {
        bytes32 messageHash = _createMessageHash(DEFAULT_TEST_MESSAGE);
        bytes memory rawSignature = _createRawSignature(signerPrivateKey, messageHash);

        _assertInvalidSignatureForValidator(messageHash, rawSignature, address(eip712));
    }

    function test_erc1271_validatePersonalSignature() external givenDiamondIsDeployed {
        bytes32 messageHash = _createMessageHash(DEFAULT_TEST_MESSAGE);
        bytes memory signature =
            _createPersonalSignature(signerPrivateKey, messageHash, address(eip712));

        _assertValidSignatureForValidator(messageHash, signature, address(eip712));
    }

    function test_erc1271_rejectInvalidPersonalSignature() external givenDiamondIsDeployed {
        bytes32 messageHash = _createMessageHash(DEFAULT_TEST_MESSAGE);
        uint256 wrongPrivateKey = _createWrongPrivateKey();
        bytes memory signature =
            _createPersonalSignature(wrongPrivateKey, messageHash, address(eip712));

        _assertInvalidSignatureForValidator(messageHash, signature, address(eip712));
    }

    function test_erc1271_validateContractSignerSignature() external {
        uint256 ownerPrivateKey = boundPrivateKey(_randomUint256());
        address owner = vm.addr(ownerPrivateKey);
        address mockSigner = address(new MockERC1271Signer(owner));
        address validator = _createDiamond("Account", "1.0", mockSigner);

        bytes32 messageHash = _createMessageHash(DEFAULT_TEST_MESSAGE);
        bytes memory signature = _createPersonalSignature(
            ownerPrivateKey,
            messageHash,
            validator // validator is the diamond that contains the mock signer
        );

        assertEq(IERC1271(validator).isValidSignature(messageHash, signature), MAGIC_VALUE);
    }

    function test_erc1271_validateMailSignature() external {
        MockMailApp app = new MockMailApp();
        MockMailApp.Mail memory mail = _createTestMail();

        uint256 pvk = boundPrivateKey(_randomUint256());
        address pk = vm.addr(pvk);

        address validator = _createDiamond(DEFAULT_DOMAIN_NAME, DEFAULT_DOMAIN_VERSION, pk);

        bytes32 dataHash = app.getDataHash(mail);
        bytes memory signature = _createPersonalSignature(pvk, dataHash, validator);

        assertEq(IERC1271(validator).isValidSignature(dataHash, signature), MAGIC_VALUE);

        assertTrue(app.validateSignature(signature, app.getStructHash(mail), validator));
    }

    function test_erc1271_validateNestedTypedDataSignWithMailApp() external {
        MockMailApp app = new MockMailApp();
        MockMailApp.Mail memory mail = _createTestMail();

        uint256 pvk = boundPrivateKey(_randomUint256());
        address pk = vm.addr(pvk);

        address validator = _createDiamond(DEFAULT_DOMAIN_NAME, DEFAULT_DOMAIN_VERSION, pk);

        bytes32 dataHash = app.getDataHash(mail);
        TypedDataContext memory ctx = _createTypedDataContextWithMailApp(dataHash, validator);

        bytes memory signature = _createTypedDataSignature(ctx, pvk, validator);

        bytes32 contentHash = MessageHashUtils.toTypedDataHash(ctx.domainSeparator, ctx.contents);

        // Validate the signature against the contentHash directly
        _assertValidSignatureForValidator(contentHash, signature, validator);

        assertTrue(app.validateSignature(signature, ctx.contents, validator));
    }

    function test_erc1271_validateNestedTypedDataSign() external {
        uint256 pvk = boundPrivateKey(_randomUint256());
        address pk = vm.addr(pvk);

        address validator = _createDiamond(DEFAULT_DOMAIN_NAME, DEFAULT_DOMAIN_VERSION, pk);

        TypedDataContext memory ctx = _createTypedDataContext(validator);
        bytes memory signature = _createTypedDataSignature(ctx, pvk, validator);
        bytes32 contentHash = MessageHashUtils.toTypedDataHash(ctx.domainSeparator, ctx.contents);

        _assertValidSignatureForValidator(contentHash, signature, validator);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      TEST HELPERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    struct TypedDataContext {
        bytes contentsType;
        bytes contentsName;
        bytes32 contents;
        bytes32 domainSeparator;
        bytes contentsDescription;
    }

    function _createTypedDataContextWithMailApp(
        bytes32 dataHash,
        address validator
    )
        private
        view
        returns (TypedDataContext memory ctx)
    {
        ctx.contentsType = "Mail(address to,string contents)";
        ctx.contentsName = "Mail";
        ctx.contents = dataHash;
        ctx.domainSeparator = EIP712Facet(validator).DOMAIN_SEPARATOR();
        ctx.contentsDescription = abi.encodePacked(ctx.contentsType, ctx.contentsName);
    }

    function _createTypedDataContext(address validator)
        private
        view
        returns (TypedDataContext memory ctx)
    {
        ctx.contentsType = "Contents(bytes32 stuff)";
        ctx.contentsName = "Contents";
        ctx.contents = keccak256(abi.encode(_randomUint256(), ctx.contentsType));
        ctx.domainSeparator = EIP712Facet(validator).DOMAIN_SEPARATOR();
        ctx.contentsDescription = abi.encodePacked(ctx.contentsType, ctx.contentsName);
    }

    function _createTestMail() private pure returns (MockMailApp.Mail memory) {
        return MockMailApp.Mail({to: address(0x123), contents: "Hello, Mail!"});
    }

    function _createWrongPrivateKey() private view returns (uint256 wrongPrivateKey) {
        wrongPrivateKey = boundPrivateKey(_randomUint256());
        require(wrongPrivateKey != signerPrivateKey, "Wrong key matches signer key");
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   ASSERTION HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _assertInvalidSignatureForValidator(
        bytes32 messageHash,
        bytes memory signature,
        address validator
    )
        private
        view
    {
        assertEq(IERC1271(validator).isValidSignature(messageHash, signature), INVALID_VALUE);
    }

    function _assertValidSignatureForValidator(
        bytes32 messageHash,
        bytes memory signature,
        address validator
    )
        private
        view
    {
        assertEq(IERC1271(validator).isValidSignature(messageHash, signature), MAGIC_VALUE);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   MESSAGE HELPERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _createMessageHash(string memory message) private pure returns (bytes32) {
        return keccak256(bytes(message));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  SIGNATURE HELPERS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _createRawSignature(
        uint256 privateKey,
        bytes32 messageHash
    )
        private
        pure
        returns (bytes memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
        return abi.encodePacked(r, s, v);
    }

    function _createPersonalSignature(
        uint256 privateKey,
        bytes32 messageHash,
        address validator
    )
        private
        view
        returns (bytes memory)
    {
        bytes32 structHash = keccak256(abi.encode(PERSONAL_SIGN_TYPEHASH, messageHash));
        bytes32 domainSeparator = EIP712Facet(validator).DOMAIN_SEPARATOR();
        bytes32 finalHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, finalHash);
        return abi.encodePacked(r, s, v);
    }

    function _createTypedDataSignature(
        TypedDataContext memory ctx,
        uint256 privateKey,
        address validator
    )
        private
        view
        returns (bytes memory)
    {
        bytes32 erc1271Hash =
            _createERC1271Hash(validator, ctx.contents, ctx.contentsType, ctx.contentsName);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, erc1271Hash);

        return abi.encodePacked(
            r,
            s,
            v,
            ctx.domainSeparator,
            ctx.contents,
            ctx.contentsDescription,
            uint16(ctx.contentsDescription.length)
        );
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    DIAMOND HELPERS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _createDiamond(
        string memory domainName,
        string memory domainVersion,
        address erc1271Signer
    )
        private
        returns (address)
    {
        DeployDiamond helper = new DeployDiamond();

        address erc1271Facet = DeployERC1271Facet.deploy();
        address eip712Facet = DeployEIP712Facet.deploy();

        _addEIP712Facet(helper, eip712Facet, domainName, domainVersion);
        _addERC1271Facet(helper, erc1271Facet, erc1271Signer);

        return helper.deploy(deployer);
    }

    function _addEIP712Facet(
        DeployDiamond helper,
        address facetAddress,
        string memory name,
        string memory version
    )
        private
    {
        helper.addFacet(
            DeployEIP712Facet.makeCut(facetAddress, IDiamond.FacetCutAction.Add),
            facetAddress,
            DeployEIP712Facet.makeInitData(name, version)
        );
    }

    function _addERC1271Facet(
        DeployDiamond helper,
        address facetAddress,
        address signerAddress
    )
        private
    {
        helper.addFacet(
            DeployERC1271Facet.makeCut(facetAddress, IDiamond.FacetCutAction.Add),
            facetAddress,
            DeployERC1271Facet.makeInitData(signerAddress)
        );
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EIP712 HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _createERC1271Hash(
        address validator,
        bytes32 contents,
        bytes memory contentsType,
        bytes memory contentsName
    )
        private
        view
        returns (bytes32)
    {
        (
            ,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
        ) = EIP712Facet(validator).eip712Domain();

        bytes32 typedDataSignStructHash = keccak256(
            abi.encode(
                _createTypedDataSignTypeHash(contentsType, contentsName),
                contents,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract,
                salt
            )
        );

        return keccak256(
            abi.encodePacked(
                "\x19\x01", EIP712Facet(validator).DOMAIN_SEPARATOR(), typedDataSignStructHash
            )
        );
    }

    function _createTypedDataSignTypeHash(
        bytes memory contentsType,
        bytes memory contentsName
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "TypedDataSign(",
                contentsName,
                " contents,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)",
                contentsType
            )
        );
    }
}
