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

# ** Internals

# Base path used to store the attack csv.
CSV_PATH_BASE="${DATASET_PATH}/csv${PROCESSING_SUFFIX}_cra"

# Base path used to store the attack plots.
PLOT_PATH_BASE="${DATASET_PATH}/plots${PROCESSING_SUFFIX}_cra"

# Path of script directory.
SCRIPT_WD="$(dirname $(realpath $0))"
SCRIPT_NAME="$(basename $(realpath $0))"

# * Functions for CSV building

function attack() {
    # Get parameters.
    local i_start=$1
    local i_step=$2
    local i_end=$(( $3 - 1 ))
    local init_mode=$4 # [1 = Initialize CSV ; 0 = Append to CSV]
    # Set parameters.
    local csv_path=${CSV_PATH_BASE}/attack.csv

    if [[ "$init_mode" == 1 ]]; then
        # Safety-guard.
        if [[ -f "${csv_path}" ]]; then
            echo "[!] SKIP: Attack: File exists: ${csv_path}"
            return 0
        fi
        echo "INFO: Process: ${csv_path}"

        # Initialize directories.
        mkdir -p ${CSV_PATH_BASE}
        # Write CSV header.
        echo -n "trace_nb"                                                           | tee "${csv_path}"
        echo -n ";correct_bytes_amp;hd_sum_amp;log2(key_rank)_amp"                   | tee -a "${csv_path}"
        echo -n ";correct_bytes_phr;hd_sum_phr;log2(key_rank)_phr"                   | tee -a "${csv_path}"
        echo ";correct_bytes_recombined;hd_sum_recombined;log2(key_rank)_recombined" | tee -a "${csv_path}"
    fi
    
    # Iteration over number of traces.
    for num_traces_attack in $(seq $i_start $i_step $i_end); do
        # Write number of traces.
        echo -n "${num_traces_attack};" | tee -a "${csv_path}"
        
        # Attack and extract:
        # 1) The key rank
        # 2) The correct number of bytes.
        scaff --log --loglevel INFO cra --no-plot --norm --data-path "${ATTACK_SET}" --start-point "${PROFILE_START_POINT}" --end-point "${PROFILE_END_POINT}" --num-traces "${num_traces_attack}" --no-bruteforce --comp recombined 2>/dev/null \
            | grep -E 'CORRECT|HD SUM|actual rounded' \
            | cut -f 2 -d ':'                         \
            | tr -d ' '                               \
            | tr '[\n]' '[;]'                         \
            | sed 's/2^//g'                           \
            | sed 's/;$//'                            \
            | tee -a "${csv_path}"

        echo "" | tee -a "${csv_path}"
    done
}

# * Script

# Ensure SCAFF version.
git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF}"

# ** CSV

# [START ; STEP ; END ; INIT?]
# DONE:
# attack 4 1 300 1

# ** PDF

pdf_path="${PLOT_PATH_BASE}/attack_all.pdf"

# Safety-guard.
if [[ -f "${pdf_path}" ]]; then
    echo "[!] SKIP: Plot: File exists: ${pdf_path}"
    exit 0
fi
echo "INFO: Process: ${pdf_path}"

mkdir -p "${PLOT_PATH_BASE}"
"$(realpath ${SCRIPT_WD}/${SCRIPT_NAME/_cra.sh/.py})" "${CSV_PATH_BASE}" "${pdf_path}"
