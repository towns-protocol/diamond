// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

// libraries
import {ERC20Storage} from "./ERC20Storage.sol";

// contracts
import {Facet} from "../../Facet.sol";

abstract contract ERC20 is IERC20, IERC20Metadata, Facet {
    function __ERC20_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    )
        external
        virtual
        onlyInitializing
    {
        __ERC20_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC20_init_unchained(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    )
        internal
        virtual
    {
        _addInterface(type(IERC20).interfaceId);
        _addInterface(type(IERC20Permit).interfaceId);
        _addInterface(type(IERC20Metadata).interfaceId);

        ERC20Storage.Layout storage self = ERC20Storage.layout();
        self.name = name_;
        self.symbol = symbol_;
        self.decimals = decimals_;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC20                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {
        return ERC20Storage.layout().inner.totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256) {
        return ERC20Storage.layout().inner.balanceOf(account);
    }

    /// @inheritdoc IERC20
    function allowance(
        address owner,
        address spender
    )
        public
        view
        virtual
        returns (uint256 result)
    {
        return ERC20Storage.layout().inner.allowance(owner, spender);
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        ERC20Storage.layout().inner.approve(spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        ERC20Storage.layout().inner.transfer(to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        ERC20Storage.layout().inner.transferFrom(from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IERC20Metadata
    function name() public view virtual returns (string memory) {
        return ERC20Storage.layout().name;
    }

    /// @inheritdoc IERC20Metadata
    function symbol() public view virtual returns (string memory) {
        return ERC20Storage.layout().symbol;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public view virtual returns (uint8) {
        return ERC20Storage.layout().decimals;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           MINT                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _mint(address to, uint256 amount) internal virtual {
        ERC20Storage.layout().inner.mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        ERC20Storage.layout().inner.burn(from, amount);
        emit Transfer(from, address(0), amount);
    }
}
