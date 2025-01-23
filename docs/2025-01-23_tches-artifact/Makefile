# Create the Docker container from the image.
build: .datasetinit .dockerinit

# NOTE: When debugging this command, set progress to "plain" instead of "tty".
.dockerinit:
	docker buildx build . -t ubuntu-screaming_channels_ble --progress tty
	touch .dockerinit

# Check that datasets have been downloaded in current directory.
.datasetinit:
	@if [ ! -f 240207_1-leak-pairing-10cm-anechoic-2.533e9-8e6_raw.tar.bz2 ] || [ ! -f 240429_highdist_2lna_highgain_norep.tar.bz2 ]; then \
		echo [ERROR] Missing datasets! && exit 1; \
	else \
		echo [INFO] Datasets correctly found!; \
	fi	
	touch .datasetinit

# Get a shell into the Docker container.
shell:
	docker run -it --env=DISPLAY --net=host \
		ubuntu-screaming_channels_ble /bin/bash

# Clean our Docker images and containers.
clean:
	docker rmi -f ubuntu-screaming_channels_ble:latest
	rm .dockerinit
