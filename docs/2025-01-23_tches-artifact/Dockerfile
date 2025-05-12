# Template: 4a045d95-227b-46ca-80b9-f279ce7ff162

FROM ubuntu:22.04 AS ubuntu-phasesca
# Automatically answer "yes" for `apt` questions.
ENV DEBIAN_FRONTEND=noninteractive

# Update the system, install basic tools and required dependencies.
RUN apt-get update && apt-get install -yq git vim python3 ipython3 python3-pip sudo wget unzip evince tmux tree soapysdr-tools python3-soapysdr x11-apps direnv texlive texlive-base texlive-latex-recommended texlive-latex-extra mlocate apt-file
RUN pip3 install setuptools numpy==2.0.0 click==8.1.7 matplotlib==3.9.2 colorlog==6.8.2 tqdm==4.66.5 scipy==1.14.1 statsmodels==0.14.2 pycryptodome==3.20.0 tomli==2.2.1 PyQt5==5.15.10
# Mitigate a segfault from Matplotlib/PyQT5 about missing library.
RUN apt-get update && apt-get install -yq libxcb* libxkb*
# Mitigate LaTeX complaining about missing `type1ec.sty`.
RUN apt-get update && apt-get install -yq cm-super-minimal

# Allows the Makefile to pass a user configuration that match the host user for
# seamless file sharing (mitigate permission errors).
ARG DOCKER_USER=rootless # User name.
ARG DOCKER_UID=1000      # User ID.
ARG DOCKER_GID=1000      # Group ID.

# Setup a rootless user matching configuration above with password `ertyerty`.
RUN groupadd -g $DOCKER_GID $DOCKER_USER
RUN useradd -u $DOCKER_UID -g $DOCKER_GID -ms /bin/bash $DOCKER_USER
RUN yes ertyerty | passwd $DOCKER_USER
RUN usermod -aG sudo $DOCKER_USER

# Log into the new user and set working directory to its HOME.
ENV HOME="/home/$DOCKER_USER"
USER $DOCKER_USER
WORKDIR $HOME

# User configuration.
RUN direnv hook bash >> $HOME/.bashrc

# Allows accessing our user installed projects. 
ENV PATH="$PATH:$HOME/.local/bin"
ENV LD_LIBRARY_PATH="/usr/local/lib"
# Set environment variables used by scripts of our projects, usually defined in a `.envrc` file.
ENV PATH_DATASET="$HOME/pro_storage/dataset"
ENV PATH_SCAFF="$HOME/git/scaff"
ENV PATH_SOAPYRX="$HOME/git/soapyrx"
# Download our projects.
RUN mkdir git
WORKDIR $HOME/git
RUN test -d phasesca && : || git clone https://github.com/pierreay/phasesca.git
RUN test -d soapyrx    && : || git clone https://github.com/pierreay/soapyrx.git
RUN test -d scaff      && : || git clone https://github.com/pierreay/scaff.git

# Update Pip (required to install our projects successfully).
RUN pip install -U pip
# Install SoapyRX.
WORKDIR $HOME/git/soapyrx
RUN pip install --user -e .
# Install SCAFF.
WORKDIR $HOME/git/scaff
RUN pip install --user -e .
# Install HEL.
WORKDIR $HOME/git/scaff
RUN chmod +x utils/install-hel.sh
RUN echo "ertyerty" | sudo -S utils/install-hel.sh

# Get the datasets.
WORKDIR $HOME
