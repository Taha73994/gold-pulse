"""اتصال قاعدة البيانات — SQLite محلياً أو PostgreSQL عبر DATABASE_URL."""
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from .config import DB_PATH


def _database_url() -> str:
    url = (os.getenv("DATABASE_URL") or "").strip()
    if not url:
        return f"sqlite:///{DB_PATH}"
    # توافق مع روابط الاستضافة التي تبدأ بـ postgres://
    if url.startswith("postgres://"):
        url = "postgresql+psycopg://" + url[len("postgres://") :]
    elif url.startswith("postgresql://"):
        url = "postgresql+psycopg://" + url[len("postgresql://") :]
    return url


DATABASE_URL = _database_url()
_IS_SQLITE = DATABASE_URL.startswith("sqlite")

engine = create_engine(
    DATABASE_URL,
    connect_args=(
        {"check_same_thread": False} if _IS_SQLITE else {"prepare_threshold": 0}
    ),
    pool_pre_ping=True,
    **({} if _IS_SQLITE else {"pool_size": 2, "max_overflow": 2}),
    future=True,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
