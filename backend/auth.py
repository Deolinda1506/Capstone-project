"""JWT token verification and get_current_user dependency."""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import JWTError

from backend.database import get_db
from backend.models import User
from backend.jwt_utils import decode_access_token

security = HTTPBearer()

_credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Invalid or expired token",
    headers={"WWW-Authenticate": "Bearer"},
)


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
