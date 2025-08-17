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
has_been_verified = False


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

    if not has_been_verified:
        # Return the merchant PaymentRequirement.
        return JSONResponse(
            status_code=402,
            content=error_data,
            headers={"Content-Type": "application/json"},
        )
    return premium_data.DATA


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
        asset="0x50766571B3769d9CfC170f3b17668F3673F80EbA",
        extra={
            "name": "USDC",
            "version": "1",
            "gasLimit": "1000000",
        },
    )
    facilitator_config: FacilitatorConfig = {"url": merchant_configs.FACILITATOR_URL}
    facilitator = FacilitatorClient(facilitator_config)
    verify_response = await facilitator.verify(decoded_payment, payment_requirements)
    print("Result of verification:", verify_response)
    if not verify_response.is_valid:
        return JSONResponse(
            status_code=402,
            content=verify_response.model_dump(by_alias=True),
            headers=headers,
        )

    # Settle the payment with retry logic
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

    # Retry loop for settlement
    max_retries = 10
    retry_count = 0
    response = None

    while retry_count < max_retries:
        try:
            response = requests.post(
                url=settle_url,
                json=payload,
                headers=headers,
            )
            response_data = response.json()
            print(f"Attempt {retry_count + 1}: {response_data}")

            # Check if settlement was successful
            if response_data.get("success", False):
                print("Settlement successful!")
                break
            else:
                print(
                    f"Settlement failed: {response_data.get('message', 'Unknown error')}"
                )
                retry_count += 1

                if retry_count < max_retries:
                    print(
                        f"Retrying in 2 seconds... (Attempt {retry_count + 1}/{max_retries})"
                    )
                    import time

                    time.sleep(2)
                else:
                    print("Max retries reached. Settlement failed.")

        except Exception as e:
            print(f"Error during settlement attempt {retry_count + 1}: {e}")
            retry_count += 1

            if retry_count < max_retries:
                print(
                    f"Retrying in 2 seconds... (Attempt {retry_count + 1}/{max_retries})"
                )
                import time

                time.sleep(2)
            else:
                print("Max retries reached due to errors.")

    print("Final settle result:", response.json() if response else "No response")
    has_been_verified = True


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
