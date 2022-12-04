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
name := "$(shell basename $(CURDIR) | tr '[A-Z]' '[a-z]')"
DOCKER_USER ?=
DOCKER_TOKEN ?=

# Tag
tag:="$(shell git rev-parse --short HEAD)"

# Repository info
isGitRepoDirty := "$(shell git status --porcelain)"

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
	${Q}echo "Building '${name}'"
	${Q}docker build --rm ${dockerBuildQuiet} \
                      -t ${name}:${tag} \
                      -t ${name}:latest \
                      .

.PHONY: push
push: build
	${Q}status=$$(git status --porcelain); \
	if [ ! -z "$${status}" ]; \
	then \
		echo "ERROR: Working directory is dirty!"; \
		exit 1; \
	fi
	${Q}echo "Logging to dockerhub"
ifeq ("${DOCKER_USER}","")
	${Q}echo "DOCKER_USERNAME is not set"
	exit 1
endif
ifeq ("${DOCKER_TOKEN}","")
	${Q}echo "Docker registry password:"
	${Q}docker login --username ${DOCKER_USER}
else
	${Q}echo "${DOCKER_TOKEN}" | docker login --username ${DOCKER_USER} --password-stdin
endif
	${Q}echo "Applying dockerhub tags to the local image"
	${Q}docker tag ${name}:${tag} ${DOCKER_USER}/${name}:${tag}
	${Q}docker tag ${name}:latest ${DOCKER_USER}/${name}:latest
	${Q}echo "Pushing '${DOCKER_USER}/${name}'"
	${Q}docker push ${DOCKER_USER}/${name}:${tag}
	${Q}docker push ${DOCKER_USER}/${name}:latest

.PHONY: run
run: build
	${Q}echo "Running '${name}'"
	${Q}docker run \
            --interactive --tty --rm \
            --net=host \
            --name=${name} \
            ${name}

.PHONY: remove
remove:
	${Q}echo "Removing '${name}'"
	${Q}docker stop ${name}
	${Q}docker rm ${name}

.PHONY: delete
delete:
	${Q}echo "Deleting '${name}'"
	${Q}docker image rm ${name}:${tag}
	${Q}docker image rm ${name}:latest
