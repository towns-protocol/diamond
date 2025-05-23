// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDiamond} from "../../../src/IDiamond.sol";

abstract contract FacetHelper is IDiamond {
    bytes4[] public functionSelectors;
    uint256 internal _index;

    function initializer() public view virtual returns (bytes4) {
        return bytes4(0);
    }

    function selectors() public virtual returns (bytes4[] memory) {
        return functionSelectors;
    }

    function makeCut(
        address facetAddress,
        FacetCutAction action
    )
        public
        returns (FacetCut memory)
    {
        return
            FacetCut({action: action, facetAddress: facetAddress, functionSelectors: selectors()});
    }

    function makeInitData(bytes memory) public view virtual returns (bytes memory data) {
        return abi.encodeWithSelector(initializer());
    }

    function addSelector(bytes4 selector) public {
        functionSelectors.push(selector);
    }

    function addSelectors(bytes4[] memory selectors_) public {
        for (uint256 i; i < selectors_.length; ++i) {
            functionSelectors.push(selectors_[i]);
        }
    }

    function removeSelector(bytes4 selector) public {
        for (uint256 i; i < functionSelectors.length; ++i) {
            if (functionSelectors[i] == selector) {
                functionSelectors[i] = functionSelectors[functionSelectors.length - 1];
                functionSelectors.pop();
                break;
            }
        }
    }

    function facetInitHelper(
        address deployer,
        address facetAddress
    )
        external
        virtual
        returns (IDiamond.FacetCut memory, bytes memory)
    {
        bytes memory initData = abi.encode(deployer);
        return (makeCut(facetAddress, FacetCutAction.Add), makeInitData(initData));
    }
}
