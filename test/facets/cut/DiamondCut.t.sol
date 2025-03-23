// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// utils
import {TestUtils} from "test/TestUtils.sol";

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IDiamondCutBase} from "src/facets/cut/IDiamondCut.sol";
import {IDiamond} from "src/Diamond.sol";
import {IDiamondCut, IDiamondCutBase} from "src/facets/cut/IDiamondCut.sol";
import {IOwnableBase} from "src/facets/ownable/IERC173.sol";
import {IMockFacet} from "test/mocks/MockFacet.sol";

// libraries
import {Errors} from "@openzeppelin/contracts/utils/Errors.sol";

// contracts
import {DeployDiamond} from "scripts/deployments/diamonds/DeployDiamond.s.sol";
import {DeployDiamondCut} from "scripts/deployments/facets/DeployDiamondCut.s.sol";
import {DeployMockFacet, MockFacet} from "test/mocks/MockFacet.sol";

contract DiamondCutTest is TestUtils, IDiamondCutBase, IOwnableBase {
  DeployMockFacet mockFacetHelper = new DeployMockFacet();
  DeployDiamond diamondHelper = new DeployDiamond();
  DeployDiamondCut diamondCutHelper = new DeployDiamondCut();

  address diamond;
  address deployer;
  IDiamondCut diamondCut;

  function setUp() public {
    deployer = getDeployer();
    diamond = diamondHelper.deploy(deployer);
    diamondCut = IDiamondCut(diamond);
  }

  function test_supportsInterface() external view {
    assertTrue(
      IERC165(diamond).supportsInterface(type(IDiamondCut).interfaceId)
    );
  }

  IDiamond.FacetCut[] internal facetCuts;

  function test_diamondCut() external {
    // create facet cuts
    address mockFacet = mockFacetHelper.deploy(deployer);
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = mockFacetHelper.makeCut(
      mockFacet,
      IDiamond.FacetCutAction.Add
    );
    vm.expectEmit(true, true, true, true, diamond);
    emit DiamondCut(extensions, address(0), "");
    // cut diamond
    vm.prank(deployer);
    diamondCut.diamondCut(extensions, address(0), "");
    // assert facet function is callable
    assertEq(IMockFacet(diamond).mockFunction(), 42);
  }

  function test_diamondCut_reverts_when_not_owner() external {
    // create facet selectors
    address mockFacet = mockFacetHelper.deploy(deployer);
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = mockFacetHelper.makeCut(
      mockFacet,
      IDiamond.FacetCutAction.Add
    );
    address caller = _randomAddress();
    vm.expectRevert(abi.encodeWithSelector(Ownable__NotOwner.selector, caller));
    vm.prank(caller);
    diamondCut.diamondCut(extensions, address(0), "");
  }

  function test_reverts_when_init_not_contract() external {
    address mockFacet = mockFacetHelper.deploy(deployer);
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = mockFacetHelper.makeCut(
      mockFacet,
      IDiamond.FacetCutAction.Add
    );
    address init = _randomAddress();
    vm.expectRevert(
      abi.encodeWithSelector(DiamondCut_InvalidContract.selector, init)
    );
    vm.prank(deployer);
    diamondCut.diamondCut(extensions, init, "");
  }

  function test_revertWhenFacetIsZeroAddress() external {
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = IDiamond.FacetCut({
      facetAddress: address(0),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: new bytes4[](0)
    });
    vm.expectRevert(
      abi.encodeWithSelector(DiamondCut_InvalidFacet.selector, address(0))
    );
    vm.prank(deployer);
    diamondCut.diamondCut(extensions, address(0), "");
  }

  function test_revertsWhenFacetIsNotContract() external {
    address facet = _randomAddress();
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: facet,
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: new bytes4[](0)
      })
    );
    vm.expectRevert(
      abi.encodeWithSelector(DiamondCut_InvalidFacet.selector, facet)
    );
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  function test_revertsWhenSelectorArrayIsEmpty() external {
    address mockFacet = mockFacetHelper.deploy(deployer);
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(mockFacet),
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: new bytes4[](0)
      })
    );
    vm.expectRevert(
      abi.encodeWithSelector(
        DiamondCut_InvalidFacetSelectors.selector,
        address(mockFacet)
      )
    );
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  function test_revertWhen_initializeDiamondCut() external {
    // create facet selectors
    address mockFacet = mockFacetHelper.deploy(deployer);
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = mockFacetHelper.makeCut(
      mockFacet,
      IDiamond.FacetCutAction.Add
    );
    // cut diamond
    vm.expectRevert(Errors.FailedCall.selector);
    vm.prank(deployer);
    diamondCut.diamondCut(extensions, mockFacet, "");
  }

  // =============================================================
  //                           Add Facet
  // =============================================================
  function test_revertWhenAddingFunctionAlreadyExists() external {
    address mockFacet = mockFacetHelper.deploy(deployer);
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = mockFacetHelper.makeCut(
      mockFacet,
      IDiamond.FacetCutAction.Add
    );
    vm.prank(deployer);
    diamondCut.diamondCut(extensions, address(0), "");
    vm.expectRevert(
      abi.encodeWithSelector(
        DiamondCut_FunctionAlreadyExists.selector,
        extensions[0].functionSelectors[0]
      )
    );
    vm.prank(deployer);
    diamondCut.diamondCut(extensions, address(0), "");
  }

  function test_revertWhenAddingZeroSelector() external {
    address mockFacet = mockFacetHelper.deploy(deployer);
    bytes4[] memory facetSelectors = new bytes4[](1);
    facetSelectors[0] = bytes4(0);
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(mockFacet),
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetSelectors
      })
    );
    vm.expectRevert(DiamondCut_InvalidSelector.selector);
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  // =============================================================
  //                        Remove Facet
  // =============================================================
  function test_revertWhenRemovingFromOtherFacet() external {
    address mockFacet = mockFacetHelper.deploy(deployer);
    // create facet selectors
    bytes4[] memory facetSelectors = new bytes4[](1);
    facetSelectors[0] = IMockFacet.mockFunction.selector;
    // create facet cuts
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = IDiamond.FacetCut({
      facetAddress: address(mockFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetSelectors
    });
    // cut diamond
    vm.prank(deployer);
    diamondCut.diamondCut(extensions, address(0), "");
    facetSelectors = new bytes4[](1);
    facetSelectors[0] = 0x12345678;
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(mockFacet),
        action: IDiamond.FacetCutAction.Remove,
        functionSelectors: facetSelectors
      })
    );
    vm.expectRevert(
      abi.encodeWithSelector(
        DiamondCut_InvalidFacetRemoval.selector,
        address(mockFacet),
        facetSelectors[0]
      )
    );
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  function test_revertWhenRemovingZeroSelector() external {
    address mockFacet = mockFacetHelper.deploy(deployer);
    // create facet selectors
    bytes4[] memory facetSelectors = new bytes4[](1);
    facetSelectors[0] = IMockFacet.mockFunction.selector;
    // create facet cuts
    IDiamond.FacetCut[] memory extensions = new IDiamond.FacetCut[](1);
    extensions[0] = IDiamond.FacetCut({
      facetAddress: address(mockFacet),
      action: IDiamond.FacetCutAction.Add,
      functionSelectors: facetSelectors
    });
    // cut diamond
    vm.prank(deployer);
    diamondCut.diamondCut(extensions, address(0), "");
    facetSelectors = new bytes4[](1);
    facetSelectors[0] = bytes4(0);
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(mockFacet),
        action: IDiamond.FacetCutAction.Remove,
        functionSelectors: facetSelectors
      })
    );
    vm.expectRevert(DiamondCut_InvalidSelector.selector);
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  function test_revertWhenRemovingImmutableSelector() external {
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(diamond),
        action: IDiamond.FacetCutAction.Remove,
        functionSelectors: new bytes4[](1)
      })
    );
    vm.expectRevert(DiamondCut_ImmutableFacet.selector);
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  // =============================================================
  //                        Replace Facet
  // =============================================================
  function test_revertWhenReplacingZeroSelector() external {
    address mockFacet = mockFacetHelper.deploy(deployer);
    bytes4[] memory facetSelectors = new bytes4[](1);
    facetSelectors[0] = bytes4(0);
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(mockFacet),
        action: IDiamond.FacetCutAction.Replace,
        functionSelectors: facetSelectors
      })
    );
    vm.expectRevert(DiamondCut_InvalidSelector.selector);
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  function test_revertWhenReplacingFunctionFromSameFacet() external {
    address mockFacet = mockFacetHelper.deploy(deployer);
    bytes4[] memory facetSelectors = new bytes4[](1);
    facetSelectors[0] = IMockFacet.mockFunction.selector;
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(mockFacet),
        action: IDiamond.FacetCutAction.Add,
        functionSelectors: facetSelectors
      })
    );
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(mockFacet),
        action: IDiamond.FacetCutAction.Replace,
        functionSelectors: facetSelectors
      })
    );
    vm.expectRevert(
      abi.encodeWithSelector(
        DiamondCut_FunctionFromSameFacetAlreadyExists.selector,
        facetSelectors[0]
      )
    );
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  function test_revertWhenReplacingImmutableFunction() external {
    bytes4[] memory facetSelectors = new bytes4[](1);
    facetSelectors[0] = IMockFacet.mockFunction.selector;
    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(diamond),
        action: IDiamond.FacetCutAction.Replace,
        functionSelectors: facetSelectors
      })
    );
    vm.expectRevert(DiamondCut_ImmutableFacet.selector);
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }

  function test_revertWhenReplacingDiamondCut() external {
    address cutFacet = diamondCutHelper.deploy(deployer);
    bytes4[] memory selectors = new bytes4[](1);
    selectors[0] = IDiamondCut.diamondCut.selector;

    facetCuts.push(
      IDiamond.FacetCut({
        facetAddress: address(cutFacet),
        action: IDiamond.FacetCutAction.Replace,
        functionSelectors: selectors
      })
    );

    vm.expectRevert(DiamondCut_InvalidSelector.selector);
    vm.prank(deployer);
    diamondCut.diamondCut(facetCuts, address(0), "");
  }
}
