// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IIntrospectionBase} from "src/facets/introspection/IIntrospectionBase.sol";
// libraries

// contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";

contract IntrospectionTest is TestUtils, IIntrospectionBase {
    DeployDiamond diamondHelper = new DeployDiamond();

    address diamond;
    address deployer;
    IERC165 introspection;

    function setUp() public {
        deployer = getDeployer();
        diamond = diamondHelper.deploy(deployer);
        introspection = IERC165(diamond);
    }

    function test_supportsInterface() external view {
        assertTrue(introspection.supportsInterface(type(IERC165).interfaceId));
    }
}
