// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

//interfaces
import {IDiamond, Diamond} from "src/Diamond.sol";

//libraries
import {DiamondHelper} from "../../common/helpers/DiamondHelper.s.sol";

//contracts
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";

// deployments
import {DeployDiamondCut} from "../facets/DeployDiamondCut.s.sol";
import {DeployDiamondLoupe} from "../facets/DeployDiamondLoupe.s.sol";
import {DeployIntrospection} from "../facets/DeployIntrospection.s.sol";
import {DeployOwnablePending} from "../facets/DeployOwnablePending.s.sol";

// utils
import {DeployMultiInit} from "../facets/DeployMultiInit.s.sol";
import {MultiInit} from "../../../src/initializers/MultiInit.sol";

contract DeployDiamond is DiamondHelper, SimpleDeployer {
  DeployMultiInit private multiInitHelper = new DeployMultiInit();
  DeployDiamondCut private diamondCutHelper = new DeployDiamondCut();
  DeployDiamondLoupe private diamondLoupeHelper = new DeployDiamondLoupe();
  DeployIntrospection private introspectionHelper = new DeployIntrospection();
  DeployOwnablePending private ownableHelper = new DeployOwnablePending();

  function versionName() public pure override returns (string memory) {
    return "diamond";
  }

  function diamondInitParams(
    address deployer
  ) internal returns (Diamond.InitParams memory) {
    address multiInit = multiInitHelper.deploy(deployer);
    address diamondCut = diamondCutHelper.deploy(deployer);
    address diamondLoupe = diamondLoupeHelper.deploy(deployer);
    address introspection = introspectionHelper.deploy(deployer);
    address ownable = ownableHelper.deploy(deployer);

    addFacet(
      diamondCutHelper.makeCut(diamondCut, IDiamond.FacetCutAction.Add),
      diamondCut,
      diamondCutHelper.makeInitData("")
    );
    addFacet(
      diamondLoupeHelper.makeCut(diamondLoupe, IDiamond.FacetCutAction.Add),
      diamondLoupe,
      diamondLoupeHelper.makeInitData("")
    );
    addFacet(
      introspectionHelper.makeCut(introspection, IDiamond.FacetCutAction.Add),
      introspection,
      introspectionHelper.makeInitData("")
    );

    // we're setting the owner of the diamond during deployment
    addInit(ownable, ownableHelper.makeInitData(deployer));

    return
      Diamond.InitParams({
        baseFacets: baseFacets(),
        init: multiInit,
        initData: abi.encodeWithSelector(
          MultiInit.multiInit.selector,
          _initAddresses,
          _initDatas
        )
      });
  }

  function __deploy(address deployer) public override returns (address) {
    Diamond.InitParams memory initDiamondCut = diamondInitParams(deployer);

    vm.startBroadcast(deployer);
    Diamond diamond = new Diamond(initDiamondCut);
    vm.stopBroadcast();

    return address(diamond);
  }
}
