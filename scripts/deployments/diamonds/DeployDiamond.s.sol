// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

//interfaces
import {Diamond, IDiamond} from "src/Diamond.sol";

//libraries
import {DiamondHelper} from "../../common/helpers/DiamondHelper.s.sol";

//contracts
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";

// deployments
import {DeployFacet} from "../../common/DeployFacet.s.sol";
import {DeployDiamondCut} from "../facets/DeployDiamondCut.s.sol";
import {DeployDiamondLoupe} from "../facets/DeployDiamondLoupe.s.sol";
import {DeployIntrospection} from "../facets/DeployIntrospection.s.sol";
import {DeployOwnablePending} from "../facets/DeployOwnablePending.s.sol";

// utils
import {MultiInit} from "../../../src/initializers/MultiInit.sol";

contract DeployDiamond is DiamondHelper, SimpleDeployer {
    DeployFacet private facetHelper = new DeployFacet();

    function versionName() public pure override returns (string memory) {
        return "diamond";
    }

    function diamondInitParams(address deployer) internal returns (Diamond.InitParams memory) {
        address multiInit = facetHelper.deploy("MultiInit", deployer);
        address diamondCut = facetHelper.deploy("DiamondCutFacet", deployer);
        address diamondLoupe = facetHelper.deploy("DiamondLoupeFacet", deployer);
        address introspection = facetHelper.deploy("IntrospectionFacet", deployer);
        address ownable = facetHelper.deploy("OwnablePendingFacet", deployer);

        addFacet(
            DeployDiamondCut.makeCut(diamondCut, IDiamond.FacetCutAction.Add),
            diamondCut,
            DeployDiamondCut.makeInitData()
        );
        addFacet(
            DeployDiamondLoupe.makeCut(diamondLoupe, IDiamond.FacetCutAction.Add),
            diamondLoupe,
            DeployDiamondLoupe.makeInitData()
        );
        addFacet(
            DeployIntrospection.makeCut(introspection, IDiamond.FacetCutAction.Add),
            introspection,
            DeployIntrospection.makeInitData()
        );

        // we're setting the owner of the diamond during deployment
        addInit(ownable, DeployOwnablePending.makeInitData(deployer));

        return Diamond.InitParams({
            baseFacets: baseFacets(),
            init: multiInit,
            initData: abi.encodeWithSelector(MultiInit.multiInit.selector, _initAddresses, _initDatas)
        });
    }

    function __deploy(address deployer) internal override returns (address) {
        Diamond.InitParams memory initDiamondCut = diamondInitParams(deployer);

        vm.broadcast(deployer);
        Diamond diamond = new Diamond(initDiamondCut);
        return address(diamond);
    }
}
