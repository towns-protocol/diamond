# Diamond Standard Implementation

[![NPM Package](https://img.shields.io/npm/v/@towns-protocol/diamond.svg)](https://www.npmjs.org/package/@towns-protocol/diamond)
[![CI Status](https://github.com/towns-protocol/diamond/workflows/CI/badge.svg)](https://github.com/towns-protocol/diamond/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Solidity Version](https://img.shields.io/badge/solidity-^0.8.29-lightgrey)](https://solidity.readthedocs.io/en/v0.8.29/)

A comprehensive toolkit for building modular smart contracts with the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535). This package provides both the core Diamond contracts and optimized building blocks to create efficient, upgradeable systems.

## Overview

This repository provides a robust foundation for building modular and upgradeable smart contract systems using the Diamond pattern. It includes not only the Diamond implementation itself but also reusable primitives and facets that serve as building blocks for your contract systems. The Diamond pattern allows for:

- **Unlimited Contract Size**: Bypass the 24KB contract size limit
- **Modular Design**: Split functionality into logical components (facets)
- **Upgradability**: Add, replace, or remove functionality without disrupting state
- **Gas Efficiency**: Optimize for lower deployment and execution costs

## Architecture

The implementation consists of:

- **Diamond Contract**: The main entry point that delegates calls to facets
- **Loupe Functions**: Methods to inspect the diamond's structure
- **Facets**: Individual contracts containing specific functionality
- **Storage**: Shared storage patterns for all facets

## Building Blocks

This toolkit provides several reusable components that can be used independently or together:

- **Storage Primitives**: Efficient data structures like HashMap and AllowanceMap for optimal gas usage
- **Token Facets**: Ready-to-use implementations of popular token standards (ERC20, ERC721, ERC6909)
- **Utility Facets**: Common utilities like ownership, pausability, and reentrancy guards

Each building block is designed to be modular, allowing you to pick and choose the components you need for your specific use case.

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

## Scripts

This repository includes deployment scripts that make it easy to work with the Diamond pattern:

### DeployFacet

Located in `scripts/common/DeployFacet.s.sol`, this script provides optimized deployment utilities for efficient contract deployment. It features:

- Deterministic deployments using CREATE2
- Batch deployment of multiple contracts
- Gas estimation with block limit safeguards
- Deployment address prediction

Example usage:

```bash
# Deploy a single facet
CONTRACT_NAME=MyFacet forge script DeployFacet

# Deploy a batch of contracts
# (See scripts/README.md for API details)
```

**Prerequisites**:

- CREATE2 Factory (`0x4e59b44847b379578588920cA78FbF26c0B4956C`)
- Multicall3 (`0xcA11bde05977b3631167028862bE2a173976CA11`)

DeployFacet handles all the complexities of gas optimization and deterministic addressing, making deployments more predictable and cost-effective.

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
forge fmt
```

## License

MIT

## Acknowledgements

This implementation is inspired by the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535) and builds upon best practices from the community.
