import fastapi
from src.services import oracle


router = fastapi.APIRouter()

@router.get("/")
async def root():
    return {"Hello": "World"}


@router.get("/price/{stablecoin}")
async def get_price(stablecoin: str):
    stablecoin = stablecoin.upper()
    price = oracle.get_stablecoin_price(stablecoin)
    print(price)
    return {"stablecoin": stablecoin, "price": price}