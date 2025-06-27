// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// interfaces

// libraries

// contracts
import {EIP712Facet} from "src/utils/cryptography/EIP712Facet.sol";

contract MockEIP712 is EIP712Facet {
    string public constant NAME = "MockEIP712";
    string public constant VERSION = "1.0";

    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = NAME;
        version = VERSION;
    }
}
