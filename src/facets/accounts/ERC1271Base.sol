// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces

// libraries
import {ERC1271Storage} from "./ERC1271Storage.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {SignatureCheckerLib} from "solady/utils/SignatureCheckerLib.sol";

// contracts
import {EIP712Base} from "../../utils/cryptography/EIP712Base.sol";

abstract contract ERC1271Base is EIP712Base {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    /// @dev `keccak256("PersonalSign(bytes prefixed)")`.
    bytes32 internal constant _PERSONAL_SIGN_TYPEHASH =
        0x983e65e5148e570cd828ead231ee759a8d7958721a768f93bc4483ba005c32de;

    /**
     * @dev Returns the ERC1271 signer.
     * Override to return the signer `isValidSignature` checks against.
     */
    function _erc1271Signer() internal view virtual returns (address) {
        // Default implementation: check if a custom signer is set
        address customSigner = ERC1271Storage.layout().signer;
        if (customSigner != address(0)) return customSigner;

        // Fallback to the diamond contract itself (for multisig/smart wallet scenarios)
        return address(this);
    }

    /**
     * @dev Returns whether the `msg.sender` is considered safe, such
     * that we don't need to use the nested EIP-712 workflow.
     * Override to return true for more callers.
     * See: https://mirror.xyz/curiousapple.eth/pFqAdW2LiJ-6S4sg_u1z08k4vK6BCJ33LcyXpnNb8yU
     */
    function _erc1271CallerIsSafe() internal view virtual returns (bool) {
        // The canonical `MulticallerWithSigner` at 0x000000000000D9ECebf3C23529de49815Dac1c4c
        // is known to include the account in the hash to be signed.
        return msg.sender == 0x000000000000D9ECebf3C23529de49815Dac1c4c;
    }

    /**
     * @dev Returns whether the `hash` and `signature` are valid.
     * Override if you need non-ECDSA logic.
     */
    function _erc1271IsValidSignatureNowCalldata(
        bytes32 hash,
        bytes calldata signature
    )
        internal
        view
        virtual
        returns (bool)
    {
        return SignatureCheckerLib.isValidSignatureNowCalldata(_erc1271Signer(), hash, signature);
    }

    /**
     * @dev Unwraps and returns the signature.
     */
    function _erc1271UnwrapSignature(bytes calldata signature)
        internal
        view
        virtual
        returns (bytes calldata result)
    {
        result = signature;
        /// @solidity memory-safe-assembly
        assembly {
            // Unwraps the ERC6492 wrapper if it exists.
            // See: https://eips.ethereum.org/EIPS/eip-6492
            if eq(
                calldataload(add(result.offset, sub(result.length, 0x20))),
                mul(0x6492, div(not(shr(address(), address())), 0xffff)) // `0x6492...6492`.
            ) {
                let o := add(result.offset, calldataload(add(result.offset, 0x40)))
                result.length := calldataload(o)
                result.offset := add(o, 0x20)
            }
        }
    }

    /**
     * @dev Validates the signature with ERC1271 return,
     * so that this account can also be used as a signer.
     */
    function _isValidSignature(
        bytes32 hash,
        bytes calldata signature
    )
        internal
        view
        virtual
        returns (bytes4 result)
    {
        // For automatic detection that the smart account supports the nested EIP-712 workflow,
        // See: https://eips.ethereum.org/EIPS/eip-7739.
        // If `hash` is `0x7739...7739`, returns `bytes4(0x77390001)`.
        // The returned number MAY be increased in future ERC7739 versions.
        unchecked {
            if (signature.length == uint256(0)) {
                // Forces the compiler to optimize for smaller bytecode size.
                if (uint256(hash) == (~signature.length / 0xffff) * 0x7739) {
                    return 0x77390001;
                }
            }
        }
        bool success = _erc1271IsValidSignatureInternal(hash, _erc1271UnwrapSignature(signature));
        /// @solidity memory-safe-assembly
        assembly {
            // `success ? bytes4(keccak256("isValidSignature(bytes32,bytes)")) : 0xffffffff`.
            // We use `0xffffffff` for invalid, in convention with the reference implementation.
            result := shl(224, or(0x1626ba7e, sub(0, iszero(success))))
        }
    }

    /**
     * @dev Returns whether the `signature` is valid for the `hash.
     */
    function _erc1271IsValidSignatureInternal(
        bytes32 hash,
        bytes calldata signature
    )
        internal
        view
        virtual
        returns (bool)
    {
        return _erc1271IsValidSignatureViaSafeCaller(hash, signature)
            || _erc1271IsValidSignatureViaNestedEIP712(hash, signature)
            || _erc1271IsValidSignatureViaRPC(hash, signature);
    }

    /**
     * @dev Performs the signature validation without nested EIP-712 if the caller is
     * a safe caller. A safe caller must include the address of this account in the hash.
     */
    function _erc1271IsValidSignatureViaSafeCaller(
        bytes32 hash,
        bytes calldata signature
    )
        internal
        view
        virtual
        returns (bool result)
    {
        if (_erc1271CallerIsSafe()) {
            result = _erc1271IsValidSignatureNowCalldata(hash, signature);
        }
    }

    /**
     * @dev ERC1271 signature validation (Nested EIP-712 workflow).
     *
     * This uses ECDSA recovery by default (see: `_erc1271IsValidSignatureNowCalldata`).
     * It also uses a nested EIP-712 approach to prevent signature replays when a single EOA
     * owns multiple smart contract accounts,
     * while still enabling wallet UIs (e.g. Metamask) to show the EIP-712 values.
     *
     * Crafted for phishing resistance, efficiency, flexibility.
     */
    function _erc1271IsValidSignatureViaNestedEIP712(
        bytes32 hash,
        bytes calldata signature
    )
        internal
        view
        virtual
        returns (bool result)
    {
        uint256 t = uint256(uint160(address(this)));
        // Forces the compiler to pop the variables after the scope, avoiding stack-too-deep.
        if (t != uint256(0)) {
            // Use inherited EIP712Base methods instead of external call
            string memory name = _EIP712Name();
            string memory version = _EIP712Version();
            uint256 chainId = block.chainid;
            address verifyingContract = address(this);
            bytes32 salt = bytes32(0); // Default salt value

            // Continue with nested EIP712 workflow
            /// @solidity memory-safe-assembly
            assembly {
                t := mload(0x40) // Grab the free memory pointer.
                // Skip 2 words for the `typedDataSignTypehash` and `contents` struct hash.
                mstore(add(t, 0x40), keccak256(add(name, 0x20), mload(name)))
                mstore(add(t, 0x60), keccak256(add(version, 0x20), mload(version)))
                mstore(add(t, 0x80), chainId)
                mstore(add(t, 0xa0), shr(96, shl(96, verifyingContract)))
                mstore(add(t, 0xc0), salt)
                mstore(0x40, add(t, 0xe0)) // Allocate the memory.
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            // `c` is `contentsDescription.length`, which is stored in the last 2 bytes of the signature.
            let c := shr(240, calldataload(add(signature.offset, sub(signature.length, 2))))
            for {} 1 {} {
                let l := add(0x42, c) // Total length of appended data (32 + 32 + c + 2).
                let o := add(signature.offset, sub(signature.length, l)) // Offset of appended data.
                mstore(0x00, 0x1901) // Store the "\x19\x01" prefix.
                calldatacopy(0x20, o, 0x40) // Copy the `APP_DOMAIN_SEPARATOR` and `contents` struct hash.
                // Use the `PersonalSign` workflow if the reconstructed hash doesn't match,
                // or if the appended data is invalid, i.e.
                // `appendedData.length > signature.length || contentsDescription.length == 0`.
                if or(xor(keccak256(0x1e, 0x42), hash), or(lt(signature.length, l), iszero(c))) {
                    t := 0 // Set `t` to 0, denoting that we need to `hash = _hashTypedData(hash)`.
                    mstore(t, _PERSONAL_SIGN_TYPEHASH)
                    mstore(0x20, hash) // Store the `prefixed`.
                    hash := keccak256(t, 0x40) // Compute the `PersonalSign` struct hash.
                    break
                }
                // Else, use the `TypedDataSign` workflow.
                // `TypedDataSign({ContentsName} contents,string name,...){ContentsType}`.
                mstore(m, "TypedDataSign(") // Store the start of `TypedDataSign`'s type encoding.
                let p := add(m, 0x0e) // Advance 14 bytes to skip "TypedDataSign(".
                calldatacopy(p, add(o, 0x40), c) // Copy `contentsName`, optimistically.
                mstore(add(p, c), 40) // Store a '(' after the end.
                if iszero(eq(byte(0, mload(sub(add(p, c), 1))), 41)) {
                    let e := 0 // Length of `contentsName` in explicit mode.
                    for { let q := sub(add(p, c), 1) } 1 {} {
                        e := add(e, 1) // Scan backwards until we encounter a ')'.
                        if iszero(gt(lt(e, c), eq(byte(0, mload(sub(q, e))), 41))) { break }
                    }
                    c := sub(c, e) // Truncate `contentsDescription` to `contentsType`.
                    calldatacopy(p, add(add(o, 0x40), c), e) // Copy `contentsName`.
                    mstore8(add(p, e), 40) // Store a '(' exactly right after the end.
                }
                // `d & 1 == 1` means that `contentsName` is invalid.
                let d := shr(byte(0, mload(p)), 0x7fffffe000000000000010000000000) // Starts with `[a-z(]`.
                // Advance `p` until we encounter '('.
                for {} iszero(eq(byte(0, mload(p)), 40)) { p := add(p, 1) } {
                    d := or(shr(byte(0, mload(p)), 0x120100000001), d) // Has a byte in ", )\x00".
                }
                mstore(p, " contents,string name,string") // Store the rest of the encoding.
                mstore(add(p, 0x1c), " version,uint256 chainId,address")
                mstore(add(p, 0x3c), " verifyingContract,bytes32 salt)")
                p := add(p, 0x5c)
                calldatacopy(p, add(o, 0x40), c) // Copy `contentsType`.
                // Fill in the missing fields of the `TypedDataSign`.
                calldatacopy(t, o, 0x40) // Copy the `contents` struct hash to `add(t, 0x20)`.
                mstore(t, keccak256(m, sub(add(p, c), m))) // Store `typedDataSignTypehash`.
                // The "\x19\x01" prefix is already at 0x00.
                // `APP_DOMAIN_SEPARATOR` is already at 0x20.
                mstore(0x40, keccak256(t, 0xe0)) // `hashStruct(typedDataSign)`.
                // Compute the final hash, corrupted if `contentsName` is invalid.
                hash := keccak256(0x1e, add(0x42, and(1, d)))
                signature.length := sub(signature.length, l) // Truncate the signature.
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
        if (t == uint256(0)) hash = _hashTypedDataV4(hash); // `PersonalSign` workflow.
        result = _erc1271IsValidSignatureNowCalldata(hash, signature);
    }

    /**
     * @dev Performs the signature validation without nested EIP-712 to allow for easy sign ins.
     * This function must always return false or revert if called on-chain.
     * For testing environments, we simplify this to avoid gas burning issues.
     */
    function _erc1271IsValidSignatureViaRPC(
        bytes32 hash,
        bytes calldata signature
    )
        internal
        view
        virtual
        returns (bool result)
    {
        // Non-zero gasprice is a heuristic to check if a call is on-chain,
        // but we can't fully depend on it because it can be manipulated.
        // See: https://x.com/NoahCitron/status/1580359718341484544
        if (tx.gasprice == uint256(0)) {
            /// @solidity memory-safe-assembly
            assembly {
                mstore(gasprice(), gasprice())
                // See: https://gist.github.com/Vectorized/3c9b63524d57492b265454f62d895f71
                let b := 0x000000000000378eDCD5B5B0A24f5342d8C10485 // Basefee contract,

                // Check if the basefee contract exists before calling it
                let codeSize := extcodesize(b)
                if codeSize {
                    pop(staticcall(0xffff, b, codesize(), gasprice(), gasprice(), 0x20))
                    // If `gasprice < basefee`, the call cannot be on-chain, and we can skip the gas burn.
                    if iszero(mload(gasprice())) {
                        let m := mload(0x40) // Cache the free memory pointer.
                        mstore(gasprice(), 0x1626ba7e) // `isValidSignature(bytes32,bytes)`.
                        mstore(0x20, b) // Recycle `b` to denote if we need to burn gas.
                        mstore(0x40, 0x40)
                        let gasToBurn := or(add(0xffff, gaslimit()), gaslimit())
                        // Burns gas computationally efficiently. Also, requires that `gas > gasToBurn`.
                        if or(eq(hash, b), lt(gas(), gasToBurn)) { invalid() }
                        // Make a call to this with `b`, efficiently burning the gas provided.
                        // No valid transaction can consume more than the gaslimit.
                        // See: https://ethereum.github.io/yellowpaper/paper.pdf
                        // Most RPCs perform calls with a gas budget greater than the gaslimit.
                        pop(staticcall(gasToBurn, address(), 0x1c, 0x64, gasprice(), gasprice()))
                        mstore(0x40, m) // Restore the free memory pointer.
                    }
                }
            }
            result = _erc1271IsValidSignatureNowCalldata(hash, signature);
        }
    }

    /**
     * @dev Sets a custom signer address for signature validation
     * @param signer The address that will be used for signature validation
     */
    function _setSigner(address signer) internal virtual {
        ERC1271Storage.layout().signer = signer;
    }
}
