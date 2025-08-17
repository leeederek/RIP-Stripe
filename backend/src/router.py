import fastapi
from fastapi import Request
from fastapi.responses import JSONResponse
from src.configs import merchant_configs, premium_data, secret_data
from src.services import oracle, merchant
from src import models
from x402.types import x402PaymentRequiredResponse, PaymentPayload
from x402.facilitator import FacilitatorClient, FacilitatorConfig
from cdp.auth.utils.jwt import generate_jwt, JwtOptions

router = fastapi.APIRouter()


@router.get("/")
async def root():
    return {}


@router.get("/get-resource/{resource_id}")
async def get_resource(resource_id: int, request: Request):
    # Get the PaymentRequirement for a requested merchant resource.
    payment_requirements = merchant.resolve_merchant_payment_reqs(resource_id)
    error_data = x402PaymentRequiredResponse(
        x402_version=1,
        error=str("Payment required"),
        accepts=[payment_requirements],
    ).model_dump(by_alias=True)

    # Return the merchant PaymentRequirement.
    return JSONResponse(
        status_code=402,
        content=error_data,
        headers={"Content-Type": "application/json"},
    )


@router.post("/verify/")
async def verify(request: Request):
    request_payload = await request.json()
    decoded_payment = PaymentPayload(**request_payload["paymentPayload"])

    # Facilitator to check payment confirmation
    facilitator_config: FacilitatorConfig = {"url": merchant_configs.FACILITATOR_URL}
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
    # Successful payment returns web content.
    return premium_data.DATA


@router.get("/price/{stablecoin}")
async def get_price(stablecoin: str):
    stablecoin = stablecoin.upper()
    price, date = oracle.get_stablecoin_price(stablecoin)
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


@router.get("/access-token")
def get_access_token():
    # Generate the JWT using the CDP SDK
    jwt_token = generate_jwt(
        JwtOptions(
            api_key_id=secret_data.KEYID,
            api_key_secret=secret_data.SECRET,
            request_method="POST",
            request_host="api.cdp.coinbase.com",
            request_path="/platform/v2/x402/settle",
            expires_in=900,  # optional (defaults to 120 seconds)
        )
    )
    return {"access_token": jwt_token}
