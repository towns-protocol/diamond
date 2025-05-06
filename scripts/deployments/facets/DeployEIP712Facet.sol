// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";

//contracts
import {EIP712Facet} from "../../../src/utils/cryptography/EIP712Facet.sol";

library DeployEIP712Facet {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](3);
        _selectors[0] = EIP712Facet.DOMAIN_SEPARATOR.selector;
        _selectors[1] = EIP712Facet.nonces.selector;
        _selectors[2] = EIP712Facet.eip712Domain.selector;
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
        return LibDeploy.deployCode("EIP712Facet.sol", "");
    }
}
