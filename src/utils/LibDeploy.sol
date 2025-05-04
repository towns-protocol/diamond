// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;
pragma experimental ABIEncoderV2;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {LibClone} from "solady/utils/LibClone.sol";

library LibDeploy {
    /// @dev Used when deploying with create2, https://github.com/Arachnid/deterministic-deployment-proxy.
    /// The calldata should be the 32 byte 'salt' followed by the init code.
    address internal constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    /// @dev Deterministic deployment address of the Multicall3 contract.
    /// Taken from https://www.multicall3.com.
    address internal constant MULTICALL3_ADDRESS = 0xcA11bde05977b3631167028862bE2a173976CA11;

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

    /// @notice Predict the address of a contract deployed with deployCode
    /// @param artifactPath The path to the contract artifact
    /// @param args The abi-encoded constructor arguments
    /// @param salt The salt to use for the CREATE2 deployment
    /// @return addr The predicted address of the deployed contract
    function predictDeployCode(
        string memory artifactPath,
        bytes memory args,
        bytes32 salt
    )
        internal
        view
        returns (address addr)
    {
        bytes memory bytecode = bytes.concat(vm.getCode(artifactPath), args);
        addr = LibClone.predictDeterministicAddress(keccak256(bytecode), salt, CREATE2_FACTORY);
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

    /// @notice Deploy multiple contracts using Multicall3.aggregate
    /// @param bytecodes Array of bytecodes for the contracts to deploy
    /// @param salts Array of salts to use for each deployment
    /// @return addresses Array of addresses of the deployed contracts
    function deployMultiple(
        bytes[] memory bytecodes,
        bytes32[] memory salts
    )
        internal
        returns (address[] memory addresses)
    {
        require(bytecodes.length == salts.length);

        // Create array of calls for multicall3
        IMulticall3.Call[] memory calls = new IMulticall3.Call[](bytecodes.length);

        for (uint256 i; i < bytecodes.length; ++i) {
            // CREATE2_FACTORY expects calldata: <32-byte salt><bytecode>
            bytes memory callData = bytes.concat(salts[i], bytecodes[i]);
            IMulticall3.Call memory call = calls[i];
            (call.target, call.callData) = (CREATE2_FACTORY, callData);
        }

        // Execute all calls in a batch
        (, bytes[] memory returnData) = IMulticall3(MULTICALL3_ADDRESS).aggregate(calls);

        // Extract deployed addresses from return data
        addresses = new address[](bytecodes.length);
        for (uint256 i; i < bytecodes.length; ++i) {
            addresses[i] = _extractAddressFromReturnData(returnData[i]);
        }
    }

    /// @dev Extract the deployed contract address from the CREATE2_FACTORY return data
    /// @param returnData The return data from the CREATE2_FACTORY call
    /// @return addr The deployed contract address
    function _extractAddressFromReturnData(bytes memory returnData)
        private
        pure
        returns (address addr)
    {
        /// @solidity memory-safe-assembly
        assembly {
            addr := shr(96, mload(add(returnData, 0x20)))
        }
    }
}
