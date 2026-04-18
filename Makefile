# -----------------------------------------------------------------------------
#  MAKEFILE RUNNING COMMAND
# -----------------------------------------------------------------------------
#  Author     : DevOps Engineer (support@devopscorner.id)
#  License    : Apache v2
# -----------------------------------------------------------------------------
# Notes:
# use [TAB] instead [SPACE]

export PATH_WORKSPACE="src"
export PATH_SCRIPT="scripts"
export PATH_COMPOSE="compose"
export PATH_DOCKER="$(PATH_COMPOSE)/docker"
export PATH_HELM="$(PATH_COMPOSE)/helm"
export PROJECT_NAME="container"
export AWS_DEFAULT_REGION="ap-southeast-1"

export CI_REGISTRY     ?= $(ARGS).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
export CI_PROJECT_PATH ?= devopscorner
export CI_PROJECT_NAME ?= cicd

IMAGE   = $(CI_REGISTRY)/${CI_PROJECT_PATH}/${CI_PROJECT_NAME}
DIR     = $(shell pwd)
VERSION ?= 1.3.0

export BASE_IMAGE=alpine
export BASE_VERSION=3.17

export ALPINE_VERSION=3.17
export UBUNTU_VERSION=22.04
export CODEBUILD_VERSION=4.0

# ==================== #
#   CONTAINER UBUNTU   #
# ==================== #
.PHONY: run stop remove build push push-container
run:
	@echo "========================================================"
	@echo " Task      : Docker Container "
	@echo " Date/Time : `date`"
	@echo "========================================================"
	@./run-docker.sh
	@echo '- DONE -'

stop:
	@echo "========================================================"
	@echo " Task      : Stopping Docker Container "
	@echo " Date/Time : `date`"
	@echo "========================================================"
	@docker-compose -f ${PATH_COMPOSE}/app-compose.yml stop
	@echo '- DONE -'

.PHONY: build-ubuntu push-ubuntu push-container-ubuntu
# ./dockerhub-build.sh Dockerfile [DOCKERHUB_IMAGE_PATH] [alpine|ubuntu|codebuild] [version|latest|tags] [custom-tags]
build-ubuntu:
	@echo "========================================================"
	@echo " Task      : Create Container Image Ubuntu "
	@echo " Date/Time : `date`"
	@echo "========================================================"
	@cd ${PATH_DOCKER}/ubuntu && ./docker-build.sh Dockerfile $(CI_PATH) ubuntu ${UBUNTU_VERSION}
	@echo '- DONE -'

# ./dockerhub-push.sh [DOCKERHUB_IMAGE_PATH] [alpine|ubuntu|codebuild|version|latest|tags|custom-tags]
push-ubuntu:
	@echo "========================================================"
	@echo " Task      : Push Container Image Ubuntu"
	@echo " Date/Time : `date`"
	@echo "========================================================"
	@cd ${PATH_DOCKER}/ubuntu && ./docker-push.sh $(CI_PATH) ubuntu
	@echo '- DONE -'

# ./dockerhub-push.sh [DOCKERHUB_IMAGE_PATH] [alpine|ubuntu|codebuild|version|latest|tags|custom-tags]
build-push-ubuntu:
	@echo "========================================================"
	@echo " Task      : Build & Push Container Image Ubuntu "
	@echo " Date/Time : `date`"
	@echo "========================================================"
	@cd ${PATH_DOCKER}/ubuntu && ./docker-build
