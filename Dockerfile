# ----------------------------------------------------------
# Base image

# https://hub.docker.com/_/alpine
FROM alpine:3.17.0
MAINTAINER Kanelis Ilias <hkanelhs@yahoo.gr>

# ----------------------------------------------------------
# Packages to install

# https://pkgs.alpinelinux.org/packages
ARG PACKAGES="bash wget curl git \
              build-base clang gcc-arm-none-eabi \
              pahole ccache valgrind dos2unix \
              astyle \
              python3 py3-pip py3-virtualenv \
              shellcheck cppcheck \
              doxygen graphviz"

RUN apk update && apk add --no-cache ${PACKAGES}

# ----------------------------------------------------------
# Startup

CMD ["/bin/bash"]