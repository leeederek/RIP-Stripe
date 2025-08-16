import fastapi
from app.router import router

app = fastapi.FastAPI()

app.include_router(router, prefix="/api")