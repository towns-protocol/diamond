// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IDiamond} from "../../../src/IDiamond.sol";
import {IERC6909} from "../../../src/facets/token/ERC6909/IERC6909.sol";

// libraries
import {DeployLib} from "../../common/DeployLib.sol";

// contracts
import {ERC6909} from "../../../src/facets/token/ERC6909/ERC6909.sol";
import {MockERC6909} from "../../../test/mocks/MockERC6909.sol";

library DeployMockERC6909 {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](15);
        // ERC6909
        _selectors[0] = ERC6909.name.selector;
        _selectors[1] = ERC6909.symbol.selector;
        _selectors[2] = ERC6909.decimals.selector;
        _selectors[3] = ERC6909.contractURI.selector;
        _selectors[4] = ERC6909.tokenURI.selector;
        _selectors[5] = IERC6909.totalSupply.selector;
        _selectors[6] = IERC6909.balanceOf.selector;
        _selectors[7] = IERC6909.allowance.selector;
        _selectors[8] = IERC6909.isOperator.selector;
        _selectors[9] = IERC6909.transfer.selector;
        _selectors[10] = IERC6909.transferFrom.selector;
        _selectors[11] = IERC6909.approve.selector;
        _selectors[12] = IERC6909.setOperator.selector;
        _selectors[13] = MockERC6909.mint.selector;
        _selectors[14] = MockERC6909.burn.selector;
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
        return DeployLib.deployCode("MockERC6909.sol", "");
    }
}
