// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// libraries
import {AddressToUint256Map, Uint256ToAddressMap} from "./HashMap.sol";

/// @notice Minimal storage layout for an ERC721 token
/// @dev Do not modify the layout of this struct especially if it's nested in another struct
/// or used in a linear storage layout
struct MinimalERC721Storage {
    // Mapping owner address to token count
    AddressToUint256Map balances;
    // Mapping from token ID to owner address
    Uint256ToAddressMap owners;
    // Mapping from token ID to approved address
    Uint256ToAddressMap tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) operatorApprovals;
    // Total supply of tokens
    uint256 totalSupply;
}

/// @notice Library implementing ERC721 logic with flexible storage slot
/// @dev Do not modify the layout of this struct especially if it's nested in another struct
/// or used in a linear storage layout
library ERC721Lib {
    function balanceOf(
        MinimalERC721Storage storage self,
        address account
    )
        internal
        view
        returns (uint256)
    {
        if (account == address(0)) {
            revert IERC721Errors.ERC721InvalidOwner(address(0));
        }
        return self.balances.get(account);
    }

    function ownerOf(
        MinimalERC721Storage storage self,
        uint256 tokenId
    )
        internal
        view
        returns (address owner)
    {
        owner = self.owners.get(tokenId);
        if (owner == address(0)) {
            revert IERC721Errors.ERC721NonexistentToken(tokenId);
        }
    }

    function safeTransferFrom(
        MinimalERC721Storage storage self,
        address from,
        address to,
        uint256 tokenId
    )
        internal
    {
        _transfer(self, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, "");
    }

    function safeTransferFrom(
        MinimalERC721Storage storage self,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        internal
    {
        _transfer(self, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    function transferFrom(
        MinimalERC721Storage storage self,
        address from,
        address to,
        uint256 tokenId
    )
        internal
    {
        if (!_isApprovedOrOwner(self, msg.sender, tokenId)) {
            revert IERC721Errors.ERC721InsufficientApproval(msg.sender, tokenId);
        }
        _transfer(self, from, to, tokenId);
    }

    function approve(MinimalERC721Storage storage self, address to, uint256 tokenId) internal {
        address owner = ownerOf(self, tokenId);
        if (to == owner) {
            revert IERC721Errors.ERC721InvalidOperator(owner);
        }

        if (msg.sender != owner && !isApprovedForAll(self, owner, msg.sender)) {
            revert IERC721Errors.ERC721InvalidApprover(msg.sender);
        }

        self.tokenApprovals.set(tokenId, to);
        emit IERC721.Approval(owner, to, tokenId);
    }

    function getApproved(
        MinimalERC721Storage storage self,
        uint256 tokenId
    )
        internal
        view
        returns (address)
    {
        requireMinted(self, tokenId);
        return self.tokenApprovals.get(tokenId);
    }

    function setApprovalForAll(
        MinimalERC721Storage storage self,
        address operator,
        bool approved
    )
        internal
    {
        if (msg.sender == operator) {
            revert IERC721Errors.ERC721InvalidOperator(operator);
        }
        self.operatorApprovals[msg.sender][operator] = approved;
        emit IERC721.ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        MinimalERC721Storage storage self,
        address owner,
        address operator
    )
        internal
        view
        returns (bool)
    {
        return self.operatorApprovals[owner][operator];
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           INTERNAL                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function mint(MinimalERC721Storage storage self, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert IERC721Errors.ERC721InvalidReceiver(address(0));
        }

        // Increment total supply
        unchecked {
            self.totalSupply += 1;
        }

        // Overflow impossible since balances cannot be greater than max tokens
        _increaseBalance(self, to);
        self.owners.set(tokenId, to);

        emit IERC721.Transfer(address(0), to, tokenId);
    }

    function burn(MinimalERC721Storage storage self, uint256 tokenId) internal {
        address owner = ownerOf(self, tokenId);

        // Clear approvals
        self.tokenApprovals.set(tokenId, address(0));

        // Decrement total supply
        unchecked {
            self.totalSupply -= 1;
        }

        // Underflow impossible since balance is always >= 1
        _deductBalance(self, owner);
        self.owners.set(tokenId, address(0));

        emit IERC721.Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        MinimalERC721Storage storage self,
        address from,
        address to,
        uint256 tokenId
    )
        internal
    {
        if (ownerOf(self, tokenId) != from) {
            revert IERC721Errors.ERC721IncorrectOwner(from, tokenId, ownerOf(self, tokenId));
        }

        if (to == address(0)) {
            revert IERC721Errors.ERC721InvalidReceiver(address(0));
        }

        // Clear approvals
        self.tokenApprovals.set(tokenId, address(0));

        _update(self, from, to);

        self.owners.set(tokenId, to);

        emit IERC721.Transfer(from, to, tokenId);
    }

    function _update(MinimalERC721Storage storage self, address from, address to) internal {
        _deductBalance(self, from);
        _increaseBalance(self, to);
    }

    function _deductBalance(MinimalERC721Storage storage self, address from) private {
        uint256 fromSlot = self.balances.slot(from);
        uint256 fromBalance;
        assembly {
            fromBalance := sload(fromSlot)
            // Overflow not possible: value <= fromBalance <= totalSupply.
            sstore(fromSlot, sub(fromBalance, 1))
        }
    }

    function _increaseBalance(MinimalERC721Storage storage self, address to) private {
        uint256 toSlot = self.balances.slot(to);
        uint256 toBalance;
        assembly {
            toBalance := sload(toSlot)
            // Overflow not possible: value <= toBalance <= totalSupply.
            sstore(toSlot, add(toBalance, 1))
        }
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        private
    {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (
                bytes4 retval
            ) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function _isApprovedOrOwner(
        MinimalERC721Storage storage self,
        address spender,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(self, tokenId);
        return (
            spender == owner || isApprovedForAll(self, owner, spender)
                || getApproved(self, tokenId) == spender
        );
    }

    function requireMinted(MinimalERC721Storage storage self, uint256 tokenId) internal view {
        if (self.owners.get(tokenId) == address(0)) {
            revert IERC721Errors.ERC721NonexistentToken(tokenId);
        }
    }
}
