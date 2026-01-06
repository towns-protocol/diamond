// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IDiamond} from "../../src/IDiamond.sol";

// libraries
import {LibDeploy} from "../../src/utils/LibDeploy.sol";

// contracts
import {Facet} from "../../src/facets/Facet.sol";
import {TokenOwnableBase} from "../../src/facets/ownable/token/TokenOwnableBase.sol";

interface IMockFacet {
    function mockFunction() external pure returns (uint256);

    function anotherMockFunction() external pure returns (uint256);

    function setValue(uint256 value_) external;

    function getValue() external view returns (uint256);

    function upgrade() external;
}

library MockFacetStorage {
    bytes32 internal constant MOCK_FACET_STORAGE_POSITION =
        keccak256("mock.facet.storage.position");

    struct Layout {
        uint256 value;
    }

    function layout() internal pure returns (Layout storage ds) {
        bytes32 position = MOCK_FACET_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

contract MockFacet is IMockFacet, TokenOwnableBase, Facet {
    using MockFacetStorage for MockFacetStorage.Layout;

    function __MockFacet_init(uint256 value) external onlyInitializing {
        MockFacetStorage.layout().value = value;
    }

    function upgrade() external reinitializer(2) {
        MockFacetStorage.layout().value = 100;
    }

    function mockFunction() external pure override returns (uint256) {
        return 42;
    }

    function anotherMockFunction() external pure returns (uint256) {
        return 43;
    }

    function setValue(uint256 value_) external onlyOwner {
        MockFacetStorage.layout().value = value_;
    }

    function getValue() external view returns (uint256) {
        return MockFacetStorage.layout().value;
    }
}

library DeployMockFacet {
    function selectors() internal pure returns (bytes4[] memory _selectors) {
        _selectors = new bytes4[](5);
        _selectors[0] = MockFacet.mockFunction.selector;
        _selectors[1] = MockFacet.anotherMockFunction.selector;
        _selectors[2] = MockFacet.upgrade.selector;
        _selectors[3] = MockFacet.setValue.selector;
        _selectors[4] = MockFacet.getValue.selector;
    }

    function makeCut(
        address facetAddress,
        IDiamond.FacetCutAction action
    )
        internal
        pure
        returns (IDiamond.FacetCut memory)
    {
        return IDiamond.FacetCut({
            action: action, facetAddress: facetAddress, functionSelectors: selectors()
        });
    }

    function makeInitData(uint256 value) internal pure returns (bytes memory) {
        return abi.encodeCall(MockFacet.__MockFacet_init, (value));
    }

    function deploy() internal returns (address) {
        return LibDeploy.deployCode("out/MockFacet.sol/MockFacet.json", "");
    }
}
