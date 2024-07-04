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

# ** Step 3: Extraction & Filtering

for indir in train attack; do
    if [[ "${ARG_SUBSET}" == "train" ]]; then
        outdir="${TRAIN_SET}"
    elif [[ "${ARG_SUBSET}" == "attack"]]; then
        outdir="${ATTACK_SET}"
    fi
    if [[ ! -d "${outdir}" ]]; then
        mkdir -p "${outdir}"
        cp -t "${outdir}" "${indir}/pt.txt" "${indir}/key.txt"
        scaff --config "${DATASET_PATH}/src/collect.toml" extract "${indir}" "${outdir}"
    else
        log_info "Skip extraction: Directory exists: ${outdir}"
    fi
done
