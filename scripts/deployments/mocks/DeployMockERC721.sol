// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts
import {SimpleDeployer} from "scripts/common/deployers/SimpleDeployer.s.sol";
import {FacetHelper} from "scripts/common/helpers/FacetHelper.s.sol";
import {ERC721} from "src/facets/token/ERC721/ERC721.sol";
import {MockERC721} from "test/mocks/MockERC721.sol";

contract DeployMockERC721 is SimpleDeployer, FacetHelper {
    constructor() {
        // ERC721
        addSelector(ERC721.totalSupply.selector);
        addSelector(ERC721.balanceOf.selector);
        addSelector(ERC721.ownerOf.selector);
        addSelector(ERC721.approve.selector);
        addSelector(ERC721.getApproved.selector);
        addSelector(ERC721.setApprovalForAll.selector);
        addSelector(ERC721.isApprovedForAll.selector);
        addSelector(bytes4(keccak256("safeTransferFrom(address,address,uint256)")));
        addSelector(bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")));
        addSelector(ERC721.transferFrom.selector);
    }

    function versionName() public pure override returns (string memory) {
        return "mockERC721";
    }

    function initializer() public pure override returns (bytes4) {
        return ERC721.__ERC721_init.selector;
    }

    function makeInitData(
        string memory name,
        string memory symbol
    )
        public
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(initializer(), name, symbol);
    }

    function __deploy(address deployer) public override returns (address) {
        vm.startBroadcast(deployer);
        MockERC721 facet = new MockERC721();
        vm.stopBroadcast();
        return address(facet);
    }
}
