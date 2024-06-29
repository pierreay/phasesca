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

# Should we use an external profile?
PROFILE_EXTERNAL=0

# Path of dataset used for the attack.
ATTACK_SET="${DATASET_PATH}/attack"

# Base path used to store the attack log.
LOG_PATH_BASE="${DATASET_PATH}/logs"

# * Functions

function attack() {
    # Get parameters.
    local comp="${1}"
    local num_traces="${2}"
    local pois_algo="${3}"
    local pois_nb="${4}"
    local num_traces_attack="${5}"
    # Set parameters.
    if [[ ${PROFILE_EXTERNAL} -eq 0 ]]; then
        local profile_path="${PROFILE_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}"
    else
        # NOTE: To be filled if needed.
        local profile_path=""
    fi
    local log_path="${LOG_PATH_BASE}/attack_${comp}_${num_traces}_${pois_algo}_${pois_nb}_${num_traces_attack}.log"
    local bruteforce="--no-bruteforce"
    local plot="--no-plot"

    # Safety-guard.
    if [[ -f "${log_path}" ]]; then
        log_info "Skip attack: File exists: ${log_path}"
        return 0
    elif [[ $(ls -alh ${ATTACK_SET} | grep -E ".*_amp.npy" | wc -l) -lt "${num_traces_attack}" ]]; then
        log_warn "Skip attack: Not enough traces: < ${num_traces}"
        return 0
    fi
    
    # Initialize directories.
    mkdir -p "${LOG_PATH_BASE}"
    # Perform the attack.
    scaff "${plot}" --norm --data-path "${ATTACK_SET}" --start-point "${PROFILE_START_POINT}" \
              --end-point "${PROFILE_END_POINT}" --num-traces "${num_traces_attack}" "${bruteforce}" --comp "${comp}" \
              attack "${profile_path}" --attack-algo pcc --variable p_xor_k --align --fs "${COLLECT_FS}" \
              | tee "${log_path}"
}

# * Script

# Ensure SCAFF version.
git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF}"

for comp in "${PROFILE_COMP_LIST[@]}"; do
    for num_traces in "${PROFILE_NUM_TRACES_LIST[@]}"; do
        for pois_algo in "${PROFILE_POIS_ALGO_LIST[@]}"; do
            for pois_nb in "${PROFILE_POIS_NB_LIST[@]}"; do
                for num_traces_attack in "${ATTACK_NUM_TRACES_LIST[@]}"; do
                    attack "${comp}" "${num_traces}" "${pois_algo}" "${pois_nb}" "${num_traces_attack}"
                done
            done
        done
    done
done
