#!/bin/bash

# Start the FastAPI server on localhost at port 8000 with auto-reload.
uvicorn src.main:server --host localhost --port 8000 --reload