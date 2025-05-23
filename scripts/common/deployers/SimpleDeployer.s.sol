// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//interfaces

//libraries

//contracts
import {DeployBase} from "../DeployBase.s.sol";

abstract contract SimpleDeployer is DeployBase {
    /// @dev Override this with the name of the deployment version that this script deploys
    function versionName() public view virtual returns (string memory);

    /// @dev Override this with the actual deployment logic, no need to worry about:
    // - existing deployments
    // - loading private keys
    // - saving deployments
    // - logging
    function __deploy(address deployer) internal virtual returns (address);

    /// @dev Will first try to load existing deployments from `deployments/<network>/<contract>.json`
    // if OVERRIDE_DEPLOYMENTS is set to true or if no cached deployment is found:
    // - read PRIVATE_KEY from env
    // - invoke __deploy() with the private key
    // - save the deployment to `deployments/<network>/<contract>.json`
    function deploy() public virtual returns (address deployedAddr) {
        return deploy(msg.sender);
    }

    function deploy(address deployer) public virtual returns (address deployedAddr) {
        return deploy(deployer, versionName(), __deploy);
    }

    function run() public virtual {
        deploy();
    }
}
