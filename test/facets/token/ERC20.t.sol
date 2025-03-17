// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20PermitBase} from "src/facets/token/ERC20/permit/IERC20PermitBase.sol";

// libraries
import {stdError} from "forge-std/StdError.sol";
import {LibClone} from "solady/utils/LibClone.sol";

// contracts
import {MockERC20} from "../../mocks/MockERC20.sol";
import {SoladyTest} from "../../utils/SoladyTest.sol";

contract ERC20Test is SoladyTest, IERC20PermitBase, IERC20Errors {
  MockERC20 internal token;

  bytes32 internal constant PERMIT_TYPEHASH =
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  struct _TestTemps {
    address owner;
    address to;
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 privateKey;
    uint256 nonce;
  }

  function _testTemps() internal returns (_TestTemps memory t) {
    (t.owner, t.privateKey) = _randomSigner();
    t.to = _randomNonZeroAddress();
    t.amount = _random();
    t.deadline = _random();
  }

  function setUp() public {
    token = MockERC20(LibClone.deployERC1967(address(new MockERC20())));
    token.initialize("Token", "TKN", 18);
  }

  function testMetadata() public view {
    assertEq(token.name(), "Token");
    assertEq(token.symbol(), "TKN");
    assertEq(token.decimals(), 18);
  }

  function testMint() public {
    vm.expectEmit(true, true, true, true);
    emit Transfer(address(0), address(0xBEEF), 1e18);
    token.mint(address(0xBEEF), 1e18);

    assertEq(token.totalSupply(), 1e18);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testBurn() public {
    token.mint(address(0xBEEF), 1e18);

    vm.expectEmit(true, true, true, true);
    emit Transfer(address(0xBEEF), address(0), 0.9e18);
    token.burn(address(0xBEEF), 0.9e18);

    assertEq(token.totalSupply(), 1e18 - 0.9e18);
    assertEq(token.balanceOf(address(0xBEEF)), 0.1e18);
  }

  function testApprove() public {
    vm.expectEmit(true, true, true, true);
    emit Approval(address(this), address(0xBEEF), 1e18);
    assertTrue(token.approve(_brutalized(address(0xBEEF)), 1e18));

    assertEq(token.allowance(address(this), address(0xBEEF)), 1e18);
  }

  function testTransfer() public {
    token.mint(_brutalized(address(this)), 1e18);

    vm.expectEmit(true, true, true, true);
    emit Transfer(address(this), address(0xBEEF), 1e18);
    assertTrue(token.transfer(address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.balanceOf(address(this)), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testTransferFrom() public {
    address from = address(0xABCD);

    token.mint(from, 1e18);

    vm.prank(from);
    token.approve(address(this), 1e18);

    vm.expectEmit(true, true, true, true);
    emit Transfer(from, address(0xBEEF), 1e18);
    assertTrue(token.transferFrom(_brutalized(from), address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.allowance(from, address(this)), 0);

    assertEq(token.balanceOf(from), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testInfiniteApproveTransferFrom() public {
    address from = address(0xABCD);

    token.mint(from, 1e18);

    vm.prank(from);
    token.approve(address(this), type(uint256).max);

    assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
    assertEq(token.totalSupply(), 1e18);

    assertEq(token.allowance(from, address(this)), type(uint256).max);

    assertEq(token.balanceOf(from), 0);
    assertEq(token.balanceOf(address(0xBEEF)), 1e18);
  }

  function testPermit() public {
    _TestTemps memory t = _testTemps();
    t.deadline = block.timestamp;

    _signPermit(t);

    _expectPermitEmitApproval(t);
    _permit(t);

    _checkAllowanceAndNonce(t);
  }

  function testMintOverMaxUintReverts() public {
    token.mint(address(this), type(uint256).max);
    vm.expectRevert(stdError.arithmeticError);
    token.mint(address(this), 1);
  }

  function testTransferInsufficientBalanceReverts() public {
    token.mint(address(this), 0.9e18);
    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20InsufficientBalance.selector,
        address(this),
        0.9e18,
        1e18
      )
    );
    token.transfer(address(0xBEEF), 1e18);
  }

  function testTransferFromInsufficientAllowanceReverts() public {
    address from = address(0xABCD);

    token.mint(from, 1e18);

    vm.prank(from);
    token.approve(address(this), 0.9e18);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20InsufficientAllowance.selector,
        address(this),
        0.9e18,
        1e18
      )
    );
    token.transferFrom(from, address(0xBEEF), 1e18);
  }

  function testTransferFromInsufficientBalanceReverts() public {
    address from = address(0xABCD);

    token.mint(from, 0.9e18);

    vm.prank(from);
    token.approve(address(this), 1e18);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20InsufficientBalance.selector,
        from,
        0.9e18,
        1e18
      )
    );
    token.transferFrom(from, address(0xBEEF), 1e18);
  }

  function testMint(address to, uint256 amount) public {
    vm.assume(to != address(0));
    vm.expectEmit(true, true, true, true);
    emit Transfer(address(0), to, amount);
    token.mint(to, amount);

    assertEq(token.totalSupply(), amount);
    assertEq(token.balanceOf(to), amount);
  }

  function testBurn(
    address from,
    uint256 mintAmount,
    uint256 burnAmount
  ) public {
    vm.assume(from != address(0));
    burnAmount = _bound(burnAmount, 0, mintAmount);

    token.mint(from, mintAmount);
    vm.expectEmit(true, true, true, true);
    emit Transfer(from, address(0), burnAmount);
    token.burn(from, burnAmount);

    assertEq(token.totalSupply(), mintAmount - burnAmount);
    assertEq(token.balanceOf(from), mintAmount - burnAmount);
  }

  function testApprove(address to, uint256 amount) public {
    assertTrue(token.approve(to, amount));

    assertEq(token.allowance(address(this), to), amount);
  }

  function testTransfer(address to, uint256 amount) public {
    token.mint(address(this), amount);

    vm.expectEmit(true, true, true, true);
    emit Transfer(address(this), to, amount);
    assertTrue(token.transfer(to, amount));
    assertEq(token.totalSupply(), amount);

    if (address(this) == to) {
      assertEq(token.balanceOf(address(this)), amount);
    } else {
      assertEq(token.balanceOf(address(this)), 0);
      assertEq(token.balanceOf(to), amount);
    }
  }

  function testTransferFrom(
    address spender,
    address from,
    address to,
    uint256 approval,
    uint256 amount
  ) public {
    vm.assume(from != address(0));
    amount = _bound(amount, 0, approval);

    token.mint(from, amount);
    assertEq(token.balanceOf(from), amount);

    vm.prank(from);
    token.approve(spender, approval);

    vm.expectEmit(true, true, true, true);
    emit Transfer(from, to, amount);
    vm.prank(spender);
    assertTrue(token.transferFrom(from, to, amount));
    assertEq(token.totalSupply(), amount);

    if (approval == type(uint256).max) {
      assertEq(token.allowance(from, spender), approval);
    } else {
      assertEq(token.allowance(from, spender), approval - amount);
    }

    if (from == to) {
      assertEq(token.balanceOf(from), amount);
    } else {
      assertEq(token.balanceOf(from), 0);
      assertEq(token.balanceOf(to), amount);
    }
  }

  function testDirectTransfer(uint256) public {
    _TestTemps memory t = _testTemps();
    while (t.owner == t.to) (t.to, ) = _randomSigner();

    uint256 totalSupply = _random();
    token.mint(t.owner, totalSupply);
    assertEq(token.balanceOf(t.owner), totalSupply);
    assertEq(token.balanceOf(t.to), 0);
    if (t.amount > totalSupply) {
      vm.expectRevert(
        abi.encodeWithSelector(
          ERC20InsufficientBalance.selector,
          t.owner,
          totalSupply,
          t.amount
        )
      );
      token.directTransfer(t.owner, t.to, t.amount);
    } else {
      vm.expectEmit(true, true, true, true);
      emit Transfer(t.owner, t.to, t.amount);
      token.directTransfer(t.owner, t.to, t.amount);
      assertEq(token.balanceOf(t.owner), totalSupply - t.amount);
      assertEq(token.balanceOf(t.to), t.amount);
    }
  }

  function testDirectSpendAllowance(uint256) public {
    _TestTemps memory t = _testTemps();
    uint256 allowance = _random();
    vm.prank(t.owner);
    token.approve(t.to, allowance);
    assertEq(token.allowance(t.owner, t.to), allowance);
    if (allowance == type(uint256).max) {
      token.directSpendAllowance(t.owner, t.to, t.amount);
      assertEq(token.allowance(t.owner, t.to), allowance);
    } else if (t.amount > allowance) {
      vm.expectRevert(
        abi.encodeWithSelector(
          ERC20InsufficientAllowance.selector,
          t.to,
          allowance,
          t.amount
        )
      );
      token.directSpendAllowance(t.owner, t.to, t.amount);
    } else {
      token.directSpendAllowance(t.owner, t.to, t.amount);
      assertEq(token.allowance(t.owner, t.to), allowance - t.amount);
    }
  }

  function testPermit(uint256) public {
    _TestTemps memory t = _testTemps();
    if (t.deadline < block.timestamp) t.deadline = block.timestamp;

    _signPermit(t);

    _expectPermitEmitApproval(t);
    _permit(t);

    _checkAllowanceAndNonce(t);
  }

  function _checkAllowanceAndNonce(_TestTemps memory t) internal view {
    assertEq(token.allowance(t.owner, t.to), t.amount);
    assertEq(token.nonces(t.owner), t.nonce + 1);
  }

  function testBurnInsufficientBalanceReverts(
    address to,
    uint256 mintAmount,
    uint256 burnAmount
  ) public {
    vm.assume(to != address(0));
    if (mintAmount == type(uint256).max) mintAmount--;
    burnAmount = _bound(burnAmount, mintAmount + 1, type(uint256).max);

    token.mint(to, mintAmount);
    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20InsufficientBalance.selector,
        to,
        mintAmount,
        burnAmount
      )
    );
    token.burn(to, burnAmount);
  }

  function testTransferInsufficientBalanceReverts(
    address to,
    uint256 mintAmount,
    uint256 sendAmount
  ) public {
    if (mintAmount == type(uint256).max) mintAmount--;
    sendAmount = _bound(sendAmount, mintAmount + 1, type(uint256).max);

    token.mint(address(this), mintAmount);
    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20InsufficientBalance.selector,
        address(this),
        mintAmount,
        sendAmount
      )
    );
    token.transfer(to, sendAmount);
  }

  function testTransferFromInsufficientAllowanceReverts(
    address to,
    uint256 approval,
    uint256 amount
  ) public {
    if (approval == type(uint256).max) approval--;
    amount = _bound(amount, approval + 1, type(uint256).max);

    address from = address(0xABCD);

    token.mint(from, amount);

    vm.prank(from);
    token.approve(address(this), approval);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20InsufficientAllowance.selector,
        address(this),
        approval,
        amount
      )
    );
    token.transferFrom(from, to, amount);
  }

  function testTransferFromInsufficientBalanceReverts(
    address to,
    uint256 mintAmount,
    uint256 sendAmount
  ) public {
    if (mintAmount == type(uint256).max) mintAmount--;
    sendAmount = _bound(sendAmount, mintAmount + 1, type(uint256).max);

    address from = address(0xABCD);

    token.mint(from, mintAmount);

    vm.prank(from);
    token.approve(address(this), sendAmount);

    vm.expectRevert(
      abi.encodeWithSelector(
        ERC20InsufficientBalance.selector,
        from,
        mintAmount,
        sendAmount
      )
    );
    token.transferFrom(from, to, sendAmount);
  }

  function testPermitBadNonceReverts(uint256) public {
    _TestTemps memory t = _testTemps();
    if (t.deadline < block.timestamp) t.deadline = block.timestamp;
    while (t.nonce == 0) t.nonce = _random();

    _signPermit(t);

    vm.expectRevert();
    _permit(t);
  }

  function testPermitBadDeadlineReverts(uint256) public {
    _TestTemps memory t = _testTemps();
    if (t.deadline == type(uint256).max) t.deadline--;
    if (t.deadline < block.timestamp) t.deadline = block.timestamp;

    _signPermit(t);

    vm.expectRevert();
    t.deadline += 1;
    _permit(t);
  }

  function testPermitPastDeadlineReverts(uint256) public {
    _TestTemps memory t = _testTemps();
    t.deadline = _bound(t.deadline, 0, block.timestamp - 1);

    _signPermit(t);

    vm.expectRevert(
      abi.encodeWithSelector(ERC2612ExpiredSignature.selector, t.deadline)
    );
    _permit(t);
  }

  function testPermitReplayReverts(uint256) public {
    _TestTemps memory t = _testTemps();
    if (t.deadline < block.timestamp) t.deadline = block.timestamp;

    _signPermit(t);

    _expectPermitEmitApproval(t);
    _permit(t);
    vm.expectRevert();
    _permit(t);
  }

  function _signPermit(_TestTemps memory t) internal view {
    bytes32 innerHash = keccak256(
      abi.encode(PERMIT_TYPEHASH, t.owner, t.to, t.amount, t.nonce, t.deadline)
    );
    bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
    bytes32 outerHash = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, innerHash)
    );
    (t.v, t.r, t.s) = vm.sign(t.privateKey, outerHash);
  }

  function _expectPermitEmitApproval(_TestTemps memory t) internal {
    vm.expectEmit(true, true, true, true);
    emit Approval(t.owner, t.to, t.amount);
  }

  function _permit(_TestTemps memory t) internal {
    token.permit(t.owner, t.to, t.amount, t.deadline, t.v, t.r, t.s);
  }
}
