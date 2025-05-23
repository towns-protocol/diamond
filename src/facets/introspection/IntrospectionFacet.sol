// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// libraries

// contracts
import {Facet} from "../../facets/Facet.sol";
import {IntrospectionBase} from "./IntrospectionBase.sol";

contract IntrospectionFacet is IntrospectionBase, IERC165, Facet {
    function __Introspection_init() external virtual onlyInitializing {
        __IntrospectionBase_init();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportsInterface(interfaceId);
    }
}
