// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC173} from "src/facets/ownable/IERC173.sol";
import {IDiamondCutBase} from "src/facets/cut/IDiamondCut.sol";
import {IDiamond} from "src/Diamond.sol";
import {IDiamondCut, IDiamondCutBase} from "src/facets/cut/IDiamondCut.sol";
import {IOwnableBase} from "src/facets/ownable/IERC173.sol";
import {IMockFacet} from "test/mocks/MockFacet.sol";
import {IManagedProxy} from "src/proxy/managed/IManagedProxy.sol";

// libraries

// contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployProxyManager} from "scripts/deployments/utils/DeployProxyManager.s.sol";
import {DeployMockFacet, MockFacet} from "test/mocks/MockFacet.sol";
import {DeployManagedProxy} from "scripts/deployments/facets/DeployManagedProxy.s.sol";
import {DeployOwnable} from "scripts/deployments/facets/DeployOwnable.s.sol";

import {ProxyManager} from "src/proxy/manager/ProxyManager.sol";

// mocks
import {MockProxyInstance} from "test/mocks/MockProxyInstance.sol";

contract ProxyManagerTest is TestUtils, IDiamondCutBase, IOwnableBase {
  DeployProxyManager proxyManagerHelper = new DeployProxyManager();
  DeployMockFacet mockFacetHelper = new DeployMockFacet();
  DeployManagedProxy managedProxyHelper = new DeployManagedProxy();
  DeployOwnable ownableFacetHelper = new DeployOwnable();

  address manager;
  address implementation;
  address deployer;
  address instanceOwner;

  MockProxyInstance instance;

  function setUp() public {
    deployer = getDeployer();

    // create a diamond with a managed proxy facet - this is the implementation
    DeployDiamond implementationHelper = new DeployDiamond();
    address managedProxy = managedProxyHelper.deploy(deployer);
    address ownableFacet = ownableFacetHelper.deploy(deployer);
    implementationHelper.addCut(
      ownableFacetHelper.makeCut(ownableFacet, IDiamond.FacetCutAction.Add)
    );
    implementationHelper.addFacet(
      managedProxyHelper.makeCut(managedProxy, IDiamond.FacetCutAction.Add),
      managedProxy,
      managedProxyHelper.makeInitData("")
    );
    implementation = implementationHelper.deploy(deployer);

    // create a diamond with a proxy manager facet, pointing to the implementation
    DeployDiamond managerDiamond = new DeployDiamond();
    address proxyManagerFacet = proxyManagerHelper.deploy(deployer);

    managerDiamond.addFacet(
      proxyManagerHelper.makeCut(
        proxyManagerFacet,
        IDiamond.FacetCutAction.Add
      ),
      proxyManagerFacet,
      proxyManagerHelper.makeInitData(implementation)
    );
    manager = managerDiamond.deploy(deployer);

    instanceOwner = makeAddr("instanceOwner");

    // create an ownable managed proxy instance
    vm.prank(instanceOwner);
    instance = new MockProxyInstance(
      ProxyManager.getImplementation.selector,
      manager
    );

    // The order of calls is:
    // Client -> Instance -> ProxyManager -> Implementation
  }

  // =============================================================
  //                          Instance
  // =============================================================

  /// @notice This test checks that the owner of the instance is different from the owner of the implementation
  /// @dev This is to ensure that the instance is not the owner of the implementation
  function test_proxyOwner() external view {
    assertEq(IERC173(address(implementation)).owner(), deployer);
    assertEq(IERC173(address(instance)).owner(), instanceOwner);
  }

  /// @notice This test checks that implementation and instance storage is separate
  function test_supportedInterfaces() external {
    assertTrue(
      IERC165(address(implementation)).supportsInterface(
        type(IERC165).interfaceId
      )
    );

    assertFalse(
      IERC165(address(instance)).supportsInterface(type(IERC165).interfaceId)
    );

    vm.prank(instanceOwner);
    instance.local_addInterface(type(IERC165).interfaceId);

    assertTrue(
      IERC165(address(instance)).supportsInterface(type(IERC165).interfaceId)
    );
  }

  /// @notice This test adds a new facet to our main implementation, which means our instance should now have access to it as well
  function test_instanceHasImplementationGlobalFacet() external {
    address mockFacet = mockFacetHelper.deploy();

    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = mockFacetHelper.makeCut(
      mockFacet,
      IDiamond.FacetCutAction.Add
    );

    vm.prank(deployer);
    IDiamondCut(address(implementation)).diamondCut(extensions, address(0), "");

    assertEq(IMockFacet(address(instance)).mockFunction(), 42);
  }

  /// @notice This test adds a local facet to our instance, which means our implementation should not have access to it
  function test_instanceContainsLocalFacet() external {
    // add some facets to diamond
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = mockFacetHelper.makeCut(
      mockFacetHelper.deploy(instanceOwner),
      IDiamond.FacetCutAction.Add
    );

    vm.prank(instanceOwner);
    IDiamondCut(address(instance)).diamondCut(extensions, address(0), "");

    // assert facet function is callable from managedProxy
    IMockFacet(address(instance)).mockFunction();

    // assert facet function is not callable from implementation
    vm.expectRevert();
    IMockFacet(address(implementation)).mockFunction();
  }

  function test_changeInstanceManager() external {
    address currentManager = IManagedProxy(address(instance)).getManager();
    assertEq(currentManager, address(manager));

    // Create a new manager
    address newManager = _randomAddress();

    // We're opting out of using the manager
    vm.prank(instanceOwner);
    IManagedProxy(address(instance)).setManager(newManager);

    // since we changed the manager, we should no longer be able to call functions from the old implementation
    // the old implementation has the getManager function in its facet
    vm.expectRevert();
    IManagedProxy(address(instance)).getManager();
  }

  // =============================================================
  //                          Proxy Manager
  // =============================================================

  function test_setImplementation() external {
    DeployDiamond implementationHelper = new DeployDiamond();
    address managedProxy = managedProxyHelper.deploy(deployer);
    address ownableFacet = ownableFacetHelper.deploy(deployer);
    implementationHelper.addCut(
      ownableFacetHelper.makeCut(ownableFacet, IDiamond.FacetCutAction.Add)
    );
    implementationHelper.addFacet(
      managedProxyHelper.makeCut(managedProxy, IDiamond.FacetCutAction.Add),
      managedProxy,
      managedProxyHelper.makeInitData("")
    );
    address newImplementation = implementationHelper.deploy(deployer);

    bytes4 selector = ProxyManager.getImplementation.selector;
    ProxyManager proxyManager = ProxyManager(manager);

    assertNotEq(proxyManager.getImplementation(selector), newImplementation);

    vm.prank(deployer);
    proxyManager.setImplementation(newImplementation);

    assertEq(proxyManager.getImplementation(selector), newImplementation);
  }

  function test_upgradePath() external {
    address mockFacet = mockFacetHelper.deploy();

    // add mock facet to implementation
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = mockFacetHelper.makeCut(
      mockFacet,
      IDiamond.FacetCutAction.Add
    );

    vm.prank(deployer);
    IDiamondCut(address(implementation)).diamondCut(
      extensions,
      mockFacet,
      abi.encodeWithSelector(MockFacet.__MockFacet_init.selector, 42)
    );

    vm.prank(instanceOwner);
    IMockFacet(address(instance)).upgrade();

    // assert facet function is callable from managedProxy
    assertEq(IMockFacet(address(instance)).getValue(), 100);
  }
}
