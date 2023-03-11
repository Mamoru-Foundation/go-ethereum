# Support setting various labels on the final image
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

# Build Geth in a stock Go builder container
FROM golang:1.20.1 as builder

RUN apt update && apt-get -y install  make gcc git bash glibc-source


# Get dependencies - will also be cached if we won't change go.mod/go.sum
COPY go.mod /go-ethereum/
COPY go.sum /go-ethereum/
RUN cd /go-ethereum && go mod download

ADD . /go-ethereum
RUN cd /go-ethereum && go run build/ci.go install ./cmd/geth

# Pull Geth into a second stage deploy debian:bullseye-slim container
FROM debian:bullseye-slim

ENV PACKAGES ca-certificates jq unzip\
  bash tini \
  grep curl sed

ENV DATA_DIR=/data

RUN apt-get update && apt-get install -y $PACKAGES \
    && apt-get clean

COPY --from=builder /go-ethereum/build/bin/geth /usr/local/bin/

EXPOSE 8545 8546 30303 30303/udp

VOLUME ${DATA_DIR}

ENTRYPOINT ["/usr/bin/tini", "--", "geth", "--datadir", "${DATA_DIR}"]

# Add some metadata labels to help programatic image consumption
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

LABEL commit="$COMMIT" version="$VERSION" buildnum="$BUILDNUM"
