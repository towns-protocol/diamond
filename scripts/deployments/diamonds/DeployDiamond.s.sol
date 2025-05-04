// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

//interfaces
import {Diamond, IDiamond} from "src/Diamond.sol";

//libraries
import {DiamondHelper} from "../../common/helpers/DiamondHelper.s.sol";

//contracts
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";

// deployments
import {DeployFacet} from "../../common/DeployFacet.s.sol";
import {DeployDiamondCut} from "../facets/DeployDiamondCut.sol";
import {DeployDiamondLoupe} from "../facets/DeployDiamondLoupe.sol";
import {DeployIntrospection} from "../facets/DeployIntrospection.sol";
import {DeployOwnablePending} from "../facets/DeployOwnablePending.sol";

// utils
import {MultiInit} from "../../../src/initializers/MultiInit.sol";

contract DeployDiamond is DiamondHelper, SimpleDeployer {
    DeployFacet private facetHelper = new DeployFacet();

    function versionName() public pure override returns (string memory) {
        return "diamond";
    }

    function diamondInitParams(address deployer) internal returns (Diamond.InitParams memory) {
        // Queue up all facets for batch deployment
        facetHelper.add("MultiInit");
        facetHelper.add("DiamondCutFacet");
        facetHelper.add("DiamondLoupeFacet");
        facetHelper.add("IntrospectionFacet");
        facetHelper.add("OwnablePendingFacet");

        // Deploy all facets in a single batch transaction
        facetHelper.deployBatch(deployer);

        // Get deployed addresses
        address multiInit = facetHelper.getDeployedAddress("MultiInit");
        address diamondCut = facetHelper.getDeployedAddress("DiamondCutFacet");
        address diamondLoupe = facetHelper.getDeployedAddress("DiamondLoupeFacet");
        address introspection = facetHelper.getDeployedAddress("IntrospectionFacet");
        address ownable = facetHelper.getDeployedAddress("OwnablePendingFacet");

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
