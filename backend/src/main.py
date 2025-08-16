import fastapi
from src.router import router
from src.configs import genius_configs
import json

with open("genius_compliance_data.json", "r") as file:
    genius_configs.DATA = json.load(file)

server = fastapi.FastAPI()

server.include_router(router)
