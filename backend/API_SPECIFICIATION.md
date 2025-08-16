# Backend API Specification for DEX Smart Contract Integration

## 1. Overview

This backend provides an API layer between the DEX frontend and on-chain smart contracts.
It will:

* Allow **adding/removing liquidity**, **swaps**, and **quotes**.
* Fetch **pool stats** from the blockchain.
* Listen to **FeesCollected events** for UI updates.
* Support **multiple chains** (Ethereum, Arbitrum, etc.).

**Tech Stack:**

* **Framework:** FastAPI (Python 3.10+)
* **Blockchain Integration:** Web3.py (async)
* **Event Handling:** Async background tasks or WebSocket streaming
* **Transport:** HTTP for API + optional WebSocket for events

---

## 2. Environment & Config

### Environment Variables

```
INFURA_API_KEY=
ALCHEMY_API_KEY=
ETH_RPC_URL=https://mainnet.infura.io/v3/${INFURA_API_KEY}
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
CONTRACT_ADDRESS_ETHEREUM=0x...
CONTRACT_ADDRESS_ARBITRUM=0x...
```

### Chain Config

`config/chains.py`:

```python
CHAIN_CONFIG = {
    "ethereum": {
        "chainId": 1,
        "rpc_url": "https://mainnet.infura.io/v3/YOUR_KEY"
    },
    "arbitrum": {
        "chainId": 42161,
        "rpc_url": "https://arb1.arbitrum.io/rpc"
    }
}

CONTRACT_ADDRESSES = {
    "ethereum": "0xYourEthereumContract",
    "arbitrum": "0xYourArbitrumContract"
}
```

---

## 3. API Endpoints

### 3.1 Add Liquidity

**POST** `/liquidity/add`
**Description:** Adds liquidity to the pool.
**Request:**

```json
{
  "chain": "ethereum",
  "amounts": ["1000000000000000000", "2000000000000000000"],
  "capital": "3000000000000000000",
  "depegTolerance": "500",
  "feeBps": "30",
  "walletAddress": "0xUserWallet"
}
```

**Response:**

```json
{
  "tickId": "12345",
  "kValue": "1000000000000",
  "radius": "500",
  "amounts": ["1000000000000000000", "2000000000000000000"],
  "fees": ["0", "0"]
}
```

---

### 3.2 Remove Liquidity

**POST** `/liquidity/remove`
**Request:**

```json
{
  "chain": "arbitrum",
  "tickId": "12345",
  "walletAddress": "0xUserWallet"
}
```

**Response:**

```json
{
  "amounts": ["1000000000000000000", "2000000000000000000"],
  "fees": ["10000000000000000", "5000000000000000"]
}
```

---

### 3.3 Get Pool Stats

**GET** `/pool/stats?chain=ethereum`
**Response:**

```json
{
  "tokenSymbols": ["USDC", "USDT", "DAI"],
  "totalTicks": 20,
  "interiorTicks": 10,
  "boundaryTicks": 10,
  "totalReserves": ["100000000000000000000", "50000000000000000000", "75000000000000000000"],
  "totalLiquidity": "225000000000000000000"
}
```

---

### 3.4 Get Quote

**GET** `/quote?chain=arbitrum&tokenInIndex=0&tokenOutIndex=1&amountIn=1000000000000000000`
**Response:**

```json
{
  "amountOut": "995000000000000000"
}
```

---

### 3.5 Swap

**POST** `/swap`
**Request:**

```json
{
  "chain": "arbitrum",
  "tokenIn": "0xTokenIn",
  "tokenOut": "0xTokenOut",
  "amountIn": "1000000000000000000",
  "minAmountOut": "995000000000000000",
  "deadline": 1692548800,
  "walletAddress": "0xUserWallet"
}
```

**Response:**

```json
{
  "inputAmountGross": "1000000000000000000",
  "inputAmountNet": "999000000000000000",
  "outputAmount": "995000000000000000",
  "effectivePrice": "1005025",
  "segments": 1,
  "success": true,
  "message": "Swap successful"
}
```

---

### 3.6 Fees Collected Event

* **WebSocket:** `/ws/fees` → pushes real-time events.
* **Polling:** `GET /fees?chain=ethereum&walletAddress=0xUserWallet`

Example Event Payload:

```json
{
  "tickId": "12345",
  "fees": ["10000000000000000", "5000000000000000"],
  "timestamp": 1692548800
}
```

---

## 4. Event Handling

* Use **Web3.py async filters** for each chain:

  * Ethereum listener.
  * Arbitrum listener.
* Implement background tasks on `FastAPI startup`:

```python
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(listen_events("ethereum"))
    asyncio.create_task(listen_events("arbitrum"))
```

---

## 5. Folder Structure

```
backend/
├── main.py
├── config/
│   ├── chains.py
│   ├── contracts.py
├── routers/
│   ├── liquidity.py
│   ├── swap.py
│   ├── pool.py
│   ├── quote.py
│   ├── events.py
├── services/
│   ├── web3_service.py
│   ├── contract_service.py
│   ├── event_service.py
```

---

## 6. Security Notes

* **No private keys on backend** (frontend signs transactions via MetaMask/WalletConnect).
* Backend only builds transaction payloads and returns `data` for client-side signing.
* Optionally implement **gas estimation** and **transaction simulation**.
