// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//interfaces

//libraries
import {LibString} from "solady/utils/LibString.sol";

//contracts
import {DeployBase} from "../DeployBase.s.sol";

abstract contract SimpleDeployer is DeployBase {
  // override this with the name of the deployment version that this script deploys
  function versionName() public view virtual returns (string memory);

  // override this with the actual deployment logic, no need to worry about:
  // - existing deployments
  // - loading private keys
  // - saving deployments
  // - logging
  function __deploy(address deployer) public virtual returns (address);

  // will first try to load existing deployments from `deployments/<network>/<contract>.json`
  // if OVERRIDE_DEPLOYMENTS is set to true or if no cached deployment is found:
  // - read PRIVATE_KEY from env
  // - invoke __deploy() with the private key
  // - save the deployment to `deployments/<network>/<contract>.json`
  function deploy() public virtual returns (address deployedAddr) {
    return deploy(msg.sender);
  }

  function deploy(
    address deployer
  ) public virtual returns (address deployedAddr) {
    return deploy(deployer, versionName());
  }

  function deploy(
    address deployer,
    string memory versionName_
  ) internal virtual returns (address deployedAddr) {
    bool overrideDeployment = vm.envOr("OVERRIDE_DEPLOYMENTS", uint256(0)) > 0;

    address existingAddr = isTesting()
      ? address(0)
      : getDeployment(versionName_);

    if (!overrideDeployment && existingAddr != address(0)) {
      info(
        string.concat(
          unicode"📝 using an existing address for ",
          versionName_,
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
          versionName_,
          unicode"\n\t⚡️ on ",
          chainIdAlias(),
          unicode"\n\t📬 from deployer address"
        ),
        LibString.toHexStringChecksummed(deployer)
      );
    }

    // call __deploy hook
    deployedAddr = __deploy(deployer);

    if (!isTesting()) {
      info(
        string.concat(unicode"✅ ", versionName_, " deployed at"),
        LibString.toHexStringChecksummed(deployedAddr)
      );

      if (deployedAddr != address(0)) {
        saveDeployment(versionName_, deployedAddr);
      }
    }
  }

  function run() public virtual {
    deploy();
  }
}
