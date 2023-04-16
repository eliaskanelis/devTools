###############################################################################
# Base image

# https://hub.docker.com/_/alpine
ARG VERSION="3.17.0"

FROM alpine:${VERSION} AS base

MAINTAINER Kanelis Ilias <hkanelhs@yahoo.gr>

###############################################################################
# Cpputest

FROM base AS cpputest_builder

WORKDIR /cpputest

RUN apk add --no-cache git cmake build-base
RUN git clone --depth 1 --branch v4.0 https://github.com/cpputest/cpputest.git .
RUN cmake -B cpputest_build && cmake --build cpputest_build

RUN mkdir -p /result/lib && \
    cp /cpputest/cpputest_build/src/CppUTest/libCppUTest.a /result/lib && \
    cp /cpputest/cpputest_build/src/CppUTestExt/libCppUTestExt.a /result/lib && \
    cp -R /cpputest/include /result/

###############################################################################
# Main

FROM base

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

ENV CPPUTEST_HOME "/usr"
COPY --from=cpputest_builder /result/ ${CPPUTEST_HOME}

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
CMD ["/bin/bash", "-i"]
