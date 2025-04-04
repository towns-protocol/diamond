// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// utils
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployPausable} from "scripts/deployments/facets/DeployPausable.s.sol";
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IDiamond} from "src/Diamond.sol";
import {IPausableBase} from "src/facets/pausable/IPausable.sol";

// libraries

// contracts
import {PausableFacet} from "src/facets/pausable/PausableFacet.sol";

contract PausableTest is TestUtils, IPausableBase {
    DeployDiamond diamondHelper = new DeployDiamond();
    DeployPausable pausableHelper = new DeployPausable();

    address diamond;
    address deployer;

    PausableFacet pausable;

    function setUp() public {
        deployer = getDeployer();
        address pausableFacet = pausableHelper.deploy(deployer);

        diamondHelper.addFacet(
            pausableHelper.makeCut(pausableFacet, IDiamond.FacetCutAction.Add),
            pausableFacet,
            pausableHelper.makeInitData("")
        );

        diamond = diamondHelper.deploy(deployer);
        pausable = PausableFacet(diamond);
    }

    function test_pause() external {
        assertFalse(pausable.paused());

        vm.prank(deployer);
        pausable.pause();

        assertTrue(pausable.paused());
    }

    function test_unpause() external {
        vm.prank(deployer);
        pausable.pause();

        assertTrue(pausable.paused());

        vm.prank(deployer);
        pausable.unpause();

        assertFalse(pausable.paused());
    }

    function test_paused() external {
        assertFalse(pausable.paused());

        vm.prank(deployer);
        pausable.pause();

        assertTrue(pausable.paused());

        vm.prank(deployer);
        pausable.unpause();

        assertFalse(pausable.paused());
    }
}
