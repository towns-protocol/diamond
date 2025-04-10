// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// utils
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployTokenOwnable} from "scripts/deployments/facets/DeployTokenOwnable.s.sol";
import {DeployTokenPausable} from "scripts/deployments/facets/DeployTokenPausable.s.sol";
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IDiamond} from "src/Diamond.sol";
import {ITokenOwnableBase} from "src/facets/ownable/token/ITokenOwnable.sol";
import {IPausableBase} from "src/facets/pausable/IPausable.sol";

// libraries

// contracts
import {TokenPausableFacet} from "src/facets/pausable/token/TokenPausableFacet.sol";

// mocks
import {MockToken} from "test/mocks/MockToken.sol";

contract TokenPausableTest is TestUtils, ITokenOwnableBase, IPausableBase {
    DeployDiamond diamondHelper = new DeployDiamond();

    address diamond;
    address deployer;
    address owner;

    MockToken mockToken;
    TokenPausableFacet tokenPausable;

    uint256 tokenId;

    function setUp() public {
        deployer = getDeployer();
        owner = makeAddr("owner");

        mockToken = new MockToken();
        tokenId = mockToken.mintTo(owner);

        vm.startPrank(deployer);
        address tokenOwnableFacet = DeployTokenOwnable.deploy();
        address tokenPausableFacet = DeployTokenPausable.deploy();
        vm.stopPrank();

        diamondHelper.addFacet(
            DeployTokenOwnable.makeCut(tokenOwnableFacet, IDiamond.FacetCutAction.Add),
            tokenOwnableFacet,
            DeployTokenOwnable.makeInitData(TokenOwnable(address(mockToken), tokenId))
        );

        diamondHelper.addFacet(
            DeployTokenPausable.makeCut(tokenPausableFacet, IDiamond.FacetCutAction.Add),
            tokenPausableFacet,
            DeployTokenPausable.makeInitData()
        );

        diamond = diamondHelper.deploy(deployer);
        tokenPausable = TokenPausableFacet(diamond);
    }

    function test_pause() external {
        assertFalse(tokenPausable.paused());

        vm.prank(owner);
        tokenPausable.pause();

        assertTrue(tokenPausable.paused());
    }

    function test_unpause() external {
        vm.prank(owner);
        tokenPausable.pause();

        assertTrue(tokenPausable.paused());

        vm.prank(owner);
        tokenPausable.unpause();

        assertFalse(tokenPausable.paused());
    }

    function test_paused() external {
        assertFalse(tokenPausable.paused());

        vm.prank(owner);
        tokenPausable.pause();

        assertTrue(tokenPausable.paused());

        vm.prank(owner);
        tokenPausable.unpause();

        assertFalse(tokenPausable.paused());
    }
}
