// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces
import {IDiamond} from "../../../src/IDiamond.sol";

//libraries
import {DeployLib} from "../../common/DeployLib.sol";

//contracts
import {OwnableFacet} from "../../../src/facets/ownable/OwnableFacet.sol";

library DeployOwnable {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](2);
        _selectors[0] = OwnableFacet.owner.selector;
        _selectors[1] = OwnableFacet.transferOwnership.selector;
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

    function makeInitData(address owner) internal pure returns (bytes memory) {
        return abi.encodeCall(OwnableFacet.__Ownable_init, (owner));
    }

    function deploy() internal returns (address) {
        return DeployLib.deployCode("OwnableFacet.sol", "");
    }
}
