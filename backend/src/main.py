import fastapi
from src.router import router

server = fastapi.FastAPI()

server.include_router(router, prefix="/api")
