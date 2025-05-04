// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IDiamond} from "../../../src/IDiamond.sol";
import {
    IERC6909,
    IERC6909ContentURI,
    IERC6909Metadata,
    IERC6909TokenSupply
} from "@openzeppelin/contracts/interfaces/draft-IERC6909.sol";

// libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";
import {DynamicArrayLib} from "solady/utils/DynamicArrayLib.sol";

// contracts
import {MockERC6909} from "../../../test/mocks/MockERC6909.sol";

library DeployMockERC6909 {
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;

    function selectors() internal pure returns (bytes4[] memory res) {
        DynamicArrayLib.DynamicArray memory arr = DynamicArrayLib.p().reserve(15);
        arr.p(IERC6909Metadata.name.selector);
        arr.p(IERC6909Metadata.symbol.selector);
        arr.p(IERC6909Metadata.decimals.selector);
        arr.p(IERC6909ContentURI.contractURI.selector);
        arr.p(IERC6909ContentURI.tokenURI.selector);
        arr.p(IERC6909TokenSupply.totalSupply.selector);
        arr.p(IERC6909.balanceOf.selector);
        arr.p(IERC6909.allowance.selector);
        arr.p(IERC6909.isOperator.selector);
        arr.p(IERC6909.transfer.selector);
        arr.p(IERC6909.transferFrom.selector);
        arr.p(IERC6909.approve.selector);
        arr.p(IERC6909.setOperator.selector);
        arr.p(MockERC6909.mint.selector);
        arr.p(MockERC6909.burn.selector);

        bytes32[] memory selectors_ = arr.asBytes32Array();
        assembly ("memory-safe") {
            res := selectors_
        }
    }

    function makeCut(
        address facetAddress,
        IDiamond.FacetCutAction action
    )
        internal
        pure
        returns (IDiamond.FacetCut memory)
    {
        return IDiamond.FacetCut({
            action: action,
            facetAddress: facetAddress,
            functionSelectors: selectors()
        });
    }

    function deploy() internal returns (address) {
        return LibDeploy.deployCode("MockERC6909.sol", "");
    }
}
