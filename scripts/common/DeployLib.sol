// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {Vm} from "forge-std/Vm.sol";
import {LibClone} from "solady/utils/LibClone.sol";

library DeployLib {
    /// @dev Used when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    /// The calldata should be the 32 byte 'salt' followed by the init code.
    address internal constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice Deploy a contract by fetching the contract bytecode from the artifacts directory
    /// @dev Credit: forge-std/StdCheatsSafe::deployCode
    /// @param artifactPath The path to the contract artifact
    /// @param args The abi-encoded constructor arguments
    /// @param salt The salt to use for the CREATE2 deployment
    /// @return addr The address of the deployed contract
    function deployCode(
        string memory artifactPath,
        bytes memory args,
        bytes32 salt
    )
        internal
        returns (address addr)
    {
        bytes memory bytecode = bytes.concat(vm.getCode(artifactPath), args);
        addr = LibClone.predictDeterministicAddress(keccak256(bytecode), salt, CREATE2_FACTORY);
        // if the address is already deployed, return it
        if (addr.code.length > 0) return addr;
        addr = deployWithCreate2Factory(bytecode, salt);
    }

    /// @notice Deploy a contract by fetching the contract bytecode from the artifacts directory
    /// @dev Credit: forge-std/StdCheatsSafe::deployCode
    /// @param artifactPath The path to the contract artifact
    /// @param args The abi-encoded constructor arguments
    /// @return The address of the deployed contract
    function deployCode(string memory artifactPath, bytes memory args) internal returns (address) {
        return deployCode(artifactPath, args, 0);
    }

    /// @notice Deploy a contract using the default CREATE2 factory
    /// @param bytecode The bytecode of the contract to deploy
    /// @param salt The salt to use for the CREATE2 deployment
    /// @return addr The address of the deployed contract
    function deployWithCreate2Factory(
        bytes memory bytecode,
        bytes32 salt
    )
        internal
        returns (address addr)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // cache the length
            let len := mload(bytecode)
            // reuse the length pointer to avoid alloc
            mstore(bytecode, salt)
            if iszero(call(gas(), CREATE2_FACTORY, 0, bytecode, add(len, 0x20), 0, 0x14)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            addr := shr(96, mload(0))
            // restore the length
            mstore(bytecode, len)
        }
    }
}
