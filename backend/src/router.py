import fastapi
from src.services import oracle
from src import models
from pymongo import MongoClient


router = fastapi.APIRouter()

# Set up MongoDB client (adjust URI as needed)
client = MongoClient("mongodb://localhost:27017/")
db = client["orbital_db"]
collection = db["data"]

@router.get("/")
async def root():
    return {"Hello": "World"}

@router.get("/price/{stablecoin}")
async def get_price(stablecoin: str):
    stablecoin = stablecoin.upper()
    price = oracle.get_stablecoin_price(stablecoin)
    print(price)
    return {"stablecoin": stablecoin, "price": price}

@router.post("/data")
async def post_data(data: models.BasicModel):
    # Convert Pydantic model to dict
    data_dict = data.dict()
    # Insert into MongoDB
    result = collection.insert_one(data_dict)
    return {"inserted_id": str(result.inserted_id), **data_dict}