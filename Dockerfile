FROM golang:buster AS builder
ARG VERSION

RUN apt-get -y update \
    && apt-get -y --no-install-recommends install \
    "make=4.2.1-1.2" \
    "git=1:2.20.1-2+deb10u3" \
    "bash=5.0-4" \
    "gcc=4:8.3.0-1" \
    && mkdir -p "$GOPATH/src/github.com/google" \
    && git clone https://github.com/google/cadvisor.git "$GOPATH/src/github.com/google/cadvisor"

WORKDIR $GOPATH/src/github.com/google/cadvisor
RUN git fetch --tags \
    && git checkout $VERSION \
    && go env -w GO111MODULE=auto \
    && make build \
    && cp ./cadvisor /

# ------------------------------------------
# Copied over from deploy/Dockerfile except that the "zfs" dependency has been removed
# a its not available fro Alpine on ARM
FROM alpine:3.15
LABEL org.opencontainers.image.authors="dengnan@google.com vmarmol@google.com vishnuk@google.com jimmidyson@gmail.com stclair@google.com"

RUN sed -i 's,https://dl-cdn.alpinelinux.org,http://dl-4.alpinelinux.org,g' /etc/apk/repositories

RUN apk --update-cache --no-cache add \
    "libc6-compat=1.2.2-r7" \
    "device-mapper=2.02.187-r2" \
    "findutils=4.8.0-r1" \
    "thin-provisioning-tools=0.9.0-r1" && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    rm -rf /var/cache/apk/*

# Grab cadvisor from the staging directory.
COPY --from=builder /cadvisor /usr/bin/cadvisor

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/healthz || exit 1

ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]
