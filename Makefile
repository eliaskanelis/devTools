SHELL:=bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.DEFAULT_GOAL = all

# -----------------------------------------------------------------------------
# Configs

# The name of the docker image must be lowercase
NAME:="$(shell basename $(CURDIR) | tr '[A-Z]' '[a-z]')"
USERNAME:="tedicreations"
DOCKER_IMAGE_NAME:="${USERNAME}/${NAME}"
TAG:="v0.0.0"

# -----------------------------------------------------------------------------
# Validations

DOCKER_EXISTS := $(shell command -v docker 2> /dev/null)
ifndef DOCKER_EXISTS
$(error "Please install 'docker'!")
endif

# -----------------------------------------------------------------------------
# Rules

.PHONY: all
all: build
	@:

.PHONY: build
build:
	@echo "Building '${DOCKER_IMAGE_NAME}'"
	@docker build --rm --quiet \
                      -t ${DOCKER_IMAGE_NAME}:latest \
                      -t ${DOCKER_IMAGE_NAME}:${TAG} \
                      .

.PHONY: push
push:
	@echo "Pushing '${DOCKER_IMAGE_NAME}'"
	@docker push ${DOCKER_IMAGE_NAME}:latest
	@docker push ${DOCKER_IMAGE_NAME}:${TAG}

.PHONY: run
run:
	@echo "Running '${DOCKER_IMAGE_NAME}' as '${NAME}'"
	@docker run \
            --interactive --tty --rm \
            --net=host \
            --name=${NAME} \
            ${DOCKER_IMAGE_NAME}

.PHONY: remove
remove:
	@echo "Removing '${DOCKER_IMAGE_NAME}'"
	@docker stop ${DOCKER_IMAGE_NAME}
	@docker rm ${DOCKER_IMAGE_NAME}

.PHONY: delete
delete:
	@echo "Deleting '${DOCKER_IMAGE_NAME}'"
	@docker image rm ${DOCKER_IMAGE_NAME}:latest
	@docker image rm ${DOCKER_IMAGE_NAME}:${TAG}
