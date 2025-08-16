from web3 import Web3
import os

# Connect to the Ethereum network
provider_url = "https://testnet.evm.nodes.onflow.org"
web3 = Web3(Web3.HTTPProvider(provider_url))

# Check if connected
if not web3.is_connected():
    print("Failed to connect to the Ethereum network")
    exit()

# Contract details
## Contract Code is in onchain/src/OrbitalPool.sol
## Contract Abi is in onchain/abi/OrbitalPool.json
orbital_pool_address = "0x274725cdEEC749D4E97DC990de45a5Bba76F80C3"  # Replace with your contract address
orbital_pool_abi = [
    {
        "inputs": [
            {"internalType": "uint256[]", "name": "amounts", "type": "uint256[]"},
            {"internalType": "uint256", "name": "capital", "type": "uint256"},
            {"internalType": "uint256", "name": "depegTolerance", "type": "uint256"},
            {"internalType": "uint256", "name": "feeBps", "type": "uint256"}
        ],
        "name": "addLiquidity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]

# Create contract instance
orbital_pool = web3.eth.contract(address=orbital_pool_address, abi=orbital_pool_abi)

# Set up transaction details
account_address = "0xDb25832bA515FD47c6F673eBD98107cdD7632910"  # Replace with your account address
private_key = os.getenv("PRIVATE_KEY")  # Ensure your private key is set in the environment

# Function parameters
amounts = [1000, 2000, 3000]
capital = 5000
depeg_tolerance = 100
fee_bps = 10

# Build transaction
transaction = orbital_pool.functions.addLiquidity(amounts, capital, depeg_tolerance, fee_bps).build_transaction({
    'from': account_address,
    'nonce': web3.eth.get_transaction_count(account_address),
    'gas': 2000000,
    'gasPrice': web3.to_wei('50', 'gwei')
})

# Sign transaction
signed_txn = web3.eth.account.sign_transaction(transaction, private_key=private_key)

# Send transaction
tx_hash = web3.eth.send_raw_transaction(signed_txn.raw_transaction)

# Wait for transaction receipt
tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

print(f"Transaction successful with hash: {tx_receipt.transactionHash.hex()}")