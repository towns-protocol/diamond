// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IDiamond} from "src/Diamond.sol";
import {IDiamondCutBase} from "src/facets/cut/IDiamondCut.sol";
import {IDiamondCut, IDiamondCutBase} from "src/facets/cut/IDiamondCut.sol";
import {IERC173} from "src/facets/ownable/IERC173.sol";
import {IOwnableBase} from "src/facets/ownable/IERC173.sol";
import {IManagedProxy} from "src/proxy/managed/IManagedProxy.sol";
import {IMockFacet} from "test/mocks/MockFacet.sol";

// libraries

// contracts
import {DeployFacet} from "../../scripts/common/DeployFacet.s.sol";
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployManagedProxy} from "scripts/deployments/facets/DeployManagedProxy.s.sol";
import {DeployOwnable} from "scripts/deployments/facets/DeployOwnable.s.sol";
import {DeployProxyManager} from "scripts/deployments/utils/DeployProxyManager.s.sol";
import {ProxyManager} from "src/proxy/manager/ProxyManager.sol";
import {DeployMockFacet, MockFacet} from "test/mocks/MockFacet.sol";

// mocks
import {MockProxyInstance} from "test/mocks/MockProxyInstance.sol";

/// @title ProxyManager Test
/// @notice Tests for the ProxyManager contract which manages proxy-implementation relationships
/// @dev The ProxyManager acts as a central registry and controller for proxy contracts and their
/// corresponding implementations. It enables:
/// - Standardized proxy-implementation relationships through a common interface
/// - Controlled upgrades of implementations
/// - Consistent implementation fetching for managed proxies
/// The test suite verifies the manager can properly:
/// - Store and retrieve implementation addresses
/// - Handle proxy instance registration
/// - Control access to implementation updates
/// - Maintain proper proxy-implementation relationships
contract ProxyManagerTest is TestUtils, IDiamondCutBase, IOwnableBase {
    DeployMockFacet mockFacetHelper = new DeployMockFacet();
    DeployFacet private facetHelper = new DeployFacet();

    address manager;
    address implementation;
    address deployer;
    address instanceOwner;

    MockProxyInstance instance;

    function setUp() public {
        deployer = getDeployer();

        // create a diamond with a managed proxy facet - this is the implementation
        DeployDiamond implementationDiamond = new DeployDiamond();
        address managedProxy = facetHelper.deploy("ManagedProxyFacet", deployer);
        address ownableFacet = facetHelper.deploy("OwnableFacet", deployer);
        implementationDiamond.addCut(
            DeployOwnable.makeCut(ownableFacet, IDiamond.FacetCutAction.Add)
        );
        implementationDiamond.addFacet(
            DeployManagedProxy.makeCut(managedProxy, IDiamond.FacetCutAction.Add),
            managedProxy,
            DeployManagedProxy.makeInitData()
        );
        implementation = implementationDiamond.deploy(deployer);

        // create a diamond with a proxy manager facet, pointing to the implementation
        DeployDiamond managerDiamond = new DeployDiamond();
        address proxyManagerFacet = facetHelper.deploy("ProxyManager", deployer);
        managerDiamond.addFacet(
            DeployProxyManager.makeCut(proxyManagerFacet, IDiamond.FacetCutAction.Add),
            proxyManagerFacet,
            DeployProxyManager.makeInitData(implementation)
        );
        manager = managerDiamond.deploy(deployer);

        instanceOwner = makeAddr("instanceOwner");

        // create an ownable managed proxy instance
        vm.prank(instanceOwner);
        instance = new MockProxyInstance(ProxyManager.getImplementation.selector, manager);

        // The order of calls is:
        // Client -> Instance -> ProxyManager -> Implementation
    }

    // =============================================================
    //                          Proxy Manager
    // =============================================================

    function test_setImplementation() external {
        DeployDiamond implementationDiamond = new DeployDiamond();
        address managedProxy = facetHelper.deploy("ManagedProxyFacet", deployer);
        address ownableFacet = facetHelper.deploy("OwnableFacet", deployer);
        implementationDiamond.addCut(
            DeployOwnable.makeCut(ownableFacet, IDiamond.FacetCutAction.Add)
        );
        implementationDiamond.addFacet(
            DeployManagedProxy.makeCut(managedProxy, IDiamond.FacetCutAction.Add),
            managedProxy,
            DeployManagedProxy.makeInitData()
        );
        address newImplementation = implementationDiamond.deploy(deployer);

        bytes4 selector = ProxyManager.getImplementation.selector;
        ProxyManager proxyManager = ProxyManager(manager);

        assertNotEq(proxyManager.getImplementation(selector), newImplementation);

        vm.prank(deployer);
        proxyManager.setImplementation(newImplementation);

        assertEq(proxyManager.getImplementation(selector), newImplementation);
    }

    // =============================================================
    //                          Instance
    // =============================================================

    /// @notice This test checks that the owner of the instance is different from the owner of the implementation
    /// @dev This is to ensure that the instance is not the owner of the implementation
    function test_instanceAndImplementationOwners() external view {
        assertEq(IERC173(address(implementation)).owner(), deployer);
        assertEq(IERC173(address(instance)).owner(), instanceOwner);
    }

    /// @notice This test checks that implementation and instance storage is separate
    function test_localStorage() external {
        assertTrue(IERC165(address(implementation)).supportsInterface(type(IERC165).interfaceId));

        assertFalse(IERC165(address(instance)).supportsInterface(type(IERC165).interfaceId));

        vm.prank(instanceOwner);
        instance.local_addInterface(type(IERC165).interfaceId);

        assertTrue(IERC165(address(instance)).supportsInterface(type(IERC165).interfaceId));
    }

    /// @notice This test adds a new facet to our main implementation, which means our instance should now have access to it as well
    function test_instanceHasImplementationGlobalFacet() external {
        address mockFacet = mockFacetHelper.deploy();

        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = mockFacetHelper.makeCut(mockFacet, IDiamond.FacetCutAction.Add);

        vm.prank(deployer);
        IDiamondCut(address(implementation)).diamondCut(extensions, address(0), "");

        assertEq(IMockFacet(address(instance)).mockFunction(), 42);
    }

    /// @notice This test reverts when the implementation owner calls diamondCut on the implementation
    function test_revertWhen_diamondCutByWrongOwner() external {
        address mockFacet = mockFacetHelper.deploy();

        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = mockFacetHelper.makeCut(mockFacet, IDiamond.FacetCutAction.Add);

        vm.prank(instanceOwner);
        vm.expectRevert();
        IDiamondCut(address(implementation)).diamondCut(extensions, address(0), "");

        vm.prank(deployer);
        vm.expectRevert();
        IDiamondCut(address(instance)).diamondCut(extensions, address(0), "");
    }

    /// @notice This test adds a local facet to our instance, which means our implementation should not have access to it
    function test_instanceContainsLocalFacet() external {
        // add some facets to diamond
        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = mockFacetHelper.makeCut(
            mockFacetHelper.deploy(instanceOwner), IDiamond.FacetCutAction.Add
        );

        vm.prank(instanceOwner);
        IDiamondCut(address(instance)).diamondCut(extensions, address(0), "");

        // assert facet function is callable from managedProxy
        IMockFacet(address(instance)).mockFunction();

        // assert facet function is not callable from implementation
        vm.expectRevert();
        IMockFacet(address(implementation)).mockFunction();
    }

    /// @notice This test changes the manager of the instance and ensures that the instance is now pointing to the new manager
    function test_changeInstanceManager() external {
        address currentManager = IManagedProxy(address(instance)).getManager();
        assertEq(currentManager, address(manager));

        // Create a new manager
        address newManager = _randomAddress();

        // We're opting out of using the manager
        vm.prank(instanceOwner);
        IManagedProxy(address(instance)).setManager(newManager);
    }

    function test_upgradePath() external {
        address mockFacet = mockFacetHelper.deploy();

        // add mock facet to implementation
        IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
        extensions[0] = mockFacetHelper.makeCut(mockFacet, IDiamond.FacetCutAction.Add);

        vm.prank(deployer);
        IDiamondCut(address(implementation)).diamondCut(
            extensions, mockFacet, abi.encodeWithSelector(MockFacet.__MockFacet_init.selector, 42)
        );

        vm.prank(instanceOwner);
        IMockFacet(address(instance)).upgrade();

        // assert facet function is callable from managedProxy
        assertEq(IMockFacet(address(instance)).getValue(), 100);
    }
}
