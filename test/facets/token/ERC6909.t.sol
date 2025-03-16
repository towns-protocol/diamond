// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

// utils
import {TestUtils} from "test/TestUtils.sol";

//interfaces
import {IERC6909Base} from "src/facets/token/ERC6909/IERC6909.sol";

//libraries

//contracts
import {DeployMockERC6909} from "scripts/deployments/mocks/DeployMockERC6909.s.sol";
import {MockERC6909} from "test/mocks/MockERC6909.sol";

contract ERC6909Test is TestUtils, IERC6909Base {
  DeployMockERC6909 deployMockERC6909Helper = new DeployMockERC6909();
  MockERC6909 facet;

  address deployer;
  address constant ZERO_ADDRESS = address(0);

  function setUp() external {
    deployer = getDeployer();
    facet = MockERC6909(deployMockERC6909Helper.deploy(deployer));
  }

  modifier givenTokensAreMinted(address to, uint256 tokenId, uint256 amount) {
    vm.assume(to != address(0));
    facet.mint(to, tokenId, amount);
    _;
  }

  modifier givenTokensAreBurned(address from, uint256 tokenId, uint256 amount) {
    facet.burn(from, tokenId, amount);
    _;
  }

  modifier givenAccountIsApproved(
    address owner,
    address spender,
    uint256 tokenId,
    uint256 amount
  ) {
    vm.assume(owner != spender);
    vm.prank(owner);
    facet.approve(spender, tokenId, amount);
    _;
  }

  modifier givenOperatorIsSet(address owner, address operator, bool approved) {
    vm.prank(owner);
    facet.setOperator(operator, approved);
    _;
  }

  function test_totalSupply_gas()
    public
    givenTokensAreMinted(address(this), 1, 1 ether)
  {
    assertEq(facet.totalSupply(1), 1 ether);
  }

  function test_totalSupply(
    uint256 tokenId,
    uint256 amount
  ) public givenTokensAreMinted(address(this), tokenId, amount) {
    assertEq(facet.totalSupply(tokenId), amount);
  }

  function test_balanceOf_gas()
    public
    givenTokensAreMinted(address(this), 1, 1 ether)
  {
    assertEq(facet.balanceOf(address(this), 1), 1 ether);
  }

  function test_balanceOf(
    address to,
    uint256 tokenId,
    uint256 amount
  ) public givenTokensAreMinted(to, tokenId, amount) {
    assertEq(facet.balanceOf(to, tokenId), amount);
  }

  function test_allowance(
    address owner,
    address spender,
    uint256 tokenId,
    uint256 amount
  ) public givenAccountIsApproved(owner, spender, tokenId, amount) {
    assertEq(facet.allowance(owner, spender, tokenId), amount);
  }

  function test_isOperator_gas()
    public
    givenOperatorIsSet(address(this), address(1), true)
  {
    assertTrue(facet.isOperator(address(this), address(1)));
  }

  function test_isOperator(
    address owner,
    address spender,
    bool approved
  ) public givenOperatorIsSet(owner, spender, approved) {
    assertEq(facet.isOperator(owner, spender), approved);
  }

  function test_transfer_gas()
    public
    givenTokensAreMinted(address(this), 1, 1 ether)
  {
    address to = address(1);
    bool success = facet.transfer(to, 1, 1 ether);
    assertTrue(success);
    assertEq(facet.balanceOf(address(this), 1), 0);
    assertEq(facet.balanceOf(to, 1), 1 ether);
  }

  function test_transfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) public givenTokensAreMinted(from, tokenId, amount) {
    vm.assume(from != to);
    vm.assume(to != ZERO_ADDRESS);

    vm.prank(from);
    bool success = facet.transfer(to, tokenId, amount);

    assertTrue(success);
    assertEq(facet.balanceOf(from, tokenId), 0);
    assertEq(facet.balanceOf(to, tokenId), amount);
  }

  function test_transferZeroAmount(
    address from,
    address to,
    uint256 tokenId
  ) public {
    vm.assume(from != ZERO_ADDRESS);
    vm.assume(to != ZERO_ADDRESS);

    vm.prank(from);
    bool success = facet.transfer(to, tokenId, 0);

    assertTrue(success);
    // No state changes expected for zero amount
    assertEq(facet.balanceOf(from, tokenId), 0);
    assertEq(facet.balanceOf(to, tokenId), 0);
  }

  function test_transferInsufficientBalance(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount
  ) public {
    vm.assume(from != ZERO_ADDRESS);
    vm.assume(to != ZERO_ADDRESS);
    vm.assume(amount > 0);

    // No tokens minted, so balance is 0
    vm.prank(from);
    vm.expectRevert(IERC6909Base.InsufficientBalance.selector);
    facet.transfer(to, tokenId, amount);
  }

  function test_approve_gas()
    public
    givenAccountIsApproved(address(this), address(1), 1, 1 ether)
  {
    assertEq(facet.allowance(address(this), address(1), 1), 1 ether);
  }

  function test_approve(
    address owner,
    address spender,
    uint256 tokenId,
    uint256 amount
  ) public {
    vm.assume(owner != ZERO_ADDRESS);
    vm.assume(spender != ZERO_ADDRESS);
    vm.assume(owner != spender);

    vm.expectEmit(address(facet));
    emit Approval(owner, spender, tokenId, amount);

    vm.prank(owner);
    bool success = facet.approve(spender, tokenId, amount);

    assertTrue(success);
    assertEq(facet.allowance(owner, spender, tokenId), amount);
  }

  function test_transferFrom_gas()
    public
    givenTokensAreMinted(address(1), 1, 1 ether)
    givenAccountIsApproved(address(1), address(this), 1, 1 ether)
  {
    address receiver = address(2);
    bool success = facet.transferFrom(address(1), receiver, 1, 1 ether);
    assertTrue(success);
    assertEq(facet.balanceOf(address(1), 1), 0);
    assertEq(facet.balanceOf(receiver, 1), 1 ether);
  }

  function test_transferFrom_withAllowance(
    address owner,
    address spender,
    address receiver,
    uint256 tokenId,
    uint256 amount
  ) public givenTokensAreMinted(owner, tokenId, amount) {
    vm.assume(owner != ZERO_ADDRESS);
    vm.assume(spender != ZERO_ADDRESS);
    vm.assume(receiver != ZERO_ADDRESS);
    vm.assume(owner != spender);
    vm.assume(owner != receiver);
    vm.assume(spender != receiver);
    vm.assume(amount > 0);
    vm.assume(amount < type(uint256).max);

    // Approve spender
    vm.prank(owner);
    facet.approve(spender, tokenId, amount);

    vm.prank(spender);
    bool success = facet.transferFrom(owner, receiver, tokenId, amount);
    assertTrue(success);

    assertEq(facet.balanceOf(owner, tokenId), 0);
    assertEq(facet.balanceOf(receiver, tokenId), amount);
    assertEq(facet.allowance(owner, spender, tokenId), 0);
  }

  function test_transferFrom_withUnlimitedAllowance(
    address owner,
    address spender,
    address receiver,
    uint256 tokenId,
    uint256 amount
  ) public givenTokensAreMinted(owner, tokenId, amount) {
    vm.assume(owner != ZERO_ADDRESS);
    vm.assume(spender != ZERO_ADDRESS);
    vm.assume(receiver != ZERO_ADDRESS);
    vm.assume(owner != spender);
    vm.assume(owner != receiver);
    vm.assume(spender != receiver);

    // Approve spender with unlimited allowance
    vm.prank(owner);
    facet.approve(spender, tokenId, type(uint256).max);

    vm.prank(spender);
    bool success = facet.transferFrom(owner, receiver, tokenId, amount);

    assertTrue(success);
    assertEq(facet.balanceOf(owner, tokenId), 0);
    assertEq(facet.balanceOf(receiver, tokenId), amount);
    assertEq(facet.allowance(owner, spender, tokenId), type(uint256).max);
  }

  function test_transferFrom_asOperator(
    address owner,
    address operator,
    address receiver,
    uint256 tokenId,
    uint256 amount
  ) public givenTokensAreMinted(owner, tokenId, amount) {
    vm.assume(owner != ZERO_ADDRESS);
    vm.assume(operator != ZERO_ADDRESS);
    vm.assume(receiver != ZERO_ADDRESS);
    vm.assume(owner != operator);
    vm.assume(owner != receiver);
    vm.assume(operator != receiver);

    // Set operator
    vm.prank(owner);
    facet.setOperator(operator, true);

    vm.prank(operator);
    bool success = facet.transferFrom(owner, receiver, tokenId, amount);

    assertTrue(success);
    assertEq(facet.balanceOf(owner, tokenId), 0);
    assertEq(facet.balanceOf(receiver, tokenId), amount);
  }

  function test_transferFrom_insufficientPermission(
    address owner,
    address spender,
    address receiver,
    uint256 tokenId,
    uint256 amount,
    uint256 approvedAmount
  ) public givenTokensAreMinted(owner, tokenId, amount) {
    vm.assume(owner != ZERO_ADDRESS);
    vm.assume(spender != ZERO_ADDRESS);
    vm.assume(receiver != ZERO_ADDRESS);
    vm.assume(owner != spender);
    vm.assume(owner != receiver);
    vm.assume(spender != receiver);
    vm.assume(amount > 0);
    approvedAmount = bound(approvedAmount, 0, amount - 1);

    // Approve spender with insufficient allowance
    vm.prank(owner);
    facet.approve(spender, tokenId, approvedAmount);

    vm.prank(spender);
    vm.expectRevert(IERC6909Base.InsufficientPermission.selector);
    facet.transferFrom(owner, receiver, tokenId, amount);
  }

  function test_transferFrom_insufficientBalance(
    address owner,
    address spender,
    address receiver,
    uint256 tokenId,
    uint256 mintAmount,
    uint256 transferAmount
  ) public {
    vm.assume(owner != ZERO_ADDRESS);
    vm.assume(spender != ZERO_ADDRESS);
    vm.assume(receiver != ZERO_ADDRESS);
    vm.assume(owner != spender);
    vm.assume(owner != receiver);
    vm.assume(spender != receiver);
    mintAmount = bound(mintAmount, 1, type(uint256).max - 1);
    transferAmount = bound(transferAmount, mintAmount + 1, type(uint256).max);

    // Mint tokens
    facet.mint(owner, tokenId, mintAmount);

    // Approve spender
    vm.prank(owner);
    facet.approve(spender, tokenId, transferAmount);

    vm.prank(spender);
    vm.expectRevert(IERC6909Base.InsufficientBalance.selector);
    facet.transferFrom(owner, receiver, tokenId, transferAmount);
  }

  function test_setOperator_gas()
    public
    givenOperatorIsSet(address(this), address(1), true)
  {
    assertTrue(facet.isOperator(address(this), address(1)));
  }

  function test_setOperator(
    address owner,
    address operator,
    bool approved
  ) public {
    vm.assume(owner != ZERO_ADDRESS);
    vm.assume(operator != ZERO_ADDRESS);
    vm.assume(owner != operator);

    vm.expectEmit(address(facet));
    emit OperatorSet(owner, operator, approved);

    vm.prank(owner);
    bool success = facet.setOperator(operator, approved);

    assertTrue(success);
    assertEq(facet.isOperator(owner, operator), approved);
  }

  function test_burn_gas()
    public
    givenTokensAreMinted(address(this), 1, 1 ether)
  {
    facet.burn(address(this), 1, 1 ether);
    assertEq(facet.balanceOf(address(this), 1), 0);
    assertEq(facet.totalSupply(1), 0);
  }

  function test_burn(
    address from,
    uint256 tokenId,
    uint256 amount
  ) public givenTokensAreMinted(from, tokenId, amount) {
    vm.prank(from);
    facet.burn(from, tokenId, amount);
    assertEq(facet.balanceOf(from, tokenId), 0);
    assertEq(facet.totalSupply(tokenId), 0);
  }

  function test_burn_insufficientBalance(
    address from,
    uint256 tokenId,
    uint256 mintAmount,
    uint256 burnAmount
  ) public {
    vm.assume(from != ZERO_ADDRESS);
    mintAmount = bound(mintAmount, 1, type(uint256).max - 1);
    burnAmount = bound(burnAmount, mintAmount + 1, type(uint256).max);

    facet.mint(from, tokenId, mintAmount);

    vm.expectRevert(IERC6909Base.InsufficientBalance.selector);
    facet.burn(from, tokenId, burnAmount);
  }

  function test_mint_gas()
    public
    givenTokensAreMinted(address(this), 1, 1 ether)
  {
    assertEq(facet.balanceOf(address(this), 1), 1 ether);
    assertEq(facet.totalSupply(1), 1 ether);
  }

  function test_mint(address to, uint256 tokenId, uint256 amount) public {
    vm.assume(to != ZERO_ADDRESS);
    vm.assume(amount > 0);

    vm.expectEmit(address(facet));
    emit Transfer(address(this), ZERO_ADDRESS, to, tokenId, amount);

    facet.mint(to, tokenId, amount);
    assertEq(facet.balanceOf(to, tokenId), amount);
    assertEq(facet.totalSupply(tokenId), amount);
  }

  function test_mint_multipleTokens(
    address to,
    uint256 tokenId1,
    uint256 tokenId2,
    uint256 amount1,
    uint256 amount2
  ) public {
    vm.assume(to != ZERO_ADDRESS);
    vm.assume(tokenId1 != tokenId2);
    vm.assume(amount1 > 0);
    vm.assume(amount2 > 0);

    facet.mint(to, tokenId1, amount1);
    facet.mint(to, tokenId2, amount2);

    assertEq(facet.balanceOf(to, tokenId1), amount1);
    assertEq(facet.balanceOf(to, tokenId2), amount2);
    assertEq(facet.totalSupply(tokenId1), amount1);
    assertEq(facet.totalSupply(tokenId2), amount2);
  }

  // Test for balance overflow is difficult to test in practice due to uint256 limits
  // But we can test the zero amount edge cases
  function test_zeroAmountOperations(
    address user,
    address recipient,
    uint256 tokenId
  ) public {
    vm.assume(user != ZERO_ADDRESS);
    vm.assume(recipient != ZERO_ADDRESS);

    // Mint zero tokens
    facet.mint(user, tokenId, 0);
    assertEq(facet.balanceOf(user, tokenId), 0);
    assertEq(facet.totalSupply(tokenId), 0);

    // Burn zero tokens
    facet.burn(user, tokenId, 0);
    assertEq(facet.balanceOf(user, tokenId), 0);
    assertEq(facet.totalSupply(tokenId), 0);

    // Transfer zero tokens
    vm.prank(user);
    facet.transfer(recipient, tokenId, 0);
    assertEq(facet.balanceOf(user, tokenId), 0);
    assertEq(facet.balanceOf(recipient, tokenId), 0);

    // TransferFrom zero tokens
    vm.prank(user);
    facet.approve(recipient, tokenId, 0);
    vm.prank(recipient);
    facet.transferFrom(user, recipient, tokenId, 0);
    assertEq(facet.balanceOf(user, tokenId), 0);
    assertEq(facet.balanceOf(recipient, tokenId), 0);
  }
}
