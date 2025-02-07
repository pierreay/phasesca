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

# * Functions

function attack() {
    # Get parameters.
    local num_traces_attack="${1}"
    local log_path_base="${LOG_PATH_BASE}_cra"
    local log_path="${log_path_base}/attack_${num_traces_attack}.log"
    local bruteforce="--no-bruteforce"
    local plot="--no-plot"

    # Safety-guard.
    if [[ -f "${log_path}" ]]; then
        log_info "Skip attack: File exists: ${log_path}"
        return 0
    elif [[ $(ls -alh ${ATTACK_SET} | grep -E ".*_amp.npy" | wc -l) -lt "${num_traces_attack}" ]]; then
        log_warn "Skip attack: Not enough traces: < ${num_traces_attac}"
        return 0
    fi
    
    # Initialize directories.
    mkdir -p "${log_path_base}"
    # Perform the attack.
    scaff --log --loglevel INFO cra "${plot}" --norm --data-path "${ATTACK_SET}" --start-point "${PROFILE_START_POINT}" --end-point "${PROFILE_END_POINT}" --num-traces "${num_traces_attack}" "${bruteforce}" --comp recombined 2>&1 | tee "${log_path}"
}

# * Script

# Ensure SCAFF version.
git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF_CRA}"

for num_traces_attack in "${ATTACK_NUM_TRACES_LIST[@]}"; do
    attack "${num_traces_attack}"
done
