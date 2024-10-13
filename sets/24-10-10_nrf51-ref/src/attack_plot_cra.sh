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

# Should we use an external profile?
PROFILE_EXTERNAL=0
PROFILE_EXTERNAL_PATH_BASE="${REPO_DATASET_PATH}/poc/240422_custom_firmware_highdist_2lna_highgain/profile"

# ** Internals

# Base path used to store the attack csv.
CSV_PATH_BASE="${DATASET_PATH}/csv${PROCESSING_SUFFIX}"

# Base path used to store the attack plots.
PLOT_PATH_BASE="${DATASET_PATH}/plots${PROCESSING_SUFFIX}"

# Path of script directory.
SCRIPT_WD="$(dirname $(realpath $0))"
SCRIPT_NAME="$(basename $(realpath $0))"

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
        # profile_path=${PROFILE_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}
        profile_path=${PROFILE_PATH_BASE}/\{\}_${num_traces}_${pois_algo}_${pois_nb}
    else
        # profile_path=${PROFILE_EXTERNAL_PATH_BASE}/${comp}_${num_traces}_${pois_algo}_${pois_nb}
        profile_path=${PROFILE_EXTERNAL_PATH_BASE}/\{\}_${num_traces}_${pois_algo}_${pois_nb}
    fi
    # csv_path=${CSV_PATH_BASE}/attack_${comp}_${num_traces}_${pois_algo}_${pois_nb}.csv
    csv_path=${CSV_PATH_BASE}/attack_${num_traces}_${pois_algo}_${pois_nb}.csv

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
        echo -n "trace_nb"                                                           | tee "${csv_path}"
        echo -n ";correct_bytes_amp;hd_sum_amp;log2(key_rank)_amp"                   | tee -a "${csv_path}"
        echo -n ";correct_bytes_phr;hd_sum_phr;log2(key_rank)_phr"                   | tee -a "${csv_path}"
        echo ";correct_bytes_recombined;hd_sum_recombined;log2(key_rank)_recombined" | tee -a "${csv_path}"
    fi
    
    # Iteration over number of traces.
    for num_traces_attack in $(seq $i_start $i_step $i_end); do
        # Write number of traces.
        echo -n "${num_traces_attack};" | tee -a "$csv_path"
        
        # Attack and extract:
        # 1) The key rank
        # 2) The correct number of bytes.
        # scaff attack --no-plot --norm --data-path $ATTACK_SET --start-point $PROFILE_START_POINT --end-point $PROFILE_END_POINT --num-traces $num_traces_attack --comp $comp $profile_path --attack-algo pcc --variable p_xor_k --align --fs ${COLLECT_FS} 2>/dev/null \
        scaff attack-recombined --no-plot --norm --data-path $ATTACK_SET --start-point $PROFILE_START_POINT --end-point $PROFILE_END_POINT --num-traces $num_traces_attack --comp amp $profile_path --attack-algo pcc --variable p_xor_k --align --fs ${COLLECT_FS} --corr-method add 2>/dev/null \
            | grep -E 'CORRECT|HD SUM|actual rounded' \
            | cut -f 2 -d ':'                         \
            | tr -d ' '                               \
            | tr '[\n]' '[;]'                         \
            | sed 's/2^//g'                           \
            | sed 's/;$//'                            \
            | tee -a "$csv_path"

        echo "" | tee -a "$csv_path"
    done
}

# * Script

# Ensure SCAFF version.
git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF}"

# ** CSV

# for comp in "${PROFILE_COMP_LIST[@]}"; do
for num_traces in "${PROFILE_NUM_TRACES_LIST[@]}"; do
    for pois_algo in "${PROFILE_POIS_ALGO_LIST[@]}"; do
        for pois_nb in "${PROFILE_POIS_NB_LIST[@]}"; do
            # [START ; STEP ; END ; INIT_MODE]
            attack _ $num_traces $pois_algo $pois_nb 2 1 40 1
            # attack _ $num_traces $pois_algo $pois_nb 250 8 500 0
            # attack _ $num_traces $pois_algo $pois_nb 500 15 1000 0
            # attack _ $num_traces $pois_algo $pois_nb 1000 60 2000 0
            # attack _ $num_traces $pois_algo $pois_nb 2000 200 10000 0
        done
    done
done
# done

# ** PDF

pdf_path="${PLOT_PATH_BASE}/attack_all.pdf"

# Safety-guard.
if [[ -f "${pdf_path}" ]]; then
    echo "[!] SKIP: Plot: File exists: ${pdf_path}"
    exit 0
fi
echo "INFO: Process: ${pdf_path}"

mkdir -p "${PLOT_PATH_BASE}"
"$(realpath ${SCRIPT_WD}/${SCRIPT_NAME/.sh/.py})" "${CSV_PATH_BASE}" "${pdf_path}"
