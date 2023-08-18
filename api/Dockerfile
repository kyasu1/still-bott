FROM lukemathwalker/cargo-chef:latest-rust-1 AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder 
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release --bin still-bott

# We do not need the Rust toolchain to run the binary!
FROM debian:bullseye-slim AS runtime
WORKDIR /app
COPY --from=builder /app/target/release/still-bott /usr/local/bin

# For self signed certificate support
RUN apt-get update
RUN apt-get install ca-certificates -y

RUN mkdir /app/dist

COPY ./run.sh /app/run.sh
RUN ["chmod", "+x", "/app/run.sh"]

ENV RUST_LOG debug
EXPOSE 3000
ENTRYPOINT ["/app/run.sh"]