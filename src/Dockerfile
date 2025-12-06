FROM alpine:3.20

ENV REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/home/container/registry \
    REGISTRY_LOG_LEVEL=info \
    STARTUP="./entrypoint.sh"

RUN apk add --no-cache \
        docker-registry \
        bash \
        ca-certificates \
        tzdata \
        dumb-init \
        apache2-utils && \
    update-ca-certificates

RUN adduser -D -h /home/container container && \
    mkdir -p /home/container /home/container/registry /etc/docker/registry && \
    chown -R container:container /home/container /etc/docker/registry

COPY --chown=container:container registry-config.yml /etc/docker/registry/config.yml
COPY --chown=root:root entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

USER container
WORKDIR /home/container

EXPOSE 5000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]
