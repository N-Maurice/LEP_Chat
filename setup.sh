#!/usr/env bash

cd api_lep_chat
python3 -m venv app/.venv
app/.venv/bin/pip install -r app/requirements.txt
app/.venv/bin/uvicorn app.main:app --reload
