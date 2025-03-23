// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IDiamondCutBase, IDiamondCut} from "./IDiamondCut.sol";
import {IDiamond} from "../../IDiamond.sol";

// libraries
import {DiamondCutStorage} from "./DiamondCutStorage.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// contracts

library DiamondCutBase {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;

  /// @dev Performs a diamond cut.
  function diamondCut(
    IDiamond.FacetCut[] memory facetCuts,
    address init,
    bytes memory initPayload
  ) internal {
    uint256 facetCutLength = facetCuts.length;

    if (facetCutLength == 0)
      revert IDiamondCutBase.DiamondCut_InvalidFacetCutLength();

    for (uint256 i; i < facetCutLength; ++i) {
      IDiamond.FacetCut memory facetCut = facetCuts[i];

      _validateFacetCut(facetCut);

      if (facetCut.action == IDiamond.FacetCutAction.Add) {
        _addFacet(facetCut.facetAddress, facetCut.functionSelectors);
      } else if (facetCut.action == IDiamond.FacetCutAction.Replace) {
        _replaceFacet(facetCut.facetAddress, facetCut.functionSelectors);
      } else if (facetCut.action == IDiamond.FacetCutAction.Remove) {
        _removeFacet(facetCut.facetAddress, facetCut.functionSelectors);
      }
    }

    emit IDiamondCutBase.DiamondCut(facetCuts, init, initPayload);

    _initializeDiamondCut(facetCuts, init, initPayload);
  }

  ///@notice Add a new facet to the diamond
  ///@param facet The facet to add
  ///@param selectors The selectors for the facet
  function _addFacet(address facet, bytes4[] memory selectors) internal {
    DiamondCutStorage.Layout storage ds = DiamondCutStorage.layout();

    // add facet to diamond storage
    // EnumerableSet will not add if the facet is already in the set
    ds.facets.add(facet);

    uint256 selectorCount = selectors.length;

    // add selectors to diamond storage
    for (uint256 i; i < selectorCount; ++i) {
      bytes4 selector = selectors[i];

      if (selector == bytes4(0)) {
        revert IDiamondCutBase.DiamondCut_InvalidSelector();
      }

      if (ds.facetBySelector[selector] != address(0)) {
        revert IDiamondCutBase.DiamondCut_FunctionAlreadyExists(selector);
      }

      ds.facetBySelector[selector] = facet;
      ds.selectorsByFacet[facet].add(selector);
    }
  }

  ///@notice Remove a facet from the diamond
  ///@param facet The facet to remove
  ///@param selectors The selectors for the facet
  function _removeFacet(address facet, bytes4[] memory selectors) internal {
    DiamondCutStorage.Layout storage ds = DiamondCutStorage.layout();

    if (facet == address(this))
      revert IDiamondCutBase.DiamondCut_ImmutableFacet();

    if (!ds.facets.contains(facet))
      revert IDiamondCutBase.DiamondCut_InvalidFacet(facet);

    uint256 selectorCount = selectors.length;

    for (uint256 i; i < selectorCount; ++i) {
      bytes4 selector = selectors[i];

      _validateSelector(selector);

      if (ds.facetBySelector[selector] != facet) {
        revert IDiamondCutBase.DiamondCut_InvalidFacetRemoval(facet, selector);
      }

      delete ds.facetBySelector[selector];

      ds.selectorsByFacet[facet].remove(selector);
    }

    if (ds.selectorsByFacet[facet].length() == 0) {
      ds.facets.remove(facet);
    }
  }

  /// @notice Replace a facet on the diamond
  /// @param facet The new facet
  /// @param selectors The selectors for the facet
  function _replaceFacet(address facet, bytes4[] memory selectors) internal {
    if (facet == address(this))
      revert IDiamondCutBase.DiamondCut_ImmutableFacet();

    DiamondCutStorage.Layout storage ds = DiamondCutStorage.layout();
    EnumerableSet.AddressSet storage currentFacets = ds.facets;

    // EnumerableSet will not add if the facet is already in the set
    currentFacets.add(facet);

    uint256 selectorCount = selectors.length;

    for (uint256 i; i < selectorCount; ++i) {
      bytes4 selector = selectors[i];

      _validateSelector(selector);

      address oldFacet = ds.facetBySelector[selector];

      if (oldFacet == address(this)) {
        revert IDiamondCutBase.DiamondCut_ImmutableFacet();
      }

      if (oldFacet == address(0)) {
        revert IDiamondCutBase.DiamondCut_FunctionDoesNotExist(facet);
      }

      if (oldFacet == facet) {
        revert IDiamondCutBase.DiamondCut_FunctionFromSameFacetAlreadyExists(
          selector
        );
      }

      // overwrite selector to new facet
      ds.facetBySelector[selector] = facet;

      // remove selector from old facet
      EnumerableSet.Bytes32Set storage oldFacetSelectors = ds.selectorsByFacet[
        oldFacet
      ];
      oldFacetSelectors.remove(selector);

      // add selector to new facet
      ds.selectorsByFacet[facet].add(selector);

      // remove old facet if it has no selectors
      if (oldFacetSelectors.length() == 0) {
        currentFacets.remove(oldFacet);
      }
    }
  }

  /// @notice Validate a facet cut
  /// @param facetCut The facet cut to validate
  function _validateFacetCut(IDiamond.FacetCut memory facetCut) internal view {
    if (facetCut.facetAddress == address(0)) {
      revert IDiamondCutBase.DiamondCut_InvalidFacet(facetCut.facetAddress);
    }

    if (
      facetCut.facetAddress != address(this) &&
      facetCut.facetAddress.code.length == 0
    ) {
      revert IDiamondCutBase.DiamondCut_InvalidFacet(facetCut.facetAddress);
    }

    if (facetCut.functionSelectors.length == 0) {
      revert IDiamondCutBase.DiamondCut_InvalidFacetSelectors(
        facetCut.facetAddress
      );
    }
  }

  function _validateSelector(bytes4 selector) internal pure {
    if (selector == bytes4(0)) {
      revert IDiamondCutBase.DiamondCut_InvalidSelector();
    }

    if (selector == IDiamondCut.diamondCut.selector) {
      revert IDiamondCutBase.DiamondCut_InvalidSelector();
    }
  }

  /// @notice Initialize Diamond Cut Payload
  /// @param init The init address
  /// @param initPayload The init payload
  function _initializeDiamondCut(
    IDiamond.FacetCut[] memory,
    address init,
    bytes memory initPayload
  ) internal {
    if (init == address(0)) return;

    if (init.code.length == 0) {
      revert IDiamondCutBase.DiamondCut_InvalidContract(init);
    }

    Address.functionDelegateCall(init, initPayload);
  }
}
