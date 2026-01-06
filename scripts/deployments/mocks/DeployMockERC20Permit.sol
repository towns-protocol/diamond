// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

// libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";
import {DynamicArrayLib} from "solady/utils/DynamicArrayLib.sol";

// contracts
import {ERC20} from "../../../src/facets/token/ERC20/ERC20.sol";
import {ERC20PermitBase} from "../../../src/facets/token/ERC20/permit/ERC20PermitBase.sol";
import {MockERC20Permit} from "../../../test/mocks/MockERC20Permit.sol";

library DeployMockERC20Permit {
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;

    function selectors() internal pure returns (bytes4[] memory res) {
        DynamicArrayLib.DynamicArray memory arr = DynamicArrayLib.p().reserve(13);
        // ERC20
        arr.p(ERC20.totalSupply.selector);
        arr.p(ERC20.balanceOf.selector);
        arr.p(ERC20.allowance.selector);
        arr.p(ERC20.approve.selector);
        arr.p(ERC20.transfer.selector);
        arr.p(ERC20.transferFrom.selector);
        arr.p(MockERC20Permit.mint.selector);
        // Metadata
        arr.p(ERC20.name.selector);
        arr.p(ERC20.symbol.selector);
        arr.p(ERC20.decimals.selector);
        // Permit
        arr.p(ERC20PermitBase.nonces.selector);
        arr.p(ERC20PermitBase.permit.selector);
        arr.p(ERC20PermitBase.DOMAIN_SEPARATOR.selector);

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
            action: action, facetAddress: facetAddress, functionSelectors: selectors()
        });
    }

    function makeInitData(
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(ERC20PermitBase.__ERC20PermitBase_init, (name, symbol, decimals));
    }

    function deploy() internal returns (address) {
        return LibDeploy.deployCode("MockERC20Permit.sol", "");
    }
}
