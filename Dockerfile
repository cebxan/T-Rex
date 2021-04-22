FROM ubuntu:20.04 AS builder

WORKDIR /tmp

ARG TREX_VERSION="0.20.1"

RUN mkdir t-rex \
    && apt update \
    && apt install -y --no-install-recommends tar wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/trexminer/T-Rex/releases/download/${TREX_VERSION}/t-rex-${TREX_VERSION}-linux.tar.gz \
    && tar xf t-rex-${TREX_VERSION}-linux.tar.gz -C t-rex


FROM nvidia/cuda:11.2.2-base

LABEL maintainer="Carlos Berroteran (cebxan)"

LABEL org.opencontainers.image.source https://github.com/cebxan/docker-trex

# Fix Driver bug
RUN ln -s /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 /usr/lib/x86_64-linux-gnu/libnvidia-ml.so

ARG DEBIAN_FRONTEND="noninteractive"

RUN apt update \
    && apt install -y --no-install-recommends \
    tzdata \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/t-rex/t-rex /usr/local/bin/t-rex

EXPOSE 4067 4068

ENV TZ America/Caracas

HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 CMD \
    curl localhost:4067/summary | jq -e 'any(.paused;.==false)' || exit 1

ENTRYPOINT [ "t-rex" ]