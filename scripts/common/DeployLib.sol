// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

import {Vm} from "forge-std/Vm.sol";

library DeployLib {
  Vm private constant vm =
    Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

  modifier broadcastWith(address deployer) {
    vm.startBroadcast(deployer);
    _;
    vm.stopBroadcast();
  }

  /// @notice Deploy a contract by fetching the contract bytecode from the artifacts directory
  // e.g. `deployCode(code, abi.encode(arg1,arg2,arg3))`
  /// @dev Credit: forge-std/StdCheatsSafe::deployCode
  /// @param artifactPath The path to the contract artifact
  /// @param args The abi-encoded constructor arguments
  /// @return addr The address of the deployed contract
  function deployCode(
    address deployer,
    string memory artifactPath,
    bytes memory args
  ) internal broadcastWith(deployer) returns (address addr) {
    bytes memory bytecode = abi.encodePacked(vm.getCode(artifactPath), args);
    /// @solidity memory-safe-assembly
    assembly {
      addr := create(0, add(bytecode, 0x20), mload(bytecode))
    }
    require(
      addr != address(0),
      "StdCheats deployCode(string,bytes): Deployment failed."
    );
  }
}
