FROM alpine:3.20

ENV REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/home/container/registry \
    REGISTRY_LOG_LEVEL=info \
    STARTUP="./entrypoint.sh"

RUN apk add --no-cache \
        docker-registry \
        bash \
        ca-certificates \
        tzdata \
        dumb-init && \
    update-ca-certificates

RUN adduser -D -h /home/container container && \
    mkdir -p /home/container /home/container/registry /etc/docker/registry && \
    chown -R container:container /home/container /etc/docker/registry

COPY --chown=container:container registry-config.yml /etc/docker/registry/config.yml
COPY --chown=container:container entrypoint.sh /home/container/entrypoint.sh

RUN chmod +x /home/container/entrypoint.sh

USER container
WORKDIR /home/container

EXPOSE 5000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["bash", "-c", "${STARTUP}"]
