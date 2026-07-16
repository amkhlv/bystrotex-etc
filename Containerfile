FROM docker.io/library/rust:bookworm AS rust-builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY Rust/BibTeX/Cargo.toml Rust/BibTeX/Cargo.lock ./
COPY Rust/BibTeX/src ./src

RUN cargo build --release --locked


FROM docker.io/library/node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /config /run/bystrotex \
    && chown node:node /run/bystrotex

WORKDIR /app/latex-to-svg

COPY latex-to-svg/package*.json ./
RUN npm ci --omit=dev \
    && npm cache clean --force

COPY latex-to-svg/index.js ./
COPY --from=rust-builder /build/target/release/rust-extras /usr/local/bin/rust-extras
COPY containers/start-backend.sh /usr/local/bin/start-bystrotex-backend

ENV BYSTROTEX_SOCKET_DIR=/run/bystrotex \
    BYSTROTEX_BIB_PATH=/config/bystrotex.bib

USER node

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/start-bystrotex-backend"]
