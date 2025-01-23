FROM ubuntu:22.04 AS ubuntu-phasesca
# Automatically answer Yes for APT questions.
ENV DEBIAN_FRONTEND=noninteractive

# Update the system, install basic tools and required dependencies.
RUN apt-get update && apt-get install -yq git vim python3-pip sudo wget unzip evince tmux soapysdr-tools python3-soapysdr x11-apps
RUN pip3 install setuptools numpy==2.0.0 click==8.1.7 matplotlib==3.9.2 colorlog==6.8.2 tqdm==4.66.5 scipy==1.14.1 statsmodels==0.14.2 pycryptodome==3.20.0

# TODO: Setup project env.
# Clone our project and create environment variables for it.
# ENV SC=/screaming_channels_ble
# ENV SC_SRC=/screaming_channels_ble/src
# ENV SC_DOCKER=/screaming_channels_ble/docs/demo_20240828_acsac
WORKDIR /root
# Download our projects.
RUN test -d phase_data && : || git clone https://github.com/pierreay/phase_data.git
RUN test -d soapyrx    && : || git clone https://github.com/pierreay/soapyrx.git
RUN test -d scaff      && : || git clone https://github.com/pierreay/scaff.git

# Install SoapyRX.
WORKDIR /root/soapyrx
RUN pip install --user .
# Install SCAFF.
WORKDIR /root/scaff
RUN pip install --user .
# Install HEL.
WORKDIR /root/scaff
RUN chmod +x utils/install-hel.sh
RUN utils/install-hel.sh

# Get the datasets.
WORKDIR /root
# TODO: Extract datasets.
# RUN --mount=type=bind,source=.,target=/host /bin/bash -c 'tar xjvf /host/240207_1-leak-pairing-10cm-anechoic-2.533e9-8e6_raw.tar.bz2 -C /'
# RUN --mount=type=bind,source=.,target=/host /bin/bash -c 'tar xjvf /host/240429_highdist_2lna_highgain_norep.tar.bz2 -C /'
