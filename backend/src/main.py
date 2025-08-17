import fastapi
from src.router import router
from src.configs import genius_configs
import json
from fastapi.middleware.cors import CORSMiddleware

with open("genius_compliance_data.json", "r") as file:
    genius_configs.DATA = json.load(file)

server = fastapi.FastAPI()

server.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Allowed origins
    allow_credentials=True,       # Allow cookies/auth headers
    allow_methods=["*"],          # Allow all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],          # Allow all headers
)

server.include_router(router)
