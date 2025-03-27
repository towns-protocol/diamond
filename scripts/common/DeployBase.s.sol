// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interfaces

// libraries
import {LibString} from "solady/utils/LibString.sol";

// contracts
import {Script} from "forge-std/Script.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";
import {Context} from "./Context.sol";

abstract contract DeployBase is Context, DeployHelpers, Script {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                     DEPLOYMENT HELPERS                     */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  modifier broadcastWith(address deployer) {
    vm.startBroadcast(deployer);
    _;
    vm.stopBroadcast();
  }

  /// @notice Deploys a contract with caching and override functionality
  /// @dev This function handles the deployment process including:
  ///      - Checking for existing deployments
  ///      - Respecting override flags
  ///      - Logging deployment information
  ///      - Saving deployment addresses
  /// @param deployer The address that will deploy the contract
  /// @param versionName The name/version of the contract being deployed
  /// @param deployFn The deployment function to execute
  /// @return deployedAddr The address of the deployed contract
  function deploy(
    address deployer,
    string memory versionName,
    function(address) internal returns (address) deployFn
  ) internal virtual returns (address deployedAddr) {
    bool overrideDeployment = vm.envOr("OVERRIDE_DEPLOYMENTS", uint256(0)) > 0;

    address existingAddr = isTesting()
      ? address(0)
      : getDeployment(versionName);

    if (!overrideDeployment && existingAddr != address(0)) {
      info(
        string.concat(
          unicode"📝 using an existing address for ",
          versionName,
          " at"
        ),
        LibString.toHexStringChecksummed(existingAddr)
      );
      return existingAddr;
    }

    if (!isTesting()) {
      info(
        string.concat(
          unicode"deploying \n\t📜 ",
          versionName,
          unicode"\n\t⚡️ on ",
          chainIdAlias(),
          unicode"\n\t📬 from deployer address"
        ),
        LibString.toHexStringChecksummed(deployer)
      );
    }

    deployedAddr = deployFn(deployer);

    if (!isTesting()) {
      info(
        string.concat(unicode"✅ ", versionName, " deployed at"),
        LibString.toHexStringChecksummed(deployedAddr)
      );

      if (deployedAddr != address(0)) {
        saveDeployment(versionName, deployedAddr);
      }
    }
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       STRING HELPERS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice returns the chain alias for the current chain
  function chainIdAlias() internal returns (string memory) {
    string memory chainAlias = block.chainid == 31337
      ? "base_anvil"
      : getChain(block.chainid).chainAlias;
    return sliceBefore(chainAlias, "_", chainAlias);
  }

  /// @dev Override to set the artifact output directory
  function outDir() internal pure virtual returns (string memory) {
    return "out/";
  }

  /// @dev Override to set the deployment cache path
  function deploymentCachePath() internal pure virtual returns (string memory) {
    return "deployments";
  }

  function networkDirPath() internal returns (string memory path) {
    string memory context = getDeploymentContext();
    string memory chainAlias = chainIdAlias();

    // if no context is provided, use the default path
    if (bytes(context).length == 0) {
      context = string.concat(deploymentCachePath(), "/", chainAlias);
    } else {
      context = string.concat(
        deploymentCachePath(),
        "/",
        context,
        "/",
        chainAlias
      );
    }

    path = string.concat(vm.projectRoot(), "/", context);
  }

  function addressesPath(
    string memory versionName,
    string memory networkDir
  ) internal pure returns (string memory path) {
    return string.concat(networkDir, "/addresses/", versionName, ".json");
  }

  function sliceBefore(
    string memory fullString,
    string memory char,
    string memory replacement
  ) internal pure returns (string memory) {
    uint256 charIndex = LibString.indexOf(fullString, char);
    if (charIndex == LibString.NOT_FOUND) {
      return replacement;
    }
    return LibString.slice(fullString, 0, charIndex);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         FILE SYSTEM                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  function getDeployment(string memory versionName) internal returns (address) {
    string memory networkDir = networkDirPath();
    string memory path = addressesPath(versionName, networkDir);

    if (!exists(path)) {
      debug(
        string.concat(
          "no deployment found for ",
          versionName,
          " on ",
          chainIdAlias()
        )
      );
      return address(0);
    }

    string memory data = vm.readFile(path);
    return vm.parseJsonAddress(data, ".address");
  }

  function saveDeployment(
    string memory versionName,
    address contractAddr
  ) internal {
    if (!shouldSaveDeployments()) {
      debug("(set SAVE_DEPLOYMENTS=1 to save deployments to file)");
      return;
    }

    string memory networkDir = networkDirPath();

    // create addresses directory
    createDir(string.concat(networkDir, "/", "addresses"));
    createChainIdFile(networkDir);

    // Get directory from version name if it contains a "/"
    string memory typeDir = sliceBefore(versionName, "/", "");
    if (bytes(typeDir).length > 0) {
      createDir(string.concat(networkDir, "/", "addresses", "/", typeDir));
    }

    // get deployment path
    string memory path = addressesPath(versionName, networkDir);

    // save deployment
    debug("saving deployment to: ", path);
    string memory contractJson = vm.serializeAddress(
      "addresses",
      "address",
      contractAddr
    );
    vm.writeJson(contractJson, path);
  }

  function createChainIdFile(string memory networkDir) internal {
    string memory chainIdFilePath = string.concat(networkDir, "/chainId.json");

    if (!exists(chainIdFilePath)) {
      debug("creating chain id file: ", chainIdFilePath);
      string memory jsonStr = vm.serializeUint("chainIds", "id", block.chainid);
      vm.writeJson(jsonStr, chainIdFilePath);
    }
  }
}
