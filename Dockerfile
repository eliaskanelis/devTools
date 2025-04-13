#syntax=docker/dockerfile:1.12.1

# #############################################################################
# #############################################################################
# Base image

# https://hub.docker.com/_/ubuntu
ARG VERSION="24.04"

FROM ubuntu:${VERSION} AS base

# #############################################################################
# #############################################################################
# arm-none-eabi

FROM base AS arm-none-eabi_builder

# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
ARG ARM_NANO_EABI_VERSION=14.2.rel1

WORKDIR /workdir

RUN \
    apt-get update && \
    apt-get install --yes --no-install-recommends wget ca-certificates xz-utils && \
    rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ARCH="x86_64" ;; \
        arm64) ARCH="aarch64" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    wget -qO- "https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_NANO_EABI_VERSION}/binrel/arm-gnu-toolchain-${ARM_NANO_EABI_VERSION}-${ARCH}-arm-none-eabi.tar.xz" \
    | tar -xJ --strip-components=1

# #############################################################################
# #############################################################################
# wine

FROM base AS wine_builder

RUN \
    apt-get update && \
    apt-get install --yes --no-install-recommends wget gnupg2 ca-certificates

RUN apt-get update && \
    dpkg --add-architecture i386 && \
    mkdir -p /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    . /etc/os-release && \
    echo "deb [signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/ubuntu/ ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/winehq.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install --yes --no-install-recommends winehq-stable && \
    rm -rf /var/lib/apt/lists/*

# #############################################################################
# #############################################################################
# Production image

FROM base

# -----------------------------------------------------------------------------
# Packages to install

ARG PACKAGES="sudo bash wget curl git \
    build-essential bc file \
    cmake clang \
    cpputest pahole ccache valgrind dos2unix \
    astyle \
    python3 python3-pip python3-venv \
    clang-format clang-tidy \
    shellcheck cppcheck cflow pmccabe \
    doxygen graphviz"

RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install --yes --no-install-recommends ${PACKAGES} && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# cpputest

ENV CPPUTEST_HOME="/usr/"

# -----------------------------------------------------------------------------
# arm-none-eabi

COPY --from=arm-none-eabi_builder /workdir /arm-none-eabi
ENV PATH=/arm-none-eabi/bin/:${PATH}

# -----------------------------------------------------------------------------
# wine

COPY --from=wine_builder /opt/wine-stable/ /opt/wine-stable/
COPY --from=wine_builder /usr/bin/ /usr/bin/
COPY --from=wine_builder /usr/lib/ /usr/lib/

# -----------------------------------------------------------------------------
# USER

# ARG PUID="${UID:-1000}"
# ARG PGID="${GID:-1000}"
# ARG USERNAME="${USER:-tedi}"

# Create a new user on start
# RUN addgroup -g ${PGID} ${USERNAME}
# RUN adduser -u ${PUID} \
#             -G ${USERNAME} \
#             --shell /bin/bash \
#             --disabled-password \
#             -H ${USERNAME}

# RUN mkdir -p /home/${USERNAME}
# RUN chown ${USERNAME}:${USERNAME} /home/${USERNAME}
# WORKDIR /home/${USERNAME}
# USER ${USERNAME}

RUN echo "ubuntu ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ubuntu
USER ubuntu
ENV TERM=linux

# -----------------------------------------------------------------------------
# Wine

# Set Wine environment variables for headless operation
ENV WINEDEBUG=-all
ENV DISPLAY=:0
ENV XDG_RUNTIME_DIR=/tmp
# ENV WINEPREFIX=/home/ubuntu/.wine

# Create the Wine prefix (virtual Windows environment)
RUN wineboot --init

# -----------------------------------------------------------------------------
# Startup

WORKDIR /workspace
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash", "-i"]
