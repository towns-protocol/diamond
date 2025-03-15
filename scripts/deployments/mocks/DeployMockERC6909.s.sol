// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC6909} from "src/facets/token/ERC6909/IERC6909.sol";

// libraries

// contracts
import {SimpleDeployer} from "scripts/common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "scripts/common/helpers/FacetHelper.s.sol";
import {MockERC6909} from "test/mocks/MockERC6909.sol";
import {ERC6909} from "src/facets/token/ERC6909/ERC6909.sol";

contract DeployMockERC6909 is SimpleDeployer, FacetHelper {
  constructor() {
    // ERC6909
    addSelector(ERC6909.name.selector);
    addSelector(ERC6909.symbol.selector);
    addSelector(ERC6909.decimals.selector);
    addSelector(ERC6909.contractURI.selector);
    addSelector(ERC6909.tokenURI.selector);
    addSelector(IERC6909.totalSupply.selector);
    addSelector(IERC6909.balanceOf.selector);
    addSelector(IERC6909.allowance.selector);
    addSelector(IERC6909.isOperator.selector);
    addSelector(IERC6909.transfer.selector);
    addSelector(IERC6909.transferFrom.selector);
    addSelector(IERC6909.approve.selector);
    addSelector(IERC6909.setOperator.selector);
    addSelector(MockERC6909.mint.selector);
    addSelector(MockERC6909.burn.selector);
  }

  function versionName() public pure override returns (string memory) {
    return "mockERC6909";
  }

  function __deploy(address deployer) public override returns (address) {
    vm.startBroadcast(deployer);
    MockERC6909 facet = new MockERC6909();
    vm.stopBroadcast();
    return address(facet);
  }
}
