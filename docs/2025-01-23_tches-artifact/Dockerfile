FROM ubuntu:22.04 AS ubuntu-phasesca
# Automatically answer Yes for APT questions.
ENV DEBIAN_FRONTEND=noninteractive

# Update the system, install basic tools and required dependencies.
RUN apt-get update && apt-get install -yq git vim python3 ipython3 python3-pip sudo wget unzip evince tmux soapysdr-tools python3-soapysdr x11-apps direnv
RUN pip3 install setuptools numpy==2.0.0 click==8.1.7 matplotlib==3.9.2 colorlog==6.8.2 tqdm==4.66.5 scipy==1.14.1 statsmodels==0.14.2 pycryptodome==3.20.0 tomli==2.2.1 PyQt5==5.15.10
RUN direnv hook bash >> ~/.bashrc

# Setup rootless user.
RUN useradd -ms /bin/bash rootless
RUN yes ertyerty | passwd rootless
# RUN mkdir -p /home/rootless
# RUN chown -R rootless:rootless /home/rootless
RUN usermod -aG sudo rootless
USER rootless
WORKDIR /home/rootless

# Allows accessing our user installed projects. 
ENV PATH="$PATH:/home/rootless/.local/bin"
# Download our projects.
RUN mkdir git
WORKDIR /home/rootless/git
RUN test -d phase_data && : || git clone https://github.com/pierreay/phase_data.git
RUN test -d soapyrx    && : || git clone https://github.com/pierreay/soapyrx.git
RUN test -d scaff      && : || git clone https://github.com/pierreay/scaff.git

# Update Pip (required to install our projects successfully).
RUN pip install -U pip
# Install SoapyRX.
WORKDIR /home/rootless/git/soapyrx
RUN pip install --user -e .
# Install SCAFF.
WORKDIR /home/rootless/git/scaff
RUN pip install --user -e .
# Install HEL.
WORKDIR /home/rootless/git/scaff
RUN chmod +x utils/install-hel.sh
RUN echo "ertyerty" | sudo -S utils/install-hel.sh

# Get the datasets.
WORKDIR /home/rootless
# TODO: Extract datasets.
# RUN --mount=type=bind,source=.,target=/host /bin/bash -c 'tar xjvf /host/240207_1-leak-pairing-10cm-anechoic-2.533e9-8e6_raw.tar.bz2 -C /'
# RUN --mount=type=bind,source=.,target=/host /bin/bash -c 'tar xjvf /host/240429_highdist_2lna_highgain_norep.tar.bz2 -C /'
