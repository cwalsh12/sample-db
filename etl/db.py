"""Shared database connection for the pipeline. Settings come from .env."""
import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import URL, create_engine

PROJECT_ROOT = Path(__file__).resolve().parent.parent

load_dotenv(PROJECT_ROOT / ".env")


def get_engine():
    """Connect as etl_writer, never as the admin superuser."""
    url = URL.create(
        "postgresql+psycopg",
        username="etl_writer",
        password=os.environ["ETL_PASSWORD"],
        host=os.getenv("POSTGRES_HOST", "127.0.0.1"),
        port=int(os.environ["POSTGRES_PORT"]),
        database=os.environ["POSTGRES_DB"],
    )
    return create_engine(url)
