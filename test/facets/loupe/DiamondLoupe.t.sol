// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IDiamond} from "src/Diamond.sol";
import {IDiamondCut} from "src/facets/cut/IDiamondCut.sol";
import {IDiamondLoupe, IDiamondLoupeBase} from "src/facets/loupe/IDiamondLoupe.sol";

//libraries

//contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployMockFacet, MockFacet} from "test/mocks/MockFacet.sol";

contract DiamondLoupeTest is TestUtils, IDiamondLoupeBase {
    DeployDiamond diamondHelper = new DeployDiamond();

    address diamond;
    address deployer;
    IDiamondLoupe diamondLoupe;
    IDiamondCut diamondCut;

    function setUp() public {
        deployer = getDeployer();
        diamond = diamondHelper.deploy(deployer);
        diamondLoupe = IDiamondLoupe(diamond);
        diamondCut = IDiamondCut(diamond);
    }

    function test_supportsInterface() external view {
        assertTrue(IERC165(diamond).supportsInterface(type(IDiamondLoupe).interfaceId));
    }

    function test_facets() external {
        address mockFacet = DeployMockFacet.deploy();
        bytes4[] memory expectedSelectors = DeployMockFacet.selectors();
        IDiamondLoupe.Facet[] memory currentFacets = diamondLoupe.facets();

        // create facet cuts
        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = IDiamond.FacetCut({
            facetAddress: mockFacet,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: expectedSelectors
        });

        // cut diamond
        vm.prank(deployer);
        diamondCut.diamondCut(extensions, address(0), "");

        // get facets
        IDiamondLoupe.Facet[] memory facets = diamondLoupe.facets();

        // assert facets length is correct
        assertEq(facets.length, currentFacets.length + 1);
    }

    function test_facetFunctionSelectors() external {
        address mockFacet = DeployMockFacet.deploy();
        bytes4[] memory expectedSelectors = DeployMockFacet.selectors();

        // create facet cuts
        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = IDiamond.FacetCut({
            facetAddress: mockFacet,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: expectedSelectors
        });

        // cut diamond
        vm.prank(deployer);
        diamondCut.diamondCut(extensions, address(0), "");

        // get facet selectors
        bytes4[] memory selectors = diamondLoupe.facetFunctionSelectors(mockFacet);

        // assert selectors length is correct
        assertEq(selectors.length, expectedSelectors.length);

        // loop through selectors
        for (uint256 i; i < selectors.length; i++) {
            // assert selector is correct
            assertEq(selectors[i], expectedSelectors[i]);
        }
    }

    function test_facetAddresses() external {
        address mockFacet = DeployMockFacet.deploy();
        bytes4[] memory expectedSelectors = DeployMockFacet.selectors();
        address[] memory currentFacetAddresses = diamondLoupe.facetAddresses();

        // create facet cuts
        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = IDiamond.FacetCut({
            facetAddress: mockFacet,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: expectedSelectors
        });

        // cut diamond
        vm.prank(deployer);
        diamondCut.diamondCut(extensions, address(0), "");

        // get facet addresses
        address[] memory facetAddresses = diamondLoupe.facetAddresses();

        // assert facet addresses length is correct
        assertEq(facetAddresses.length, currentFacetAddresses.length + 1);

        // assert facet address is correct
        assertEq(facetAddresses[facetAddresses.length - 1], mockFacet);
    }

    function test_facetAddress() external {
        address mockFacet = DeployMockFacet.deploy();
        bytes4[] memory expectedSelectors = DeployMockFacet.selectors();

        // create facet cuts
        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = IDiamond.FacetCut({
            facetAddress: mockFacet,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: expectedSelectors
        });

        // cut diamond
        vm.prank(deployer);
        diamondCut.diamondCut(extensions, address(0), "");

        // loop through mock facet selectors
        for (uint256 i; i < expectedSelectors.length; i++) {
            // assert facet address is correct
            assertEq(diamondLoupe.facetAddress(expectedSelectors[i]), mockFacet);
        }
    }

    function test_facetAddressRemove() external {
        address mockFacet = DeployMockFacet.deploy();
        bytes4[] memory expectedSelectors = DeployMockFacet.selectors();

        // create facet cuts
        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = IDiamond.FacetCut({
            facetAddress: mockFacet,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: expectedSelectors
        });

        // cut diamond
        vm.prank(deployer);
        diamondCut.diamondCut(extensions, address(0), "");

        // remove facet cuts
        extensions[0] = IDiamond.FacetCut({
            facetAddress: mockFacet,
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: expectedSelectors
        });

        // cut diamond
        vm.prank(deployer);
        diamondCut.diamondCut(extensions, address(0), "");

        // loop through mock facet selectors
        for (uint256 i; i < expectedSelectors.length; i++) {
            // assert facet address is correct
            assertEq(diamondLoupe.facetAddress(expectedSelectors[i]), address(0));
        }
    }

    function test_facetAddressReplace() external {
        address mockFacet = DeployMockFacet.deploy();
        bytes4[] memory expectedSelectors = DeployMockFacet.selectors();

        // create facet cuts
        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = IDiamond.FacetCut({
            facetAddress: mockFacet,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: expectedSelectors
        });

        // cut diamond
        vm.prank(deployer);
        diamondCut.diamondCut(extensions, address(0), "");

        address expectedFacetAddress = address(new MockFacet());

        // create facet cuts
        extensions[0] = IDiamond.FacetCut({
            facetAddress: expectedFacetAddress,
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: expectedSelectors
        });

        // cut diamond
        vm.prank(deployer);
        diamondCut.diamondCut(extensions, address(0), "");

        // loop through mock facet selectors
        for (uint256 i; i < expectedSelectors.length; i++) {
            // assert facet address is correct
            assertEq(diamondLoupe.facetAddress(expectedSelectors[i]), expectedFacetAddress);
        }
    }
}
