from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.config import get_settings
from app.core.firebase import init_firebase_app
from app.middleware.cors import setup_cors
from app.routers import auth, messages, sessions

settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_firebase_app(settings)
    yield


app = FastAPI(
    title="LEP Chat API",
    description="Chatbot API guiding citizens through Rwandan law, with cited legal references.",
    version="0.1.0",
    lifespan=lifespan,
)

setup_cors(app, settings)


@app.get("/health", tags=["health"])
async def health_check() -> dict:
    return {"status": "ok"}


app.include_router(auth.router, prefix=settings.api_v1_prefix)
app.include_router(sessions.router, prefix=settings.api_v1_prefix)
app.include_router(messages.router, prefix=settings.api_v1_prefix)
