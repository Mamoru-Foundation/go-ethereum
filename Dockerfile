# Support setting various labels on the final image
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""


# Build Geth in a stock Go builder container
FROM golang:1.20 as builder

RUN apt-get update  \
    && apt-get install -y gcc musl-dev git curl tar libc6-dev

# Get dependencies - will also be cached if we won't change go.mod/go.sum
COPY go.mod /go-ethereum/
COPY go.sum /go-ethereum/
RUN cd /go-ethereum && go mod download

ADD . /go-ethereum
RUN cd /go-ethereum && GO111MODULE=on go run build/ci.go install ./cmd/geth

# Install the Lighthouse Consensus Client
ENV LIGHTHOUSE_VERSION=v4.3.0
RUN  curl -LO https://github.com/sigp/lighthouse/releases/download/${LIGHTHOUSE_VERSION}/lighthouse-${LIGHTHOUSE_VERSION}-x86_64-unknown-linux-gnu.tar.gz
RUN tar xvf lighthouse-${LIGHTHOUSE_VERSION}-x86_64-unknown-linux-gnu.tar.gz  \
    && cp lighthouse /usr/local/bin  \
    && rm lighthouse-${LIGHTHOUSE_VERSION}-x86_64-unknown-linux-gnu.tar.gz  \
    && rm lighthouse

# Pull Geth into a second stage deploy debian container
FROM debian:12.0-slim
#debian:bullseye-slim

COPY docker/cron/cron.conf /etc/cron.d/cron.conf
COPY docker/cron/prune.sh /prune.sh
COPY docker/supervisord/gethlighthousebn.conf /etc/supervisor/conf.d/supervisord.conf
# Install Supervisor and create the Unix socket
RUN touch /var/run/supervisor.sock

RUN apt-get update  \
    && apt-get install -y ca-certificates jq unzip bash grep curl sed htop procps cron supervisor \
    && apt-get clean \
    && crontab /etc/cron.d/cron.conf

COPY --from=builder /go-ethereum/build/bin/* /usr/local/bin/
COPY --from=builder /usr/local/bin/lighthouse /usr/local/bin/

EXPOSE 9000 8545 8546 8551 30303 30303/udp

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
# Add some metadata labels to help programatic image consumption
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

LABEL commit="$COMMIT" version="$VERSION" buildnum="$BUILDNUM"
