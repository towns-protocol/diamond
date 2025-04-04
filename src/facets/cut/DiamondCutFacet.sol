// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IDiamond} from "../../IDiamond.sol";
import {IDiamondCut} from "./IDiamondCut.sol";

// libraries

// contracts
import {Facet} from "../Facet.sol";
import {OwnableBase} from "../ownable/OwnableBase.sol";
import {DiamondCutBase} from "./DiamondCutBase.sol";

contract DiamondCutFacet is IDiamondCut, OwnableBase, Facet {
    function __DiamondCut_init() external onlyInitializing {
        _addInterface(type(IDiamondCut).interfaceId);
    }

    /// @inheritdoc IDiamondCut
    function diamondCut(
        IDiamond.FacetCut[] memory facetCuts,
        address init,
        bytes memory initPayload
    )
        external
        onlyOwner
        reinitializer(_nextVersion())
    {
        DiamondCutBase.diamondCut(facetCuts, init, initPayload);
    }
}
