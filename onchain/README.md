### LP Provides 3 parameters 
## capital #USD value they want to invest
## depeg_tolerance # # Minimum acceptable token price (e.g., $0.98)
## Fee rate they want to earn

## Our system will calculate ev
radius = capital * base_rate
k = DepegConversion.price_to_k(depeg_tolerance, radius, n)
initial_reserves = EqualPriceGeometry.equal_price_point(radius, n)



## Deployment Process
## 1. Deploy all the contracts in the libraries
forge create --broadcast src/libraries/Math.sol:Math \
     --rpc-url https://testnet.evm.nodes.onflow.org \
     --private-key $DEPLOYER_PRIVATE_KEY \
     --legacy
Deployer: 0xDb25832bA515FD47c6F673eBD98107cdD7632910
Deployed to: 0xa8F0820cbb0c03feFC9912c3527a3Ec887aBC3b2
Transaction hash: 0x8891ca4dc2a7ee9781ca4942df185ecd1edccb91c7ce141dfb77bcf246818720
### 2. OrbitalCoreMath.sol
forge create \
  --broadcast \
  --libraries "contracts/utils/math/Math.sol:Math:0xa8f0820cbb0c03fefc9912c3527a3ec887abc3b2" \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --private-key $DEPLOYER_PRIVATE_KEY \
  src/libraries/OrbitalCoreMath.sol:OrbitalCoreMath
  
No files changed, compilation skipped
Deployer: 0xDb25832bA515FD47c6F673eBD98107cdD7632910
Deployed to: 0xC6A8a3c9Cd34aeA22E8F591ac12e3c7e8Ca4cB69
Transaction hash: 0x64585e16a43fe390eabab1f6eae3c93a71d9c8e87ae25cf52d4f06a69bb2f404
### 3. OrbitalTypes.sol
forge create \
  --broadcast \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --private-key $DEPLOYER_PRIVATE_KEY \
  src/libraries/OrbitalTypes.sol:OrbitalTypes
Deployer: 0xDb25832bA515FD47c6F673eBD98107cdD7632910
Deployed to: 0xC9B7d2D8Cd6A6E9d784371E1e72cE4CAF0DA0628
Transaction hash: 0xf68b20164ba8cbe17b24de87ed022e7f406b5b995cd43f3f7f99bba873c5e3aa


### Need to deploy some tokens first

forge create \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  src/stablecoins/USDC.sol:USDC \
  --constructor-args 100000000
Deployed to: 0xE103Bb1b2E2dd1c5eD7b9B2D84f78Eb4B004cF7a
Transaction hash: 0xf6fcc8ef21bfc8a64961123335ec0369ec72af5c271b5a1a7d12443bc5d7d7f3

forge create \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  src/stablecoins/PYUSD.sol:PYUSD \
  --constructor-args 100000000
Deployed to: 0x9857E9b660221cED694dEAC6679Cdb0bEAedFF6F
Transaction hash: 0xa8886fa6be2c8fd1e983a1a89ef419c57cc50d96f2646ef8d2a9d54ee72bc8b1
4.IOrbitalPool.sol [Interfacedon't need to be deployed]

### 
forge script script/DeployOrbitalPool.s.sol --rpc-url https://testnet.evm.nodes.onflow.org --broadcast --private-key $DEPLOYER_PRIVATE_KEY
##### 545
✅  [Success] Hash: 0xa4cdc369e21e90c2052b3d8f43af38e7ce13d68dd4699564c68f32b36d01d080
Contract Address: 0x274725cdEEC749D4E97DC990de45a5Bba76F80C3
Block: 63491022
Paid: 0.0000000003168173 ETH (3168173 gas * 0.0000001 gwei)

✅ Sequence #1 on 545 | Total Paid: 0.0000000003168173 ETH (3168173 gas * avg 0.0000001 gwei)



    ### Verify the contract
    forge verify-contract --rpc-url https://testnet.evm.nodes.onflow.org/ \
    --verifier blockscout \
    --verifier-url https://evm-testnet.flowscan.io/api \
    0x274725cdEEC749D4E97DC990de45a5Bba76F80C3 \
    src/OrbitalPool.sol:OrbitalPool        

### 
cast call 0x274725cdEEC749D4E97DC990de45a5Bba76F80C3 \
    --rpc-url https://testnet.evm.nodes.onflow.org \
    "getPoolStats()" \
    $DEPLOYER_ADDRESS

### 5. 

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
