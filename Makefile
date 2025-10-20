# Example Makefile for a LazyCAT Apps project
# Copy this file to your project and customize the variables below

# Project configuration
# PROJECT_NAME ?= your-project  # defaults to current directory name
# Project type (lpk-only | docker-lpk)
PROJECT_TYPE ?= docker-lpk
APP_ID_PREFIX = cloud.lazycat.app.liu.

# Version (optional, auto-detected from git if not set)
# VERSION := 1.0.0

# Docker configuration (only for docker-lpk projects)
# REGISTRY := docker.io/lazycatapps
# IMAGE_NAME := $(PROJECT_NAME)

# Anki-specific configuration
ANKI_VERSION ?= 25.09

# Docker build arguments - passed to base.mk's docker-build
DOCKER_BUILD_EXTRA_ARGS := --build-arg commit_id=$(shell git rev-parse HEAD || echo "dev") \
                           --build-arg ANKI_VERSION=$(ANKI_VERSION)

# Container runtime configuration
VNC_PORT ?= 3000
ANKI_CONNECT_PORT ?= 8765
DATA_DIR ?= $(PWD)/anki_data

# Docker run arguments
DOCKER_RUN_ARGS := -p $(VNC_PORT):3000 \
                   -p $(ANKI_CONNECT_PORT):8765 \
                   -v $(DATA_DIR):/config \
                   --restart unless-stopped

# Include the common base.mk
include base.mk

# You can add custom targets below
# Example:
# .PHONY: custom-target
# custom-target: ## My custom target
#	@echo "Running custom target"

.PHONY: run
run: ## Run container locally with data volume
	@mkdir -p $(DATA_DIR)
	@$(MAKE) run-default
	@echo "VNC access: http://localhost:$(VNC_PORT)"
	@echo "AnkiConnect port: $(ANKI_CONNECT_PORT)"
	@echo "Data directory: $(DATA_DIR)"
