// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IDiamond} from "./IDiamond.sol";

// libraries
import {DiamondCutBase} from "./facets/cut/DiamondCutBase.sol";
import {DiamondLoupeBase} from "./facets/loupe/DiamondLoupeBase.sol";

// contracts
import {Initializable} from "./facets/initializable/Initializable.sol";
import {Proxy} from "./proxy/Proxy.sol";

contract Diamond is IDiamond, Proxy, Initializable {
    struct InitParams {
        FacetCut[] baseFacets;
        address init;
        bytes initData;
    }

    constructor(InitParams memory initDiamondCut) initializer {
        DiamondCutBase.diamondCut(
            initDiamondCut.baseFacets, initDiamondCut.init, initDiamondCut.initData
        );
    }

    receive() external payable {}

    // =============================================================
    //                           Internal
    // =============================================================
    function _getImplementation() internal view virtual override returns (address facet) {
        facet = DiamondLoupeBase.facetAddress(msg.sig);
        if (facet == address(0)) revert Diamond_UnsupportedFunction();
    }
}
