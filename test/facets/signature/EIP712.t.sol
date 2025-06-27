// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IDiamond} from "src/Diamond.sol";

// libraries

// contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployMockERC20Permit} from "scripts/deployments/mocks/DeployMockERC20Permit.sol";
import {EIP712Utils} from "test/facets/signature/EIP712Utils.sol";

import {ERC20} from "src/facets/token/ERC20/ERC20.sol";

import {MockEIP712} from "test/mocks/MockEIP712.sol";
import {MockERC20Permit} from "test/mocks/MockERC20Permit.sol";

contract EIP712Test is TestUtils, EIP712Utils {
    DeployDiamond diamondHelper = new DeployDiamond();

    string public constant NAME = "Towns";
    string public constant SYMBOL = "TOWNS";
    string public constant VERSION = "1";

    address diamond;
    address deployer;

    MockERC20Permit erc20;
    MockEIP712 eip712;

    function setUp() public {
        deployer = getDeployer();
        address mockERC20PermitAddress = DeployMockERC20Permit.deploy();

        diamondHelper.addFacet(
            DeployMockERC20Permit.makeCut(mockERC20PermitAddress, IDiamond.FacetCutAction.Add),
            mockERC20PermitAddress,
            DeployMockERC20Permit.makeInitData(NAME, SYMBOL, 18)
        );

        diamond = diamondHelper.deploy(deployer);
        erc20 = MockERC20Permit(diamond);
        eip712 = new MockEIP712();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20Permit                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_mint(address to, uint256 amount) external {
        vm.assume(to != address(0));
        vm.assume(to != address(erc20));

        erc20.mint(to, amount);
        assertEq(erc20.balanceOf(to), amount);
    }

    function test_permit(uint256 privateKey, address spender, uint256 amount) external {
        privateKey = bound(privateKey, 1, 1000);
        amount = bound(amount, 1, 1000);

        vm.assume(spender != address(0));
        vm.assume(spender != address(erc20));

        address owner = vm.addr(privateKey);
        vm.assume(spender != owner);

        uint256 deadline = block.timestamp + 100;

        erc20.mint(owner, amount);

        (uint8 v, bytes32 r, bytes32 s) =
            signPermit(privateKey, address(erc20), owner, spender, amount, deadline);

        vm.prank(owner);
        erc20.permit(owner, spender, amount, deadline, v, r, s);

        assertEq(erc20.allowance(owner, spender), amount);
    }

    function test_erc20_domainSeparator() external view {
        bytes32 domainSeparator = erc20.DOMAIN_SEPARATOR();
        assertEq(domainSeparator, _buildDomainSeparator(NAME, VERSION, address(erc20)));
    }

    function test_erc20_nonces() external view {
        address user = _randomAddress();
        uint256 nonce = erc20.nonces(user);
        assertEq(nonce, 0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EIP712                                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function test_eip712_domainSeparator() external view {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            ,
        ) = eip712.eip712Domain();

        assertEq(name, "MockEIP712");
        assertEq(version, "1.0");
        assertEq(fields, hex"0f"); // 01111
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, address(eip712));
    }

    function test_eip712_domainSeparator_overridden() external view {
        bytes32 separator = eip712.DOMAIN_SEPARATOR();
        bytes32 expectedSeparator = _buildDomainSeparator("MockEIP712", "1.0", address(eip712));
        assertEq(separator, expectedSeparator);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           Utils                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _buildDomainSeparator(
        string memory name,
        string memory version,
        address verifyingContract
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                verifyingContract
            )
        );
    }
}
