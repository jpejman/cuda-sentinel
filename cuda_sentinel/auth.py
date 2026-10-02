import os
from fastapi import Header, HTTPException

def require_operator(authorization: str | None = Header(default=None)) -> None:
    """Require a bearer token when operator auth is configured."""
    expected = os.environ.get("SENTINEL_OPERATOR_TOKEN")
    if expected and authorization != f"Bearer {expected}":
        raise HTTPException(status_code=401, detail="Operator authentication required")
