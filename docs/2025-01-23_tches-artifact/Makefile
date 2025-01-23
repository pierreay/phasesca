DOCKER_NAME = ubuntu-phasesca

# Create the Docker container from the image.
build: .datasetinit .dockerinit

# When debugging this command, set progress to "plain" instead of "tty".
.dockerinit:
	docker buildx build . -t $(DOCKER_NAME) --progress tty
	touch .dockerinit

# Check that datasets have been downloaded in current directory.
.datasetinit:
	# TODO: Check for datasets.
	# @if [ ! -f 240207_1-leak-pairing-10cm-anechoic-2.533e9-8e6_raw.tar.bz2 ] || [ ! -f 240429_highdist_2lna_highgain_norep.tar.bz2 ]; then \
	# 	echo [ERROR] Missing datasets! && exit 1; \
	# else \
	# 	echo [INFO] Datasets correctly found!; \
	# fi	
	touch .datasetinit

# Get a shell into the Docker container.
shell:
	docker run -it --env=DISPLAY --net=host \
		$(DOCKER_NAME) /bin/bash

# Clean our Docker images and containers.
clean:
	docker rmi -f $(DOCKER_NAME):latest
	rm .dockerinit
