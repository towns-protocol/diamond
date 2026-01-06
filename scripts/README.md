# DeployFacet

A powerful deployment script that optimizes contract deployments using deterministic CREATE2 addresses and batch operations.

## Prerequisites

- **CREATE2 Factory**: The deployment uses the standard [deterministic-deployment-proxy](https://github.com/Arachnid/deterministic-deployment-proxy) at `0x4e59b44847b379578588920cA78FbF26c0B4956C`
- **Multicall3**: The batch deployment functionality requires [Multicall3](https://www.multicall3.com) to be deployed at `0xcA11bde05977b3631167028862bE2a173976CA11`

Both contracts must be deployed on the target chain for the full functionality to work.

## Features

- **Deterministic Addresses**: Predict contract addresses before deployment
- **Batch Deployments**: Deploy multiple contracts in single transactions
- **Gas Estimation**: Accurately estimates gas costs with built-in safeguards
- **Deployment Verification**: Easily check if contracts are deployed

## Usage

### Single Facet Deployment

Deploy a single facet using environment variables:

```bash
CONTRACT_NAME=MyFacet forge script DeployFacet
```

The script will automatically load the contract from the artifacts directory, deploy it, and return the deployed address.

### Batch Deployment

```solidity
// Add contracts to deployment queue
deployFacet.add("MyContract");
deployFacet.add("AnotherContract", bytes32(uint256(1))); // with custom salt

// Deploy the batch
deployFacet.deployBatch(deployer);
```

### Address Prediction

You can predict deployment addresses before actually deploying:

```solidity
// Predict address with default salt (0)
address predictedAddress = deployFacet.predictAddress("MyContract");

// Predict address with custom salt
address predictedAddress = deployFacet.predictAddress("MyContract", bytes32(uint256(1)));
```

### Deployment Verification

```solidity
// Check if deployed
bool isDeployed = deployFacet.isDeployed("MyContract");

// Get deployed address (returns address(0) if not deployed)
address contractAddress = deployFacet.getDeployedAddress("MyContract");
```

## Gas Estimation

The script uses a comprehensive gas estimation model that considers:

- Base transaction costs (21,000 gas)
- Contract creation costs (32,000 gas)
- Deployed bytecode costs (200 gas per byte)
- Storage variable costs (22,100 gas)

This ensures accurate gas estimates for both single and batch deployments. Batches are automatically split when approaching per-transaction gas limits, and contracts exceeding the limit are blocked at queue time.
