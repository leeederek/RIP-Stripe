#!/bin/bash

# Start the FastAPI server on localhost at port 8000 with auto-reload.
uvicorn app.main:app --host localhost --port 8000 --reload