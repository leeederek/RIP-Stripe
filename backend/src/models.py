from pydantic import BaseModel


class BasicModel(BaseModel):
    name: str
    value: int


class SwapRequest(BaseModel):
    chain: str
    token_in: str
    token_out: str
    amount_in: str
    min_amount_out: str
    deadline: int
    wallet_address: str
    # {
    #     "chain": "arbitrum",
    #     "tokenIn": "0xTokenIn",
    #     "tokenOut": "0xTokenOut",
    #     "amountIn": "1000000000000000000",
    #     "minAmountOut": "995000000000000000",
    #     "deadline": 1692548800,
    #     "walletAddress": "0xUserWallet",
    # }


class SwapResponse(BaseModel):
    input_amount_gross: str
    input_amount_net: str
    output_amount: str
    effective_price: str
    sgements: int
    success: bool
    message: str
    # {
    #   "inputAmountGross": "1000000000000000000",
    #   "inputAmountNet": "999000000000000000",
    #   "outputAmount": "995000000000000000",
    #   "effectivePrice": "1005025",
    #   "segments": 1,
    #   "success": true,
    #   "message": "Swap successful"
    # }
