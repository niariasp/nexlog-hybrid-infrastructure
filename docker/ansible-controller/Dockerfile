FROM alpine:3.24.2

RUN apk add --no-cache \
    python3 \
    ansible-core \
    git \
    openssh-client \
    openssl \
    ca-certificates \
    && update-ca-certificates

WORKDIR /root
