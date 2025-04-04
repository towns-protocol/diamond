// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

// utils
import {TestUtils} from "test/TestUtils.sol";

//interfaces

//libraries

//contracts
import {DeployMockERC721} from "scripts/deployments/mocks/DeployMockERC721.sol";
import {MockERC721} from "test/mocks/MockERC721.sol";

contract ERC721Test is TestUtils {
    DeployMockERC721 deployMockERC721Helper = new DeployMockERC721();

    MockERC721 mockERC721;

    address deployer;

    function setUp() external {
        deployer = getDeployer();
        mockERC721 = MockERC721(deployMockERC721Helper.deploy(deployer));
    }

    modifier givenTokensAreMinted(address to, uint256 tokenId) {
        vm.assume(to != address(0));
        mockERC721.mint(to, tokenId);
        _;
    }

    modifier givenAccountIsApproved(address to, address operator, uint256 tokenId) {
        vm.assume(to != operator);
        vm.prank(to);
        mockERC721.approve(operator, tokenId);
        _;
    }

    modifier givenAccountIsApprovedForAll(address to, address operator, bool approved) {
        vm.assume(to != operator);
        vm.prank(to);
        mockERC721.setApprovalForAll(operator, approved);
        _;
    }

    function test_totalSupply(
        address to,
        uint256 tokenId
    )
        public
        givenTokensAreMinted(to, tokenId)
    {
        assertEq(mockERC721.totalSupply(), 1);
        assertEq(mockERC721.balanceOf(to), 1);
        assertEq(mockERC721.ownerOf(tokenId), to);
    }

    function test_approve(
        address to,
        address account,
        uint256 tokenId
    )
        public
        givenTokensAreMinted(to, tokenId)
        givenAccountIsApproved(to, account, tokenId)
    {
        assertEq(mockERC721.getApproved(tokenId), account);
    }

    function test_isApprovedForAll(
        address to,
        address account,
        uint256 tokenId
    )
        public
        givenTokensAreMinted(to, tokenId)
        givenAccountIsApprovedForAll(to, account, true)
    {
        assertEq(mockERC721.isApprovedForAll(to, account), true);
    }

    function test_transfer(
        address from,
        address to,
        uint256 tokenId
    )
        public
        givenTokensAreMinted(from, tokenId)
    {
        vm.assume(from != to);
        vm.assume(to != address(0));

        vm.prank(from);
        mockERC721.transferFrom(from, to, tokenId);
        assertEq(mockERC721.ownerOf(tokenId), to);
        assertEq(mockERC721.balanceOf(from), 0);
        assertEq(mockERC721.balanceOf(to), 1);
    }
}
