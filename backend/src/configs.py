from x402.chains import (
    get_chain_id,
    get_token_decimals,
    get_token_name,
    get_token_version,
    get_default_token_address,
)
from x402.types import (
    PaymentPayload,
    PaymentRequirements,
    Price,
    SupportedNetworks,
    TokenAmount,
    TokenAsset,
    EIP712Domain,
    x402PaymentRequiredResponse,
    SettleResponse,
)


class flare_configs:
    """
    Configuration for Flare network interactions.

    Note:
    The ABI is a definition of the contract's interface, which allows interaction with the smart contract on the blockchain.
    The address is to get the particular contract on the a particular network. The RPC URL is the endpoint for some network.

    To find/run a smart contract on a blockchain, you'll need the ABI (which is associated with the contract and can probably
    be found in the documentation of the contract online), the address of the contract, the url of the network and then you can
    use these to interact with the contract using a library like Web3.py (check ABI for inputs and outputs of functions).

    """

    FTSOV2_ADDRESS = "0x3d893C53D9e8056135C26C8c638B76C8b60Df726"
    # FtsoV2 address (Flare Testnet Coston2), check https://dev.flare.network/ftso/solidity-reference for prod?
    RPC_URL = "https://coston2-api.flare.network/ext/C/rpc"

    # Feed IDs for stablecoins pegged to USD
    STABLECOIN_FEED_IDS = {
        "FLR": "0x01464c522f55534400000000000000000000000000",  # FLR/USD
        "BTC": "0x014254432f55534400000000000000000000000000",  # BTC/USD
        "ETH": "0x014554482f55534400000000000000000000000000",  # ETH/USD
    }
    # ABI for FtsoV2
    ABI = [
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "_addressUpdater",
                    "type": "address",
                }
            ],
            "stateMutability": "nonpayable",
            "type": "constructor",
        },
        {
            "inputs": [],
            "name": "FTSO_PROTOCOL_ID",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "fastUpdater",
            "outputs": [
                {"internalType": "contract IFastUpdater", "name": "", "type": "address"}
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "fastUpdatesConfiguration",
            "outputs": [
                {
                    "internalType": "contract IFastUpdatesConfiguration",
                    "name": "",
                    "type": "address",
                }
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "getAddressUpdater",
            "outputs": [
                {
                    "internalType": "address",
                    "name": "_addressUpdater",
                    "type": "address",
                }
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "bytes21", "name": "_feedId", "type": "bytes21"}
            ],
            "name": "getFeedById",
            "outputs": [
                {"internalType": "uint256", "name": "", "type": "uint256"},
                {"internalType": "int8", "name": "", "type": "int8"},
                {"internalType": "uint64", "name": "", "type": "uint64"},
            ],
            "stateMutability": "payable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "bytes21", "name": "_feedId", "type": "bytes21"}
            ],
            "name": "getFeedByIdInWei",
            "outputs": [
                {"internalType": "uint256", "name": "_value", "type": "uint256"},
                {"internalType": "uint64", "name": "_timestamp", "type": "uint64"},
            ],
            "stateMutability": "payable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint256", "name": "_index", "type": "uint256"}
            ],
            "name": "getFeedByIndex",
            "outputs": [
                {"internalType": "uint256", "name": "", "type": "uint256"},
                {"internalType": "int8", "name": "", "type": "int8"},
                {"internalType": "uint64", "name": "", "type": "uint64"},
            ],
            "stateMutability": "payable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint256", "name": "_index", "type": "uint256"}
            ],
            "name": "getFeedByIndexInWei",
            "outputs": [
                {"internalType": "uint256", "name": "_value", "type": "uint256"},
                {"internalType": "uint64", "name": "_timestamp", "type": "uint64"},
            ],
            "stateMutability": "payable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint256", "name": "_index", "type": "uint256"}
            ],
            "name": "getFeedId",
            "outputs": [{"internalType": "bytes21", "name": "", "type": "bytes21"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "bytes21", "name": "_feedId", "type": "bytes21"}
            ],
            "name": "getFeedIndex",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "bytes21[]", "name": "_feedIds", "type": "bytes21[]"}
            ],
            "name": "getFeedsById",
            "outputs": [
                {"internalType": "uint256[]", "name": "", "type": "uint256[]"},
                {"internalType": "int8[]", "name": "", "type": "int8[]"},
                {"internalType": "uint64", "name": "", "type": "uint64"},
            ],
            "stateMutability": "payable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "bytes21[]", "name": "_feedIds", "type": "bytes21[]"}
            ],
            "name": "getFeedsByIdInWei",
            "outputs": [
                {"internalType": "uint256[]", "name": "_values", "type": "uint256[]"},
                {"internalType": "uint64", "name": "_timestamp", "type": "uint64"},
            ],
            "stateMutability": "payable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint256[]", "name": "_indices", "type": "uint256[]"}
            ],
            "name": "getFeedsByIndex",
            "outputs": [
                {"internalType": "uint256[]", "name": "", "type": "uint256[]"},
                {"internalType": "int8[]", "name": "", "type": "int8[]"},
                {"internalType": "uint64", "name": "", "type": "uint64"},
            ],
            "stateMutability": "payable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint256[]", "name": "_indices", "type": "uint256[]"}
            ],
            "name": "getFeedsByIndexInWei",
            "outputs": [
                {"internalType": "uint256[]", "name": "_values", "type": "uint256[]"},
                {"internalType": "uint64", "name": "_timestamp", "type": "uint64"},
            ],
            "stateMutability": "payable",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "relay",
            "outputs": [
                {"internalType": "contract IRelay", "name": "", "type": "address"}
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {
                    "internalType": "bytes32[]",
                    "name": "_contractNameHashes",
                    "type": "bytes32[]",
                },
                {
                    "internalType": "address[]",
                    "name": "_contractAddresses",
                    "type": "address[]",
                },
            ],
            "name": "updateContractAddresses",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function",
        },
        {
            "inputs": [
                {
                    "components": [
                        {
                            "internalType": "bytes32[]",
                            "name": "proof",
                            "type": "bytes32[]",
                        },
                        {
                            "components": [
                                {
                                    "internalType": "uint32",
                                    "name": "votingRoundId",
                                    "type": "uint32",
                                },
                                {
                                    "internalType": "bytes21",
                                    "name": "id",
                                    "type": "bytes21",
                                },
                                {
                                    "internalType": "int32",
                                    "name": "value",
                                    "type": "int32",
                                },
                                {
                                    "internalType": "uint16",
                                    "name": "turnoutBIPS",
                                    "type": "uint16",
                                },
                                {
                                    "internalType": "int8",
                                    "name": "decimals",
                                    "type": "int8",
                                },
                            ],
                            "internalType": "struct FtsoV2Interface.FeedData",
                            "name": "body",
                            "type": "tuple",
                        },
                    ],
                    "internalType": "struct FtsoV2Interface.FeedDataWithProof",
                    "name": "_feedData",
                    "type": "tuple",
                }
            ],
            "name": "verifyFeedData",
            "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
            "stateMutability": "view",
            "type": "function",
        },
    ]


class orbital_configs:
    PROVIDER_URL = "https://testnet.evm.nodes.onflow.org"
    CONTRACT_ADDRESS = "0x274725cdEEC749D4E97DC990de45a5Bba76F80C3"
    ABI = [
        {
            "inputs": [
                {"internalType": "address[]", "name": "_tokens", "type": "address[]"},
                {"internalType": "string[]", "name": "_symbols", "type": "string[]"},
                {"internalType": "address", "name": "_owner", "type": "address"},
            ],
            "stateMutability": "nonpayable",
            "type": "constructor",
        },
        {
            "inputs": [{"internalType": "address", "name": "owner", "type": "address"}],
            "name": "OwnableInvalidOwner",
            "type": "error",
        },
        {
            "inputs": [
                {"internalType": "address", "name": "account", "type": "address"}
            ],
            "name": "OwnableUnauthorizedAccount",
            "type": "error",
        },
        {"inputs": [], "name": "ReentrancyGuardReentrantCall", "type": "error"},
        {
            "inputs": [{"internalType": "address", "name": "token", "type": "address"}],
            "name": "SafeERC20FailedOperation",
            "type": "error",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "uint256",
                    "name": "tickId",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "enum OrbitalTypes.TickState",
                    "name": "fromState",
                    "type": "uint8",
                },
                {
                    "indexed": False,
                    "internalType": "enum OrbitalTypes.TickState",
                    "name": "toState",
                    "type": "uint8",
                },
            ],
            "name": "BoundaryCrossed",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "uint256",
                    "name": "tickId",
                    "type": "uint256",
                },
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "owner",
                    "type": "address",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "amounts",
                    "type": "uint256[]",
                },
            ],
            "name": "FeesCollected",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "recipient",
                    "type": "address",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "amounts",
                    "type": "uint256[]",
                },
            ],
            "name": "FeesCollected",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "provider",
                    "type": "address",
                },
                {
                    "indexed": True,
                    "internalType": "uint256",
                    "name": "tickId",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "radius",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "k",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "amounts",
                    "type": "uint256[]",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "feeBps",
                    "type": "uint256",
                },
            ],
            "name": "LiquidityAdded",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "provider",
                    "type": "address",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "amounts",
                    "type": "uint256[]",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "lpTokensMinted",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "newReserves",
                    "type": "uint256[]",
                },
            ],
            "name": "LiquidityAdded",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "provider",
                    "type": "address",
                },
                {
                    "indexed": True,
                    "internalType": "uint256",
                    "name": "tickId",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "amounts",
                    "type": "uint256[]",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "fees",
                    "type": "uint256[]",
                },
            ],
            "name": "LiquidityRemoved",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "provider",
                    "type": "address",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "amounts",
                    "type": "uint256[]",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "lpTokensBurned",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "newReserves",
                    "type": "uint256[]",
                },
            ],
            "name": "LiquidityRemoved",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "previousOwner",
                    "type": "address",
                },
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "newOwner",
                    "type": "address",
                },
            ],
            "name": "OwnershipTransferred",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "trader",
                    "type": "address",
                },
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "tokenIn",
                    "type": "address",
                },
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "tokenOut",
                    "type": "address",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "amountIn",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "amountOut",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "segments",
                    "type": "uint256",
                },
            ],
            "name": "Swap",
            "type": "event",
        },
        {
            "anonymous": False,
            "inputs": [
                {
                    "indexed": True,
                    "internalType": "address",
                    "name": "trader",
                    "type": "address",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "tokenInIndex",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "tokenOutIndex",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "amountIn",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256",
                    "name": "amountOut",
                    "type": "uint256",
                },
                {
                    "indexed": False,
                    "internalType": "uint256[]",
                    "name": "newReserves",
                    "type": "uint256[]",
                },
            ],
            "name": "Swap",
            "type": "event",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "activeTickIds",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint256[]", "name": "amounts", "type": "uint256[]"},
                {"internalType": "uint256", "name": "capital", "type": "uint256"},
                {
                    "internalType": "uint256",
                    "name": "depegTolerance",
                    "type": "uint256",
                },
                {"internalType": "uint256", "name": "feeBps", "type": "uint256"},
            ],
            "name": "addLiquidity",
            "outputs": [
                {
                    "components": [
                        {
                            "internalType": "uint256",
                            "name": "tickId",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "kValue",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "radius",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "depegProtection",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "capitalEfficiency",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "virtualReserves",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256[]",
                            "name": "initialReserves",
                            "type": "uint256[]",
                        },
                        {
                            "internalType": "uint256",
                            "name": "effectiveDeposit",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256[]",
                            "name": "leftoverAmounts",
                            "type": "uint256[]",
                        },
                        {"internalType": "bool", "name": "success", "type": "bool"},
                        {"internalType": "string", "name": "message", "type": "string"},
                    ],
                    "internalType": "struct OrbitalTypes.LiquidityResult",
                    "name": "result",
                    "type": "tuple",
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "boundaryTickIds",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint256", "name": "tickId", "type": "uint256"}
            ],
            "name": "collectFees",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "getPoolStats",
            "outputs": [
                {
                    "components": [
                        {
                            "internalType": "string[]",
                            "name": "tokenSymbols",
                            "type": "string[]",
                        },
                        {
                            "internalType": "uint256",
                            "name": "totalTicks",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "interiorTicks",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "boundaryTicks",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256[]",
                            "name": "totalReserves",
                            "type": "uint256[]",
                        },
                        {
                            "internalType": "uint256",
                            "name": "totalLiquidity",
                            "type": "uint256",
                        },
                    ],
                    "internalType": "struct OrbitalTypes.PoolStats",
                    "name": "",
                    "type": "tuple",
                }
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint8", "name": "tokenInIndex", "type": "uint8"},
                {"internalType": "uint8", "name": "tokenOutIndex", "type": "uint8"},
                {"internalType": "uint256", "name": "amountIn", "type": "uint256"},
            ],
            "name": "getQuote",
            "outputs": [
                {"internalType": "uint256", "name": "amountOut", "type": "uint256"}
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "interiorTickIds",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "isBoundaryTick",
            "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "isInteriorTick",
            "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "nextTickId",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "owner",
            "outputs": [{"internalType": "address", "name": "", "type": "address"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint256", "name": "tickId", "type": "uint256"}
            ],
            "name": "removeLiquidity",
            "outputs": [
                {"internalType": "uint256[]", "name": "amounts", "type": "uint256[]"},
                {"internalType": "uint256[]", "name": "fees", "type": "uint256[]"},
            ],
            "stateMutability": "nonpayable",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "renounceOwnership",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "address", "name": "tokenIn", "type": "address"},
                {"internalType": "address", "name": "tokenOut", "type": "address"},
                {"internalType": "uint256", "name": "amountIn", "type": "uint256"},
                {"internalType": "uint256", "name": "minAmountOut", "type": "uint256"},
                {"internalType": "uint256", "name": "deadline", "type": "uint256"},
            ],
            "name": "swap",
            "outputs": [
                {
                    "components": [
                        {
                            "internalType": "uint256",
                            "name": "inputAmountGross",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "inputAmountNet",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "outputAmount",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "effectivePrice",
                            "type": "uint256",
                        },
                        {
                            "internalType": "uint256",
                            "name": "segments",
                            "type": "uint256",
                        },
                        {"internalType": "bool", "name": "success", "type": "bool"},
                        {"internalType": "string", "name": "message", "type": "string"},
                    ],
                    "internalType": "struct OrbitalTypes.TradeResult",
                    "name": "result",
                    "type": "tuple",
                }
            ],
            "stateMutability": "nonpayable",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "uint8", "name": "tokenInIndex", "type": "uint8"},
                {"internalType": "uint8", "name": "tokenOutIndex", "type": "uint8"},
                {"internalType": "uint256", "name": "amountIn", "type": "uint256"},
                {"internalType": "uint256", "name": "minAmountOut", "type": "uint256"},
                {"internalType": "address", "name": "recipient", "type": "address"},
            ],
            "name": "swapExactIn",
            "outputs": [
                {"internalType": "uint256", "name": "amountOut", "type": "uint256"}
            ],
            "stateMutability": "nonpayable",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "tickIdToIndex",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "ticks",
            "outputs": [
                {"internalType": "uint256", "name": "tickId", "type": "uint256"},
                {"internalType": "address", "name": "owner", "type": "address"},
                {"internalType": "uint256", "name": "k", "type": "uint256"},
                {"internalType": "uint256", "name": "radius", "type": "uint256"},
                {"internalType": "uint256", "name": "liquidity", "type": "uint256"},
                {
                    "internalType": "enum OrbitalTypes.TickState",
                    "name": "state",
                    "type": "uint8",
                },
                {"internalType": "uint256", "name": "feeBps", "type": "uint256"},
            ],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "tokenCount",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "address", "name": "", "type": "address"}],
            "name": "tokenIndex",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "tokenSymbols",
            "outputs": [{"internalType": "string", "name": "", "type": "string"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "name": "tokens",
            "outputs": [{"internalType": "address", "name": "", "type": "address"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "totalLiquidity",
            "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [],
            "name": "totalReserves",
            "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
            "stateMutability": "view",
            "type": "function",
        },
        {
            "inputs": [
                {"internalType": "address", "name": "newOwner", "type": "address"}
            ],
            "name": "transferOwnership",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function",
        },
    ]


class merchant_configs:
    """
    Configurations and constants for merchant interactions.
    """

    MERCHANT_ID_TO_MERCHANT_MAP = {
        1000: "NYTIMES",
    }

    MERCHANT_TO_CURRENCY_MAP = {
        "NYTIMES": ["USDC", "USDT", "DAI", "PYUSD", "USDe", "FRAX"],
    }

    price = TokenAmount(
        amount="1000",
        asset=TokenAsset(
            address="0x036CbD53842c5426634e7929541eC2318f3dCF7e",  # USDC on Base Sepolia
            decimals=6,
            eip712=EIP712Domain(name="USDC", version="2"),
        ),
    )

    network = "base-sepolia"
    resource = "url"  # url
    description = "Access to weather data (Custom Token)"
    # Get USDC address for the network
    chain_id = get_chain_id(network)
    asset_address = price.asset.address

    # Get EIP-712 domain info
    eip712_domain = {
        "name": get_token_name(chain_id, asset_address),
        "version": get_token_version(chain_id, asset_address),
    }

    PAYMENT_REQUIREMENT = PaymentRequirements(
        scheme="exact",
        network=network,
        max_amount_required=price.amount,
        resource=resource,
        description=description,
        mime_type="application/json",
        pay_to=str(0x0),  # need wallet
        max_timeout_seconds=60,
        asset=asset_address,
        output_schema=None,
        extra=eip712_domain,
    )


class genius_configs:
    DATA: dict
