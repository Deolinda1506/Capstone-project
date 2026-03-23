"""JWT creation and verification for email/password login."""
from datetime import datetime, timedelta, timezone
from typing import Any

from jose import JWTError, jwt

from backend.config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES


def create_access_token(subject: str, extra: dict[str, Any] | None = None) -> str:
    """Create a JWT with subject (user id) and optional extra claims."""
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    # NumericDate (int) avoids edge cases with python-jose + aware datetimes on some runtimes
    to_encode = {"sub": subject, "exp": int(expire.timestamp())}
    if extra:
        to_encode.update(extra)
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict[str, Any]:
    """Decode and verify JWT; return payload. Raises JWTError if invalid."""
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
