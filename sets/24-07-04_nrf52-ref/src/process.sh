#!/bin/bash

# * Environment

env="$(realpath $(dirname $0))/env.sh"
source "$env"

# Safety-guard.
if [[ -z $ENV_FLAG ]]; then
    echo "ERROR: Environment can't been sourced!"
    exit 1
fi

log_info "Loaded environment: ${env}"

# * Script

mkdir -p train_1
cp -t train_1 train/pt.txt train/key.txt
scaff --config src/collect.toml extract train train_1 --avg-min=1 --avg-max=1 --cpu=-1 --corr-min=8.5e-1

mkdir -p attack_1
cp -t attack_1 attack/pt.txt attack/key.txt
scaff --config src/collect.toml extract attack attack_1 --avg-min=1 --avg-max=1 --cpu=-1 --corr-min=8.5e-1

mkdir -p train_filt
cp -t train_filt train/pt.txt train/key.txt
"$(realpath $(dirname $0))/process_filt.py" train train_filt src/collect.toml

mkdir -p attack_filt_lh1e6
cp -t attack_filt_lh1e6 attack/pt.txt attack/key.txt
"$(realpath $(dirname $0))/process_filt.py" attack attack_filt_lh1e6 src/collect.toml lh1e6

mkdir -p attack_filt_lh500e3
cp -t attack_filt_lh500e3 attack/pt.txt attack/key.txt
"$(realpath $(dirname $0))/process_filt.py" attack attack_filt_lh500e3 src/collect.toml lh500e3
