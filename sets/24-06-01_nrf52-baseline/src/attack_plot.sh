#!/bin/bash

# * Environment

env="$(realpath $(dirname $0))/env.sh"
echo "INFO: Source file: $env"
source "$env"

# * Variables

# ** Configuration for the used profiles

# Dataset path.
if [[ -z $DATASET_PATH ]]; then
    echo "ERROR: DATASET_PATH is unset!"
    exit 1
fi

# List of parameters for the used profiles.
COMP_LIST=(amp phr)
NUM_TRACES_LIST=(4000 8000 16000)
POIS_ALGO_LIST=(r)
POIS_NB_LIST=(1)

# Delimiters.
START_POINT=0
END_POINT=0

# Should we use an external profile?
PROFILE_EXTERNAL=1
PROFILE_EXTERNAL_PATH_BASE="${REPO_DATASET_PATH}/poc/240422_custom_firmware_highdist_2lna_highgain/profile"

# ** Internals

# Path of dataset used for the attack.
ATTACK_SET="${DATASET_PATH}/attack"

# Base path used to fetch the created profile.
PROFILE_PATH_BASE="${DATASET_PATH}/profile"

# Base path used to store the attack csv.
CSV_PATH_BASE="${DATASET_PATH}/csv"

# Base path used to store the attack plots.
PLOT_PATH_BASE="${DATASET_PATH}/plots"

# Path of script directory.
SCRIPT_WD="$(dirname $(realpath $0))"

# * Functions for CSV building

function attack() {
    # Get parameters.
    comp=$1
    num_traces=$2
    pois_algo=$3
    pois_nb=$4
    i_start=$5
    i_step=$6
    i_end=$(( $7 - 1 ))
    init_mode=$8 # [1 = Initialize CSV ; 0 = Append to CSV]
    # Set parameters.
    if [[ ${PROFILE_EXTERNAL} -eq 0 ]]; then
        profile_path=${PROFILE_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}
    else
        profile_path=${PROFILE_EXTERNAL_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}
    fi
    csv_path=${CSV_PATH_BASE}/attack_${comp}_${num_traces}_${pois_algo}_${pois_nb}.csv

    if [[ "$init_mode" == 1 ]]; then
        # Safety-guard.
        if [[ -f "${csv_path}" ]]; then
            echo "[!] SKIP: Attack: File exists: ${csv_path}"
            return 0
        fi
        echo "INFO: Process: ${csv_path}"

        # Initialize directories.
        mkdir -p $CSV_PATH_BASE
        # Write CSV header.
        echo "trace_nb;correct_bytes;log2(key_rank)" | tee "${csv_path}"
    fi
    
    # Iteration over number of traces.
    for num_traces_attack in $(seq $i_start $i_step $i_end); do
        # Write number of traces.
        echo -n "${num_traces_attack};" | tee -a "$csv_path"

        # Attack and extract:
        # 1) The key rank
        # 2) The correct number of bytes.
        sc-attack --no-plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $num_traces_attack --comp $comp \
                  attack $profile_path --attack-algo pcc --variable p_xor_k --align --fs $FS 2>/dev/null \
            | grep -E 'actual rounded|CORRECT' \
            | cut -f 2 -d ':' \
            | tr -d ' ' \
            | tr '[\n]' '[;]' \
            | sed 's/2^//' \
            | sed 's/;$//' \
            | tee -a "$csv_path"

        echo "" | tee -a "$csv_path"
    done
}

# * Script

# ** CSV

for comp in "${COMP_LIST[@]}"; do
    for num_traces in "${NUM_TRACES_LIST[@]}"; do
        for pois_algo in "${POIS_ALGO_LIST[@]}"; do
            for pois_nb in "${POIS_NB_LIST[@]}"; do
                # [START ; STEP ; END ; INIT_MODE]
                attack $comp $num_traces $pois_algo $pois_nb 10 10 500 1
                attack $comp $num_traces $pois_algo $pois_nb 500 30 1000 0
                attack $comp $num_traces $pois_algo $pois_nb 1000 60 2000 0
                attack $comp $num_traces $pois_algo $pois_nb 2000 200 10000 0
            done
        done
    done
done

# ** PDF

pdf_path="${PLOT_PATH_BASE}/attack_all.pdf"

# Safety-guard.
if [[ -f "${pdf_path}" ]]; then
    echo "[!] SKIP: Plot: File exists: ${pdf_path}"
    exit 0
fi
echo "INFO: Process: ${pdf_path}"

mkdir -p "${PLOT_PATH_BASE}"
"$(realpath ${0/.sh/.py})" "${CSV_PATH_BASE}" "${pdf_path}"
