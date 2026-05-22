FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    GITHUB_USERNAME=docker \
    EFS_DIR=/app/efs \
    RAY_TMPDIR=/tmp/ray_ci \
    TOKENIZERS_PARALLELISM=false

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN python -m pip install --upgrade pip \
    && pip install -r requirements.txt

COPY madewithml ./madewithml
COPY datasets ./datasets

RUN mkdir -p /app/efs /tmp/ray_ci

EXPOSE 8000

CMD ["sh", "-c", "python -m madewithml.serve --run_id \"$RUN_ID\" --threshold \"${THRESHOLD:-0.9}\""]
