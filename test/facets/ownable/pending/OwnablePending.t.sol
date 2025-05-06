// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IDiamond} from "src/Diamond.sol";
import {IOwnableBase} from "src/facets/ownable/IERC173.sol";

// libraries

// contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployOwnablePending} from "scripts/deployments/facets/DeployOwnablePending.sol";
import {OwnablePendingFacet} from "src/facets/ownable/pending/OwnablePendingFacet.sol";

contract OwnablePendingTest is TestUtils, IOwnableBase {
    DeployDiamond diamondHelper = new DeployDiamond();

    address diamond;
    address deployer;
    address owner;

    OwnablePendingFacet ownable;

    function setUp() public {
        deployer = getDeployer();

        vm.prank(deployer);
        address ownablePending = DeployOwnablePending.deploy();

        diamondHelper.addCut(
            DeployOwnablePending.makeCut(ownablePending, IDiamond.FacetCutAction.Add)
        );

        diamond = diamondHelper.deploy(deployer);
        ownable = OwnablePendingFacet(diamond);
    }

    function test_currentOwner() external view {
        assertEq(ownable.currentOwner(), deployer);
    }

    function test_transferOwnership() external {
        address newOwner = _randomAddress();

        vm.prank(deployer);
        ownable.startTransferOwnership(newOwner);

        assertEq(ownable.pendingOwner(), newOwner);
        assertEq(ownable.currentOwner(), deployer);
    }

    function test_acceptOwnership() external {
        address newOwner = _randomAddress();

        vm.prank(deployer);
        ownable.startTransferOwnership(newOwner);

        vm.prank(newOwner);
        ownable.acceptOwnership();

        assertEq(ownable.pendingOwner(), address(0));
        assertEq(ownable.currentOwner(), newOwner);
    }
}
