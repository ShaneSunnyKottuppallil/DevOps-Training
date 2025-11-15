FROM python:3.8-slim AS builder

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      pkg-config \
      default-libmysqlclient-dev

COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt


FROM python:3.8-slim

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
      default-mysql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY . .
COPY --from=builder /wheels /wheels

RUN pip install --no-cache-dir /wheels/*


COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
