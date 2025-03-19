// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

// interfaces
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

// libraries
import {EIP712Storage} from "./EIP712Storage.sol";

// contracts
import {EIP712Base} from "./EIP712Base.sol";
import {Nonces} from "../Nonces.sol";
import {Facet} from "../../facets/Facet.sol";

contract EIP712Facet is IERC5267, EIP712Base, Nonces, Facet {
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
  ) external onlyInitializing {
    __EIP712_init_unchained(name, version);
  }

  function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
    return _domainSeparatorV4();
  }

  function nonces(address owner) external view returns (uint256) {
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
    EIP712Storage.Layout storage dl = EIP712Storage.layout();

    // If the hashed name and version in storage are non-zero, the contract hasn't been properly initialized
    // and the EIP712 domain is not reliable, as it will be missing name and version.
    require(
      dl.hashedName == 0 && dl.hashedVersion == 0,
      "EIP712: Uninitialized"
    );

    return (
      hex"0f", // 01111
      _EIP712Name(),
      _EIP712Version(),
      block.chainid,
      address(this),
      bytes32(0),
      new uint256[](0)
    );
  }
}
