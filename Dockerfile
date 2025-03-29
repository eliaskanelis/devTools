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
    apt-get -y upgrade && \
    apt-get install -y bash wget tar xz-utils && \
    rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -qO- \
    https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_NANO_EABI_VERSION}/binrel/arm-gnu-toolchain-${ARM_NANO_EABI_VERSION}-$(uname -m)-arm-none-eabi.tar.xz \
    | tar xvJf - --strip-components=1

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
    apt-get install -y ${PACKAGES} && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# cpputest

ENV CPPUTEST_HOME="/usr/"

# -----------------------------------------------------------------------------
# arm-none-eabi

COPY --from=arm-none-eabi_builder /workdir /arm-none-eabi
ENV PATH=/arm-none-eabi/bin/:${PATH}

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
# Startup

WORKDIR /workdir
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash", "-i"]
