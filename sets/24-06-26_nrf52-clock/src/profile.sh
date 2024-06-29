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

# * Variables

# Path of dataset used to create the profile.
TRAIN_SET="${DATASET_PATH}/train"

# Base path used to store the created profile.
PROFILE_PATH_BASE="${DATASET_PATH}/profile"

# * Functions

function profile() {
    # Get parameters.
    local comp="${1}"
    local num_traces="${2}"
    local pois_algo="${3}"
    local pois_nb="${4}"
    # Set parameters.
    local profile_path="${PROFILE_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}"
    local plot="--no-plot"
    local save_images="--save-images"

    # Safety-guard.
    if [[ -d "${profile_path}" ]]; then
        echo "[!] SKIP: Profile creation: Directory exists: ${profile_path}"
        return 0
    elif [[ $(ls -alh ${TRAIN_SET} | grep -E ".*_amp.npy" | wc -l) -lt "${num_traces}" ]]; then
        echo "[!] SKIP: Profile creation: Not enough traces: < ${num_traces}"
        return 0
    fi
    
    # Initialize directories.
    mkdir -p "${profile_path}"
    # Create the profile.
    scaff "${plot}" "${save_images}" --norm --data-path "${TRAIN_SET}" --start-point "${PROFILE_START_POINT}" --end-point "${PROFILE_END_POINT}" --num-traces "${num_traces}" --comp "${comp}" profile "${profile_path}" --pois-algo "${pois_algo}" --num-pois "${pois_nb}" --poi-spacing 2 --variable p_xor_k --align --fs "${COLLECT_FS}"
}

# * Script

# Ensure SCAFF version.
git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF}"

for comp in "${PROFILE_COMP_LIST[@]}"; do
    for num_traces in "${PROFILE_NUM_TRACES_LIST[@]}"; do
        for pois_algo in "${PROFILE_POIS_ALGO_LIST[@]}"; do
            for pois_nb in "${PROFILE_POIS_NB_LIST[@]}"; do
                profile "${comp}" "${num_traces}" "${pois_algo}" "${pois_nb}"
            done
        done
    done
done
