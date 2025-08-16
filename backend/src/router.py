import fastapi
from fastapi import HTTPException
from src.services import oracle, merchant
from src import models


router = fastapi.APIRouter()


@router.get("/")
async def root():
    return {"Hello": "World"}


@router.get("/get-resource/{resource_id}")
async def get_resource(resource_id: int):
    accepted_currencies = merchant.get_valid_payment_currencies(resource_id)
    print(accepted_currencies)
    raise HTTPException(status_code=402, detail=accepted_currencies)


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
