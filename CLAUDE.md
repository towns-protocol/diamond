# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Solidity smart contract project implementing the EIP-2535 Diamond Standard. It provides a comprehensive toolkit for building modular, upgradeable smart contracts that can bypass the 24KB contract size limit.

## Development Commands
```bash
# Build contracts
bun build

# Run tests
bun test

# Run a specific test
forge test --match-test testFunctionName

# Run tests with gas report
forge test --gas-report

# Format code
bun fmt:fix

# Check formatting
bun fmt

# Deploy a single facet
CONTRACT_NAME=MyFacet forge script DeployFacet

# Run any script
forge script scripts/path/to/Script.s.sol --rpc-url $RPC_URL
```

## Architecture

### Diamond Pattern Structure
- **Diamond.sol**: Main proxy contract that delegates calls to facets
- **Facets**: Modular contracts containing specific functionality
  - DiamondCutFacet: Manages adding/replacing/removing facets
  - DiamondLoupeFacet: Introspection capabilities
  - OwnableFacet: Access control
  - Token facets: ERC20, ERC721, ERC6909 implementations
- **Storage**: Uses diamond storage pattern with specific storage slots for each facet
- **Primitives**: Gas-optimized data structures (HashMap, AllowanceMap)

### Key Patterns
1. **Diamond Storage**: Each facet uses a unique storage slot to avoid collisions
   ```solidity
   bytes32 constant STORAGE_SLOT = keccak256("namespace.storage");
   ```

2. **Facet Deployment**: Use DeployFacet script for deterministic CREATE2 deployments

3. **Initialization**: Facets use initializer functions called during diamondCut operations

### Testing Approach
- Tests located in `test/` directory
- Use Foundry's forge test framework
- Test files end with `.t.sol`
- Integration tests test full diamond functionality
- Unit tests for individual facets and primitives

### Code Style
- Solidity 0.8.29
- 100 character line limit
- Double quotes for strings
- Imports sorted alphabetically
- Optimizer set to maximum runs (4294967295) for deployment gas optimization