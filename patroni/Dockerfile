FROM postgres:18.0-bookworm

RUN apt-get update && \
  apt-get install -y \
  postgresql \
  postgresql-contrib \
  python3 \
  python3-venv \
  curl \
  bash \
  build-essential \
  libpq-dev \
  netcat-openbsd \
  && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/jwilder/dockerize/releases/download/v0.9.9/dockerize-linux-amd64-v0.9.9.tar.gz \
  | tar -xz -C /usr/local/bin

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip
RUN pip install patroni[etcd] psycopg2-binary

COPY ./scripts /patroni/scripts
RUN chmod +x /patroni/scripts/wait-for-etcd.sh

WORKDIR /patroni
