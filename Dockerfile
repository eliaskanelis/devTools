# #############################################################################
# #############################################################################
# Base image

# https://hub.docker.com/_/alpine
ARG VERSION="3.17.0"

FROM alpine:${VERSION} AS base

MAINTAINER Kanelis Ilias <hkanelhs@yahoo.gr>

# #############################################################################
# #############################################################################
# arm-none-eabi

FROM base AS arm-none-eabi_builder

# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
ARG ARM_NANO_EABI_VERSION=12.2.mpacbti-rel1

WORKDIR /workdir

RUN wget -qO- \
    https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_NANO_EABI_VERSION}/binrel/arm-gnu-toolchain-${ARM_NANO_EABI_VERSION}-$(uname -m)-arm-none-eabi.tar.xz \
    | tar xvJf - --strip-components=1

# #############################################################################
# #############################################################################
# Production image

FROM base

# -----------------------------------------------------------------------------
# Packages to install

# https://pkgs.alpinelinux.org/packages
ARG PACKAGES="bash wget curl git \
    gcompat \
    build-base ncurses \
    cmake clang \
    cpputest pahole ccache valgrind dos2unix \
    astyle \
    python3 py3-pip py3-virtualenv \
    shellcheck cppcheck \
    doxygen graphviz"

RUN apk update && apk add --no-cache ${PACKAGES}

# -----------------------------------------------------------------------------
# cpputest

ENV CPPUTEST_HOME "/usr/"

# -----------------------------------------------------------------------------
# arm-none-eabi

COPY --from=arm-none-eabi_builder /workdir /arm-none-eabi
ENV PATH=/arm-none-eabi/bin/:${PATH}

# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Startup

WORKDIR /workdir
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash", "-i"]
