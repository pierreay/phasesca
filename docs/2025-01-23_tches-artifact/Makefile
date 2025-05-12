# Name of the Docker image.
DOCKER_NAME = ubuntu-phasesca
# Path to the mount on the host.
DOCKER_LMOUNT =

# User name, UID and GID that will be used for the container user.
DOCKER_USER = $(shell id -u -n)
DOCKER_UID  = $(shell id -u)
DOCKER_GID  = $(shell id -g)

# Path to the mount under the guest container.
DOCKER_RMOUNT = /home/$(DOCKER_USER)/host_dir

# Create the required variables are set.
.PHONY: check-env
check-env:
ifndef DOCKER_LMOUNT
	$(error DOCKER_LMOUNT is undefined)
endif

# Create the Docker container from the image.
build: .dockerinit

# When debugging this command, set progress to "plain" instead of "tty".
.dockerinit:
	docker buildx build . \
		--build-arg=DOCKER_USER=$(DOCKER_USER) \
		--build-arg=DOCKER_UID=$(DOCKER_UID) --build-arg=DOCKER_GID=$(DOCKER_GID) \
		-t $(DOCKER_NAME) --progress tty
	touch .dockerinit

# Get a shell into the Docker container.
.PHONY: shell
shell: check-env
	docker run -it \
		--env=DISPLAY --net=host \
		-v $(DOCKER_LMOUNT):$(DOCKER_RMOUNT) \
		$(DOCKER_NAME) /bin/bash

# Clean our Docker images and containers.
.PHONY: clean
clean:
	docker container ls --all | grep $(DOCKER_NAME) | awk '{print $$1}' | xargs -n1 -r docker container rm
	docker image rm $(DOCKER_NAME):latest
	rm .dockerinit

