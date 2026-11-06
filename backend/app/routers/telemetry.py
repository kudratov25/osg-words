from fastapi import APIRouter, Depends
from sqlmodel import Session

from ..database import get_session
from ..models import DevicePing
from ..schemas import DevicePingCreate

router = APIRouter(prefix="/telemetry", tags=["telemetry"])


@router.post("/ping", status_code=204)
def ping(payload: DevicePingCreate, session: Session = Depends(get_session)):
    session.add(DevicePing(**payload.model_dump()))
    session.commit()
