#!/bin/bash

# * Environment

env="$(realpath $(dirname $0))/env.sh"
echo "INFO: Source file: $env"
source "$env"

# Safety-guard.
if [[ -z $ENV_FLAG ]]; then
    echo "ERROR: Environment can't been sourced!"
    exit 1
fi

# * Variables

# ** Configuration for the used profiles

# List of parameters for the used profiles.
COMP_LIST=(amp phr)
NUM_TRACES_LIST=(4000 8000 16000)
POIS_ALGO_LIST=(r snr)
POIS_NB_LIST=(1 2)

# Delimiters.
START_POINT=0
END_POINT=0

# Should we use an external profile?
PROFILE_EXTERNAL=0
PROFILE_EXTERNAL_PATH_BASE="${REPO_DATASET_PATH}/poc/240422_custom_firmware_highdist_2lna_highgain/profile"

# ** Configuration specific to the attack

NUM_TRACES_ATTACK_LIST=(200 700 2500 3500 10000 16000)

# ** Internals

# Path of dataset used for the attack.
ATTACK_SET="${DATASET_PATH}/attack"

# Base path used to fetch the created profile.
PROFILE_PATH_BASE="${DATASET_PATH}/profile"

# Base path used to store the attack log.
LOG_PATH_BASE="${DATASET_PATH}/logs"

# * Functions

function attack() {
    # Get parameters.
    comp=$1
    num_traces=$2
    pois_algo=$3
    pois_nb=$4
    num_traces_attack=$5
    # Set parameters.
    if [[ ${PROFILE_EXTERNAL} -eq 0 ]]; then
        profile_path=${PROFILE_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}
    else
        profile_path=${PROFILE_EXTERNAL_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}
    fi
    log_path=${LOG_PATH_BASE}/attack_${comp}_${num_traces}_${pois_algo}_${pois_nb}_${num_traces_attack}.log
    bruteforce="--no-bruteforce"
    plot="--no-plot"

    # Safety-guard.
    if [[ -f "${log_path}" ]]; then
        echo "[!] SKIP: Attack: File exists: ${log_path}"
        return 0
    elif [[ $(ls -alh ${ATTACK_SET} | grep -E "amp.*.npy" | wc -l) -lt ${num_traces_attack} ]]; then
        echo "[!] SKIP: Attack: Not enough traces: < ${num_traces}"
        return 0
    fi
    
    # Initialize directories.
    mkdir -p $LOG_PATH_BASE
    # Perform the attack.
    scaff $plot --norm --data-path $ATTACK_SET --start-point $START_POINT \
              --end-point $END_POINT --num-traces $num_traces_attack $bruteforce --comp $comp \
              attack $profile_path --attack-algo pcc --variable p_xor_k --align --fs $FS \
              | tee $log_path
}

# * Script

# Ensure SCAFF version.
git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF}"

for comp in "${COMP_LIST[@]}"; do
    for num_traces in "${NUM_TRACES_LIST[@]}"; do
        for pois_algo in "${POIS_ALGO_LIST[@]}"; do
            for pois_nb in "${POIS_NB_LIST[@]}"; do
                for num_traces_attack in "${NUM_TRACES_ATTACK_LIST[@]}"; do
                    attack $comp $num_traces $pois_algo $pois_nb $num_traces_attack
                done
            done
        done
    done
done
