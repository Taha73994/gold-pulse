FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    GOLD_DATA_DIR=/tmp/gold-pulse

WORKDIR /app

COPY requirements.txt requirements-cloud.txt ./
RUN pip install --no-cache-dir -r requirements-cloud.txt

COPY backend ./backend
COPY run.py ./
COPY webapp ./webapp

ENV GOLD_WEB_DIR=/app/webapp

EXPOSE 8010

CMD ["sh", "-c", "uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8010} --proxy-headers --forwarded-allow-ips=*"]
