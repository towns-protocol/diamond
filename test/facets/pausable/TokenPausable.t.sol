// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

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
    DeployTokenOwnable tokenOwnableHelper = new DeployTokenOwnable();
    DeployTokenPausable tokenPausableHelper = new DeployTokenPausable();

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

        address tokenOwnableFacet = tokenOwnableHelper.deploy(deployer);
        address tokenPausableFacet = tokenPausableHelper.deploy(deployer);

        diamondHelper.addFacet(
            tokenOwnableHelper.makeCut(tokenOwnableFacet, IDiamond.FacetCutAction.Add),
            tokenOwnableFacet,
            tokenOwnableHelper.makeInitData(TokenOwnable(address(mockToken), tokenId))
        );

        diamondHelper.addFacet(
            tokenPausableHelper.makeCut(tokenPausableFacet, IDiamond.FacetCutAction.Add),
            tokenPausableFacet,
            tokenPausableHelper.makeInitData("")
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
