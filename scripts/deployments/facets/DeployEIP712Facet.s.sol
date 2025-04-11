// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";
import {DynamicArrayLib} from "solady/utils/DynamicArrayLib.sol";

//contracts
import {EIP712Facet} from "../../../src/utils/cryptography/EIP712Facet.sol";

library DeployEIP712Facet {
    using DynamicArrayLib for DynamicArrayLib.DynamicArray;

    function selectors() internal pure returns (bytes4[] memory res) {
        DynamicArrayLib.DynamicArray memory arr = DynamicArrayLib.p().reserve(3);
        arr.p(EIP712Facet.DOMAIN_SEPARATOR.selector);
        arr.p(EIP712Facet.nonces.selector);
        arr.p(EIP712Facet.eip712Domain.selector);
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

    function makeInitData(
        string memory name,
        string memory version
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeCall(EIP712Facet.__EIP712_init, (name, version));
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("EIP712Facet.sol", "");
    }
}
