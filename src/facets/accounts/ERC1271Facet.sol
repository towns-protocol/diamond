// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IERC1271} from "./IERC1271.sol";

// libraries

// contracts
import {Facet} from "../Facet.sol";
import {ERC1271Base} from "./ERC1271Base.sol";

/**
 * @title ERC1271Facet
 * @dev Implementation of ERC1271 standard for signature validation in smart contracts
 * This facet allows a diamond contract to validate signatures according to ERC1271
 * with nested EIP-712 support for enhanced security and wallet UX.
 *
 * @notice This facet assumes that EIP712Facet is already deployed to the diamond
 * to provide EIP712 domain functionality.
 *
 * @notice Custom facets can override `_erc1271Signer()` to provide constant signer
 * addresses for gas optimization, similar to how EIP712Facet allows overriding
 * `_domainNameAndVersion()`.
 *
 * Example usage:
 * ```solidity
 * contract MyCustomERC1271Facet is ERC1271Facet {
 *     function _erc1271Signer() internal pure override returns (address) {
 *         return 0x742d35Cc6634C0532925a3b8D5c2C0E8b9d7C8Ed; // Your constant signer
 *     }
 * }
 * ```
 */
contract ERC1271Facet is IERC1271, ERC1271Base, Facet {
    /**
     * @dev Initializes the ERC1271 facet
     * @param signer Optional signer address. If address(0), the diamond itself is used
     *
     * @notice EIP712Facet must be initialized separately before or after this facet
     */
    function __ERC1271_init(address signer) external onlyInitializing {
        __ERC1271_init_unchained(signer);
    }

    function __ERC1271_init_unchained(address signer) internal {
        if (signer != address(0)) {
            _setSigner(signer);
        }
        _addInterface(type(IERC1271).interfaceId);
    }

    /// @inheritdoc IERC1271
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    )
        external
        view
        override
        returns (bytes4 magicValue)
    {
        return _isValidSignature(hash, signature);
    }

    /**
     * @dev Returns the current signer address used for validation
     */
    function erc1271Signer() external view returns (address) {
        return _erc1271Signer();
    }

    /**
     * @dev Returns the ERC1271 signer address.
     * This function reads from storage by default, but can be overridden to return
     * a constant value for gas optimization.
     *
     * Example override in a custom facet:
     * ```solidity
     * function _erc1271Signer() internal pure override returns (address) {
     *     return 0x1234567890123456789012345678901234567890; // Constant signer
     * }
     * ```
     */
    function _erc1271Signer() internal view virtual override returns (address) {
        return super._erc1271Signer();
    }
}
