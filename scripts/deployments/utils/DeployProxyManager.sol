// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {LibDeploy} from "../../../src/utils/LibDeploy.sol";

//contracts
import {ProxyManager} from "../../../src/proxy/manager/ProxyManager.sol";

library DeployProxyManager {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](2);
        _selectors[0] = ProxyManager.getImplementation.selector;
        _selectors[1] = ProxyManager.setImplementation.selector;
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

    function makeInitData(address implementation) internal pure returns (bytes memory) {
        return abi.encodeCall(ProxyManager.__ProxyManager_init, (implementation));
    }

    function deploy() internal returns (address) {
        return LibDeploy.deployCode("ProxyManager.sol", "");
    }
}
