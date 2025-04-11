// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";

//contracts
import {ManagedProxyFacet} from "../../../src/proxy/managed/ManagedProxyFacet.sol";

library DeployManagedProxy {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](2);
        _selectors[0] = ManagedProxyFacet.getManager.selector;
        _selectors[1] = ManagedProxyFacet.setManager.selector;
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

    function makeInitData() internal pure returns (bytes memory) {
        return abi.encodeCall(ManagedProxyFacet.__ManagedProxy_init, ());
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("ManagedProxyFacet.sol", "");
    }
}
