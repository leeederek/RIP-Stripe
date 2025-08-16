import fastapi

router = fastapi.APIRouter()

@router.get("/")
async def root():
    return {"Hello": "World"}