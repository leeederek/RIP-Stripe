from pydantic import BaseModel


class BasicModel(BaseModel):
    name: str
    value: int
