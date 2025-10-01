.PHONY: help build build-local run stop clean logs shell push deploy build-lpk deploy-lpk all

# Default configuration
DOCKER_USER ?= $(shell whoami)
IMAGE_NAME ?= anki-desktop-docker
IMAGE_TAG ?= latest
FULL_IMAGE ?= $(DOCKER_USER)/$(IMAGE_NAME):$(IMAGE_TAG)
PLATFORM ?= linux/amd64
CONTAINER_NAME ?= anki-desktop
ANKI_VERSION ?= 25.09

# Port configuration
VNC_PORT ?= 3000
ANKI_CONNECT_PORT ?= 8765

# Volume configuration
DATA_DIR ?= $(PWD)/data

# LPK configuration
LAZYCAT_BOX_NAME ?= mybox

HELP_FUN = \
	%help; while(<>){push@{$$help{$$2//'options'}},[$$1,$$3] \
	if/^([\w-_]+)\s*:.*\#\#(?:@(\w+))?\s(.*)$$/}; \
	print"\033[1m$$_:\033[0m\n", map"  \033[36m$$_->[0]\033[0m".(" "x(20-length($$_->[0])))."$$_->[1]\n",\
	@{$$help{$$_}},"\n" for keys %help; \

help: ##@General Show this help
	@echo -e "Usage: make \033[36m<target>\033[0m\n"
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

build: ##@Build Build Docker image for platform $(PLATFORM)
	@echo "Building image: $(FULL_IMAGE) for platform $(PLATFORM)"
	docker build --platform $(PLATFORM) \
		--build-arg commit_id=$(shell git rev-parse HEAD || echo "dev") \
		--build-arg ANKI_VERSION=$(ANKI_VERSION) \
		-t $(FULL_IMAGE) .
	@echo "Image built successfully!"

build-local: ##@Build Build Docker image for local platform
	@echo "Building image for local platform: $(FULL_IMAGE)"
	docker build \
		--build-arg commit_id=$(shell git rev-parse HEAD || echo "dev") \
		--build-arg ANKI_VERSION=$(ANKI_VERSION) \
		-t $(FULL_IMAGE) .
	@echo "Image built successfully!"

run: ##@Run Run container locally with data volume
	@echo "Starting Anki Desktop container..."
	@mkdir -p $(DATA_DIR)
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(VNC_PORT):3000 \
		-p $(ANKI_CONNECT_PORT):8765 \
		-v $(DATA_DIR):/config \
		--restart unless-stopped \
		$(FULL_IMAGE)
	@echo "Container started successfully!"
	@echo "VNC access: http://localhost:$(VNC_PORT)"
	@echo "AnkiConnect port: $(ANKI_CONNECT_PORT)"
	@echo "Data directory: $(DATA_DIR)"

stop: ##@Run Stop and remove container
	@echo "Stopping container..."
	-docker stop $(CONTAINER_NAME)
	-docker rm $(CONTAINER_NAME)
	@echo "Container stopped and removed!"

restart: stop run ##@Run Restart container

logs: ##@Run Show container logs
	docker logs -f $(CONTAINER_NAME)

shell: ##@Run Open shell in running container
	docker exec -it $(CONTAINER_NAME) /bin/bash

clean: stop ##@Maintenance Clean container and optionally volumes
	@echo "Container stopped and removed"
	@echo "Note: Data directory $(DATA_DIR) is preserved"
	@echo "To clean data, run: rm -rf $(DATA_DIR)"

clean-all: clean ##@Maintenance Clean container and data directory
	@echo "Removing data directory..."
	-rm -rf $(DATA_DIR)
	@echo "All cleaned!"

push: ##@Maintenance Push image to Docker Hub
	@echo "Pushing image: $(FULL_IMAGE)"
	docker push $(FULL_IMAGE)
	@echo "Image pushed successfully!"

build-lpk: ##@Build Build LPK package (requires lzc-cli)
	@echo "Building LPK package..."
	lzc-cli project build
	@echo "LPK package built successfully!"

deploy-lpk: build-lpk ##@Deploy Deploy LPK to local box
	@echo "Deploying LPK package..."
	@LPK_FILE=$$(ls -t *.lpk 2>/dev/null | head -n 1); \
	if [ -z "$$LPK_FILE" ]; then \
		echo "Error: No LPK file found"; \
		exit 1; \
	fi; \
	echo "Installing $$LPK_FILE..."; \
	lzc-cli app install "$$LPK_FILE"
	@echo "Deployment completed!"

deploy: build-local push build-lpk deploy-lpk ##@Deploy Full deployment (build + push + lpk)

all: deploy ##@Aliases Alias for deploy (default target)
