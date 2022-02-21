FROM alpine:latest

ARG MIRAGE_VERSION=0.6.6

WORKDIR /opt/mirage

RUN set -ex && \
    apk update && \
    apk --no-cache add ca-certificates && \
    wget https://github.com/acidlemon/mirage-ecs/releases/download/v${MIRAGE_VERSION}/mirage-ecs_${MIRAGE_VERSION}_linux_amd64.tar.gz && \
    tar xvzf mirage-ecs_${MIRAGE_VERSION}_linux_amd64.tar.gz && \
    rm -f xvzf mirage-ecs_${MIRAGE_VERSION}_linux_amd64.tar.gz

COPY config.yml /opt/mirage/config.yml

ENV MIRAGE_LOG_LEVEL info
ENV MIRAGE_CONF config.yml

ENTRYPOINT ["/opt/mirage/mirage-ecs"]
