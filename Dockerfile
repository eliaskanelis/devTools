# ----------------------------------------------------------
# Base image

# https://hub.docker.com/_/alpine
FROM alpine:3.17.0

# ----------------------------------------------------------
# User inputs

ARG PUID="${UID:-1000}"
ARG PGID="${UID:-1000}"

# ----------------------------------------------------------
# Packages to install

ENV PACKAGES=
RUN apk update && apk add --no-cache ${PACKAGES}

# ----------------------------------------------------------
# Dev

# ENTRYPOINT ["bash"]
#CMD ["bash"]
