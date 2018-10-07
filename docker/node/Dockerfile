FROM node:9.4-alpine

RUN apk add --no-cache su-exec && \
    addgroup bar && \
    adduser -D -h /home -s /bin/sh -G bar foo

COPY entrypoint.sh /entrypoint
RUN chmod +x /entrypoint

ENTRYPOINT ["/entrypoint"]