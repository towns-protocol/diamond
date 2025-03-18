# Diamond Standard Implementation

An efficient, modular, and upgradeable implementation of the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535) for Ethereum smart contracts.

## Overview

This repository provides a robust foundation for building modular and upgradeable smart contract systems using the Diamond pattern. The Diamond pattern allows for:

- **Unlimited Contract Size**: Bypass the 24KB contract size limit
- **Modular Design**: Split functionality into logical components (facets)
- **Upgradability**: Add, replace, or remove functionality without disrupting state
- **Gas Efficiency**: Optimize for lower deployment and execution costs

## Architecture

The implementation consists of:

- **Diamond Contract**: The main entry point that delegates calls to facets
- **Facets**: Individual contracts containing specific functionality
- **Storage**: Shared storage patterns for all facets
- **Loupe Functions**: Methods to inspect the diamond's structure

### Core Facets

- **DiamondCut**: Handles adding, replacing, and removing facets
- **DiamondLoupe**: Provides introspection into the diamond's structure
- **Ownership**: Manages access control for diamond operations
- **Pausable**: Allows pausing functionality in emergency situations
- **Initializable**: Manages initialization process for facets
- **Reentrancy**: Protection against reentrancy attacks

### Token Standards

This implementation includes optimized facets for various token standards:

- **ERC20**: Standard fungible token implementation
- **ERC721**: Standard non-fungible token implementation
- **ERC6909**: Minimal multi-token interface for managing multiple tokens in a single contract

### Primitives

The implementation uses custom low-level primitives to maximize gas efficiency:

- **HashMap**: Efficient key-value storage implementations (Address-to-Uint256, Uint256-to-Address)
- **AllowanceMap**: Optimized double mapping for token allowances
- **ERC20/ERC721/ERC6909 Primitives**: Core token implementations designed for Diamond pattern integration

## Development

This project uses [Foundry](https://book.getfoundry.sh/) for development, testing, and deployment.

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Bun](https://bun.sh/) for JavaScript package management

### Installation

```bash
# Clone the repository
git clone https://github.com/towns-protocol/diamond.git
cd diamond

# Install dependencies
bun install
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Format

```bash
bun prettier:fix
forge fmt
```

## License

MIT

## Acknowledgements

This implementation is inspired by the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535) and builds upon best practices from the community.
