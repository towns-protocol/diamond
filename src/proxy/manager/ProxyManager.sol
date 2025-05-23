// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IProxyManager} from "./IProxyManager.sol";

// libraries
import {Facet} from "../../facets/Facet.sol";
import {OwnableBase} from "../../facets/ownable/OwnableBase.sol";
import {ProxyManagerBase} from "./ProxyManagerBase.sol";

/**
 * @title ProxyManager
 * @notice In charge of directing calls to the correct implementation contract, in use by the ManagedProxy contract to correctly direct calls to the correct implementation contract.
 * @dev The flow of calls goes as follows ManagedProxy -> ProxyManager -> Implementation
 */
contract ProxyManager is IProxyManager, ProxyManagerBase, OwnableBase, Facet {
    function __ProxyManager_init(address implementation) external onlyInitializing {
        _setImplementation(implementation);
        _addInterface(type(IProxyManager).interfaceId);
    }

    function getImplementation(bytes4 selector) external view virtual returns (address) {
        return _getImplementation(selector);
    }

    function setImplementation(address implementation) external virtual onlyOwner {
        _setImplementation(implementation);
    }
}
