from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlmodel import Session

from . import packs
from .database import engine, init_db
from .routers import admin, auth, content, feedback, telemetry


def seed_if_empty() -> None:
    with Session(engine) as session:
        packs.seed_if_empty(session)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()  # alembic upgrade head (stamps pre-Alembic databases first)
    seed_if_empty()  # first start: content files; always: a PackMeta per pair
    yield


app = FastAPI(title="OSG Content & Telemetry API", lifespan=lifespan)
app.include_router(content.router)
app.include_router(telemetry.router)
app.include_router(feedback.router)
app.include_router(auth.config_router)
app.include_router(auth.router)
app.include_router(auth.me_router)
app.include_router(admin.auth_router)
app.include_router(admin.router)


@app.get("/health")
def health():
    return {"status": "ok"}
