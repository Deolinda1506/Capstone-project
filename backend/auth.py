"""JWT token verification and get_current_user dependency."""
from __future__ import annotations

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError

from backend.config import DISABLE_AUTH
from backend.database import get_db
from backend.models import User
from backend.jwt_utils import decode_access_token

security = HTTPBearer()
security_optional = HTTPBearer(auto_error=False)

_credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Invalid or expired token",
    headers={"WWW-Authenticate": "Bearer"},
)

# Default dev user ID when no token provided (for local testing without auth)
_DEV_USER_ID = "00000000-0000-0000-0000-000000000001"


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    """Verify Bearer JWT token. Returns the corresponding User."""
    token = credentials.credentials
    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if user_id:
            user = db.get(User, user_id)
            if user and not user.is_deleted and (user.status or "approved") == "approved":
                return user
    except JWTError:
        pass
    raise _credentials_exception


async def get_current_user_or_dev(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security_optional)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    """Use JWT user if token provided; otherwise return a default dev user (no auth required)."""
    if DISABLE_AUTH:
        # Skip token check entirely - always use dev user
        pass
    elif credentials:
        try:
            payload = decode_access_token(credentials.credentials)
            user_id = payload.get("sub")
            if user_id:
                user = db.get(User, user_id)
                if user and not user.is_deleted and (user.status or "approved") == "approved":
                    return user
        except JWTError:
            pass
    # No token or invalid: use dev user (create if needed)
    user = db.get(User, _DEV_USER_ID)
    if not user:
        user = User(
            id=_DEV_USER_ID,
            staff_id="DEV-001",
            email="dev@carotidcheck.local",
            password_hash=None,
            facility="Dev Facility",
            status="approved",
            role="chw",
            is_deleted=False,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user
