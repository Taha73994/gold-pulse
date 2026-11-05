"""حماية لوحة المالك برمز سري."""
from fastapi import Header, HTTPException

from .config import ADMIN_PIN


def require_admin(x_admin_pin: str = Header(default="")) -> bool:
    if not x_admin_pin or x_admin_pin != ADMIN_PIN:
        raise HTTPException(status_code=401, detail="رمز المالك غير صحيح")
    return True
