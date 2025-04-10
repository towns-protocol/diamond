// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC20PermitBase} from "./IERC20PermitBase.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

// libraries
import {ERC20Storage} from "../ERC20Storage.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";

// contracts
import {Nonces} from "../../../../utils/Nonces.sol";
import {EIP712Base} from "../../../../utils/cryptography/EIP712Base.sol";
import {ERC20} from "../ERC20.sol";

abstract contract ERC20PermitBase is IERC20PermitBase, IERC20Permit, ERC20, EIP712Base, Nonces {
    /// @dev `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
    bytes32 private constant _PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    function __ERC20PermitBase_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    )
        external
        virtual
        onlyInitializing
    {
        __ERC20_init_unchained(name_, symbol_, decimals_);
        __ERC20PermitBase_init_unchained(name_);
    }

    function __ERC20PermitBase_init_unchained(string memory name_) internal virtual {
        __EIP712_init_unchained(name_, "1");
    }

    /// @inheritdoc IERC20Permit
    function nonces(address owner) external view virtual returns (uint256 result) {
        return _latestNonce(owner);
    }

    /// @inheritdoc IERC20Permit
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        virtual
    {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, amount, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        ERC20Storage.layout().inner._approve(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }

    /// @inheritdoc IERC20Permit
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32 result) {
        return _domainSeparatorV4();
    }
}
