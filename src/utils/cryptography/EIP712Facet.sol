// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

// interfaces
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

// libraries
import {EIP712Lib, EIP712Storage} from "../../primitive/EIP712.sol";

// contracts
import {Facet} from "../../facets/Facet.sol";
import {Nonces} from "../Nonces.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract EIP712Facet is IERC5267, EIP712Base, Nonces, Facet {
    using EIP712Lib for EIP712Storage;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP-712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(
        string memory name,
        string memory version
    )
        external
        virtual
        onlyInitializing
    {
        __EIP712_init_unchained(name, version);
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function nonces(address owner) external view virtual returns (uint256) {
        return _latestNonce(owner);
    }

    /// @inheritdoc IERC5267
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return _getEIP712Storage().eip712Domain();
    }
}
