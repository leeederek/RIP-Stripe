import fastapi
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from src.configs import merchant_configs
from src.services import oracle, merchant
from src import models
from x402.types import x402PaymentRequiredResponse, PaymentPayload
from x402.facilitator import FacilitatorClient, FacilitatorConfig
from x402.exact import decode_payment

router = fastapi.APIRouter()


@router.get("/")
async def root():
    return {"Hello": "World"}


@router.get("/get-resource/{resource_id}")
async def get_resource(resource_id: int, request: Request):
    # accepted_currencies = merchant.get_valid_payment_currencies(resource_id)
    payment_requirements = merchant.get_payment_requirements()
    error_data = x402PaymentRequiredResponse(
        x402_version=1,
        error=str("Payment required"),
        accepts=payment_requirements,
    ).model_dump(by_alias=True)

    return JSONResponse(
        status_code=402,
        content=error_data,
        headers={"Content-Type": "application/json"},
    )


@router.post("/verify/")
async def verify(request: Request):
    # decoded_payment_dict = decode_payment()
    json_dict = await request.json()
    # # decoded_payment_dict["x402Version"] = x402_VERSION
    decoded_payment = PaymentPayload(**json_dict["paymentPayload"])
    # print(decoded_payment)
    FACILITATOR_URL = "https://x402.org/facilitator"
    NETWORK = "base-sepolia"

    # Initialize facilitator client
    facilitator_config: FacilitatorConfig = {"url": FACILITATOR_URL}
    facilitator = FacilitatorClient(facilitator_config)
    verify_response = await facilitator.verify(
        decoded_payment, merchant_configs.PAYMENT_REQUIREMENT
    )
    if not verify_response.is_valid:
        return JSONResponse(
            status_code=402,
            content=verify_response.model_dump(),
            headers={"Content-Type": "application/json"},
        )


@router.get("/price/{stablecoin}")
async def get_price(stablecoin: str):
    stablecoin = stablecoin.upper()
    price, date = oracle.get_stablecoin_price(stablecoin)
    print(price)
    return {"Stablecoin": stablecoin, "Price": f"${price}", "fetched at": date}


@router.get("/coin-data/{stablecoin}")
async def genius_compliance(stablecoin: str):
    return merchant.get_stablecoin_data(stablecoin.upper())


@router.get("/risk-score/{stablecoin}")
async def risk_score(stablecoin: str):
    return merchant.compute_risk_score(stablecoin.upper())


@router.post("/swap")
async def swap(data: models.BasicModel):
    # Return SwapResponse
    returned_data = merchant.swap_currencies()
