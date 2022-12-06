# ----------------------------------------------------------
# Base image

ARG VERSION="3.17.0"

# https://hub.docker.com/_/alpine
FROM alpine:${VERSION}
MAINTAINER Kanelis Ilias <hkanelhs@yahoo.gr>

# ----------------------------------------------------------
# Packages to install

# https://pkgs.alpinelinux.org/packages
ARG PACKAGES="bash wget curl git \
              build-base cmake clang gcc-arm-none-eabi \
              cpputest pahole ccache valgrind dos2unix \
              astyle \
              python3 py3-pip py3-virtualenv \
              shellcheck cppcheck \
              doxygen graphviz"

RUN apk update && apk add --no-cache ${PACKAGES}

ENV CPPUTEST_HOME "/usr/"

# ----------------------------------------------------------
# USER

ARG PUID="${UID:-1000}"
ARG PGID="${GID:-1000}"
ARG USERNAME="${USER:-tedi}"

# Create a new user on start
RUN addgroup -g ${PGID} ${USERNAME}
RUN adduser -u ${PUID} \
            -G ${USERNAME} \
            --shell /bin/bash \
            --disabled-password \
            -H ${USERNAME}

RUN mkdir -p /home/${USERNAME}
RUN chown ${USERNAME}:${USERNAME} /home/${USERNAME}
WORKDIR /home/${USERNAME}
USER ${USERNAME}

# ----------------------------------------------------------
# Startup

ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["bash", "-i"]
