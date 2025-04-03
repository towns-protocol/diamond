// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts
interface IProxyManagerBase {
    /// @dev Thrown when the implementation is not a contract
    error ProxyManager__NotContract(address implementation);

    /// @dev Emitted when the implementation is set
    event ProxyManager__ImplementationSet(address implementation);
}

interface IProxyManager is IProxyManagerBase {
    /// @notice Get the implementation for a given selector
    /// @param selector The selector to get the implementation for
    /// @return The implementation address
    function getImplementation(bytes4 selector) external view returns (address);

    /// @notice Set the implementation
    /// @param implementation The implementation address
    function setImplementation(address implementation) external;
}
