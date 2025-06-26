// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IERC1271} from "./IERC1271.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

// libraries
import {EIP712Lib, EIP712Storage} from "../../primitive/EIP712.sol";
import {ERC1271Storage} from "./ERC1271Storage.sol";
import {ERC1271} from "solady/accounts/ERC1271.sol";
import {EIP712} from "solady/utils/EIP712.sol";

// contracts
import {EIP712Base} from "../../utils/cryptography/EIP712Base.sol";

abstract contract ERC1271Base is EIP712Base, EIP712, ERC1271 {
    using EIP712Lib for EIP712Storage;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EIP712                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Returns the domain name and version.
     * This function should be overridden by facets that want to use constant values
     * instead of reading from storage for gas optimization.
     *
     * NOTE: If the returned result may change after deployment,
     * you must override `_domainNameAndVersionMayChange()` to return true.
     */
    function _domainNameAndVersion()
        internal
        view
        virtual
        override
        returns (string memory name, string memory version)
    {
        // Default implementation reads from storage
        EIP712Storage storage $ = _getEIP712Storage();
        name = $._EIP712Name();
        version = $._EIP712Version();
    }

    /**
     * @dev Returns if `_domainNameAndVersion()` may change after deployment.
     * Default: false (values are fixed after initialization).
     * Override to return true if your implementation allows name/version to change.
     */
    function _domainNameAndVersionMayChange()
        internal
        pure
        virtual
        override
        returns (bool result)
    {
        // By default, assume name and version are fixed after initialization
        return false;
    }

    function _hashTypedData(bytes32 structHash)
        internal
        view
        virtual
        override
        returns (bytes32 digest)
    {
        _hashTypedDataV4(structHash);
    }

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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EIP1271                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Returns the ERC1271 signer.
     * Override to return the signer `isValidSignature` checks against.
     */
    function _erc1271Signer() internal view virtual override returns (address) {
        // Default implementation: check if a custom signer is set
        address customSigner = ERC1271Storage.layout().signer;
        if (customSigner != address(0)) {
            return customSigner;
        }

        // Fallback to the diamond contract itself (for multisig/smart wallet scenarios)
        return address(this);
    }

    /**
     * @dev Sets a custom signer address for signature validation
     * @param signer The address that will be used for signature validation
     */
    function _setSigner(address signer) internal virtual {
        ERC1271Storage.layout().signer = signer;
    }
}
