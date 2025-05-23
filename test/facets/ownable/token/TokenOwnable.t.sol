// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IDiamond} from "src/Diamond.sol";
import {ITokenOwnableBase} from "src/facets/ownable/token/ITokenOwnable.sol";

// libraries

// contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployTokenOwnable} from "scripts/deployments/facets/DeployTokenOwnable.sol";
import {TokenOwnableFacet} from "src/facets/ownable/token/TokenOwnableFacet.sol";

// mocks
import {MockToken} from "test/mocks/MockToken.sol";

contract TokenOwnableTest is TestUtils, ITokenOwnableBase {
    DeployDiamond diamondHelper = new DeployDiamond();

    address diamond;
    address deployer;
    address owner;

    TokenOwnableFacet tokenOwnable;
    MockToken mockToken;
    uint256 tokenId;

    function setUp() public {
        deployer = getDeployer();
        owner = makeAddr("owner");

        address tokenOwnableFacet = DeployTokenOwnable.deploy();

        mockToken = new MockToken();
        tokenId = mockToken.mintTo(owner);

        diamondHelper.addFacet(
            DeployTokenOwnable.makeCut(tokenOwnableFacet, IDiamond.FacetCutAction.Add),
            tokenOwnableFacet,
            DeployTokenOwnable.makeInitData(TokenOwnable(address(mockToken), tokenId))
        );

        diamond = diamondHelper.deploy(deployer);
        tokenOwnable = TokenOwnableFacet(diamond);
    }

    function test_owner() external view {
        assertEq(tokenOwnable.owner(), owner);
    }

    function test_transferOwnership() external {
        address newOwner = _randomAddress();

        vm.startPrank(owner);
        mockToken.approve(address(tokenOwnable), tokenId);
        tokenOwnable.transferOwnership(newOwner);
        vm.stopPrank();

        assertEq(tokenOwnable.owner(), newOwner);
    }
}
