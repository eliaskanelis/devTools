SHELL:=bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.DEFAULT_GOAL = all

# -----------------------------------------------------------------------------
# Validations

DOCKER_EXISTS := $(shell command -v docker 2> /dev/null)
ifndef DOCKER_EXISTS
$(error "Please install 'docker'!")
endif

GIT_EXISTS := $(shell command -v git 2> /dev/null)
ifndef DOCKER_EXISTS
$(error "Please install 'git'!")
endif

# -----------------------------------------------------------------------------
# Configs

# The name of the docker image must be lowercase
NAME:="$(shell basename $(CURDIR) | tr '[A-Z]' '[a-z]')"
USERNAME:="tedicreations"
DOCKER_IMAGE_NAME:="${USERNAME}/${NAME}"

# Tag
arch:=$(shell uname --processor)
git_comit:="$(shell git rev-parse --short HEAD)"
TAG:="${arch}_${git_comit}"

# Beautify output
ifeq ("$(origin V)", "command line")
  VERBOSE := $(V)
endif
ifndef VERBOSE
  VERBOSE := 0
endif

ifeq ($(VERBOSE),1)
  dockerBuildQuiet :=
  Q :=
else
  dockerBuildQuiet := --quiet
  Q := @
endif

# -----------------------------------------------------------------------------
# Rules

.PHONY: all
all: build
	@:

.PHONY: build
build:
	${Q}echo "Building '${DOCKER_IMAGE_NAME}'"
	${Q}docker build --rm ${dockerBuildQuiet} \
                      -t ${DOCKER_IMAGE_NAME}:${TAG} \
                      -t ${DOCKER_IMAGE_NAME}:latest \
                      .

.PHONY: push
push:
	${Q}echo "Pushing '${DOCKER_IMAGE_NAME}'"
	${Q}docker push ${DOCKER_IMAGE_NAME}:${TAG}
	${Q}docker push ${DOCKER_IMAGE_NAME}:latest

.PHONY: run
run: build
	${Q}echo "Running '${DOCKER_IMAGE_NAME}' as '${NAME}'"
	${Q}docker run \
            --interactive --tty --rm \
            --net=host \
            --name=${NAME} \
            ${DOCKER_IMAGE_NAME}

.PHONY: remove
remove:
	${Q}echo "Removing '${DOCKER_IMAGE_NAME}'"
	${Q}docker stop ${DOCKER_IMAGE_NAME}
	${Q}docker rm ${DOCKER_IMAGE_NAME}

.PHONY: delete
delete:
	${Q}echo "Deleting '${DOCKER_IMAGE_NAME}'"
	${Q}docker image rm ${DOCKER_IMAGE_NAME}:${TAG}
	${Q}docker image rm ${DOCKER_IMAGE_NAME}:latest
