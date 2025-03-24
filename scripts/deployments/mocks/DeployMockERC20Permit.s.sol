// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts
import {DeployLib} from "scripts/common/DeployLib.sol";
import {SimpleDeployer} from "scripts/common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "scripts/common/helpers/FacetHelper.s.sol";
import {MockERC20Permit} from "test/mocks/MockERC20Permit.sol";
import {ERC20} from "src/facets/token/ERC20/ERC20.sol";
import {ERC20PermitBase} from "src/facets/token/ERC20/permit/ERC20PermitBase.sol";
import {IDiamond} from "src/IDiamond.sol";

library DeployMockERC20Permit {
  function selectors() internal pure returns (bytes4[] memory _selectors) {
    _selectors = new bytes4[](13);
    // ERC20
    _selectors[0] = ERC20.totalSupply.selector;
    _selectors[1] = ERC20.balanceOf.selector;
    _selectors[2] = ERC20.allowance.selector;
    _selectors[3] = ERC20.approve.selector;
    _selectors[4] = ERC20.transfer.selector;
    _selectors[5] = ERC20.transferFrom.selector;
    _selectors[6] = MockERC20Permit.mint.selector;
    // Metadata
    _selectors[7] = ERC20.name.selector;
    _selectors[8] = ERC20.symbol.selector;
    _selectors[9] = ERC20.decimals.selector;
    // Permit
    _selectors[10] = ERC20PermitBase.nonces.selector;
    _selectors[11] = ERC20PermitBase.permit.selector;
    _selectors[12] = ERC20PermitBase.DOMAIN_SEPARATOR.selector;
  }

  function makeCut(
    address facetAddress,
    IDiamond.FacetCutAction action
  ) internal pure returns (IDiamond.FacetCut memory) {
    return
      IDiamond.FacetCut({
        action: action,
        facetAddress: facetAddress,
        functionSelectors: selectors()
      });
  }

  function makeInitData(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal pure returns (bytes memory) {
    return
      abi.encodeCall(
        ERC20PermitBase.__ERC20PermitBase_init,
        (name, symbol, decimals)
      );
  }

  function deploy(address deployer) internal returns (address) {
    return
      DeployLib.deployCode(
        deployer,
        "./out/MockERC20Permit.sol/MockERC20Permit.json",
        ""
      );
  }
}
