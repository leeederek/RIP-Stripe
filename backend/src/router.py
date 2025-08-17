import fastapi
from fastapi import Request
from fastapi.responses import JSONResponse
from src.configs import merchant_configs, premium_data, secret_data
from src.services import oracle, merchant
from src import models
from x402.types import x402PaymentRequiredResponse, PaymentPayload
from x402.facilitator import FacilitatorClient, FacilitatorConfig
from cdp.auth.utils.jwt import generate_jwt, JwtOptions
import requests
from x402.types import PaymentRequirements
from x402.encoding import safe_base64_decode
import json

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


@router.get("/verify")
async def verify(request: Request):
    payment_header = request.headers.get("X-PAYMENT", "")
    payment_obj = safe_base64_decode(payment_header)
    decoded_payment = PaymentPayload(**json.loads(payment_obj))
    access_token = make_access_token("GET")
    jwt_token = access_token
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Content-Type": "application/json",
    }

    # Facilitator to check payment confirmation
    payment_requirements = PaymentRequirements(
        scheme="exact",
        network="base-sepolia",
        max_amount_required="10",
        resource="https://api.cdp.coinbase.com/platform/v2/x402/settle",
        description="Premium API access for data analysis",
        mime_type="application/json",
        output_schema={"data": "string"},
        pay_to="0x74051bf72a90014a515c511fECFe9811dE138235",
        max_timeout_seconds=300,
        asset="0x036CbD53842c5426634e7929541eC2318f3dCF7e",
        extra={
            "name": "USDC",
            "version": "2",
            "gasLimit": "1000000",
        }
    )
    facilitator_config: FacilitatorConfig = {"url": merchant_configs.FACILITATOR_URL}
    facilitator = FacilitatorClient(facilitator_config)
    verify_response = await facilitator.verify(decoded_payment, payment_requirements)
    print("verify res:", verify_response)
    if not verify_response.is_valid:
        return JSONResponse(
            status_code=402,
            content=verify_response.model_dump(by_alias=True),
            headers=headers,
        )

    # Settle the payment
    settle_url = "https://api.cdp.coinbase.com/platform/v2/x402/settle"
    access_token = make_access_token("POST")
    jwt_token = access_token
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Content-Type": "application/json",
    }
    payload = {
        "x402Version": 1,
        "paymentPayload": decoded_payment.model_dump(by_alias=True),
        "paymentRequirements": payment_requirements.model_dump(by_alias=True),
    }
    # response = requests.post(
    #     url=settle_url,
    #     json=payload,
    #     headers=headers,
    # )
    response = requests.post(
        url=settle_url,
        json=payload,
        headers=headers,
    )
    print("settle res:", response.text)

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


def make_access_token(request):
    # Generate the JWT using the CDP SDK
    jwt_token = generate_jwt(
        JwtOptions(
            api_key_id=secret_data.KEYID,
            api_key_secret=secret_data.SECRET,
            request_method=request,
            request_host="api.cdp.coinbase.com",
            request_path="/platform/v2/x402/settle",
            expires_in=900,  # optional (defaults to 120 seconds)
        )
    )
    return jwt_token


@router.get("/access-token")
def get_access_token():
    return make_access_token("POST")


@router.post("/settle")
async def settle_txn(request: Request):
    # request_payload = await request.json()
    # decoded_payment = PaymentPayload(**request_payload["paymentPayload"])
    url = "https://api.cdp.coinbase.com/platform/v2/x402/settle"

    # Create PaymentRequirements object from configs
    payment_requirements = PaymentRequirements(
        scheme="exact",
        network="base-sepolia",
        max_amount_required="1000000000000000000",
        resource="https://api.cdp.coinbase.com/platform/v2/x402/settle",
        description="Premium API access for data analysis",
        mime_type="application/json",
        output_schema={"data": "string"},
        pay_to="0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
        max_timeout_seconds=300,
        asset="0x036CbD53842c5426634e7929541eC2318f3dCF7e",
    )

    payload = {
        "x402Version": 1,
        "paymentPayload": {
            "x402Version": 1,
            "scheme": "exact",
            "network": "base-sepolia",
            "payload": {
                "signature": "0xf3746613c2d920b5fdabc0856f2aeb2d4f88ee6037b8cc5d04a71a4462f13480",
                "authorization": {
                    "from": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
                    "to": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
                    "value": "1000000000000000000",
                    "validAfter": "1716150000",
                    "validBefore": "1716150000",
                    "nonce": "0x1234567890abcdef1234567890abcdef12345678",
                },
            },
        },
        "paymentRequirements": {
            "scheme": "exact",
            "network": "base-sepolia",
            "maxAmountRequired": "1000000000000000000",
            "resource": "https://api.cdp.coinbase.com/platform/v2/x402/settle",
            "description": "Premium API access for data analysis",
            "mimeType": "application/json",
            "outputSchema": {"data": "string"},
            "payTo": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
            "maxTimeoutSeconds": 300,
            "asset": "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
            # "extra": {"gasLimit": "1000000"},p
        },
    }
    access_token = make_access_token("POST")

    jwt_token = access_token
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Content-Type": "application/json",
    }
    response = requests.post(
        url=url,
        json=payload,
        headers=headers,
    )
    print(response.text)
    return payload
