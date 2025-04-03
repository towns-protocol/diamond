// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

//interfaces

//libraries

//contracts
import {TokenPausableFacet} from "../../../src/facets/pausable/token/TokenPausableFacet.sol";
import {SimpleDeployer} from "../../common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "../../common/helpers/FacetHelper.s.sol";

contract DeployTokenPausable is FacetHelper, SimpleDeployer {
    constructor() {
        addSelector(TokenPausableFacet.pause.selector);
        addSelector(TokenPausableFacet.unpause.selector);
        addSelector(TokenPausableFacet.paused.selector);
    }

    function versionName() public pure override returns (string memory) {
        return "tokenPausableFacet";
    }

    function __deploy(address deployer) public override returns (address) {
        vm.startBroadcast(deployer);
        TokenPausableFacet facet = new TokenPausableFacet();
        vm.stopBroadcast();
        return address(facet);
    }

    function initializer() public pure override returns (bytes4) {
        return TokenPausableFacet.__Pausable_init.selector;
    }
}
