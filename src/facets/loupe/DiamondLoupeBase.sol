// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IDiamondLoupeBase} from "./IDiamondLoupe.sol";

// libraries
import {DiamondCutStorage} from "../cut/DiamondCutStorage.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// contracts

library DiamondLoupeBase {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function facetSelectors(address facet) internal view returns (bytes4[] memory selectors) {
        bytes32[] memory selectors_ = DiamondCutStorage.layout().selectorsByFacet[facet].values();

        assembly ("memory-safe") {
            selectors := selectors_
        }
    }

    function facetAddresses() internal view returns (address[] memory _facetAddresses) {
        return DiamondCutStorage.layout().facets.values();
    }

    function facetAddress(bytes4 selector) internal view returns (address _facetAddress) {
        return DiamondCutStorage.layout().facetBySelector[selector];
    }

    function facets() internal view returns (IDiamondLoupeBase.Facet[] memory _facets) {
        address[] memory _facetAddresses = facetAddresses();
        uint256 facetCount = _facetAddresses.length;
        _facets = new IDiamondLoupeBase.Facet[](facetCount);

        for (uint256 i; i < facetCount; ++i) {
            address _facetAddress = _facetAddresses[i];
            _facets[i] = IDiamondLoupeBase.Facet({
                facet: _facetAddress,
                selectors: facetSelectors(_facetAddress)
            });
        }
    }
}
