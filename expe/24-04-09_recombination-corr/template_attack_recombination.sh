#!/bin/bash

# * Global variables

# ** Parameters

# Number of traces to use for profile creation.
NUM_TRACES_PROFILE=16000
# Number of traces to use for attack.
NUM_TRACES_ATTACK=1000
# Delimiters. Small window greatly increase profile computation speed.
START_POINT=0
END_POINT=0

# NOTE: Sampling rate is hardcoded in collect_*.sh scripts.
FS=8e6

# POIs algorithm.
POIS_ALGO="snr"

# ** Paths

PATH_DATASET_EXTERN="$PATH_DATASET/240309_custom_firmware_phase_eval_iq_norep_modgfsk"
PATH_EXPE="$PATH_PROJ/expe/24-04-09_recombination-corr"

# Output full logs for individual attacks.
LOG_OUTPUT="$PATH_EXPE/output.log"
LOG_OUTPUT_FILTERED="${LOG_OUTPUT/.log/_filtered.log}"

# Output CSV file for Python plot.
OUTFILE_CSV="$PATH_EXPE/attack_results.csv"
# Output PDF file for Python plot.
OUTFILE_PDF="${OUTFILE_CSV/.csv/.pdf}"

# Path of dataset used to create the profile.
TRAIN_SET="$PATH_DATASET_EXTERN/train"
# Base path of the profile.
PROFILE_PATH_BASE="$PATH_DATASET_EXTERN/profile"
# Pattern of the used profile.
PROFILE_PATH="${PROFILE_PATH_BASE}_{}_${NUM_TRACES_PROFILE}_${POIS_ALGO}"
# Path of dataset used to perform the attack.
ATTACK_SET="$PATH_DATASET_EXTERN/attack"

# * Functions

function attack_recombined() {
    # bruteforce="--bruteforce"
    # plot="--plot"
    echo "========================= $NUM_TRACES_ATTACK attack traces ========================="
    sc-attack $plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_ATTACK $bruteforce \
              attack-recombined $PROFILE_PATH --attack-algo pcc --variable p_xor_k --align --fs $FS
}

function iterate() {
    i_start=$1
    i_step=$2
    i_end=$(($3 - 1 ))
    # Iteration over number of traces.
    for num_traces in $(seq $i_start $i_step $i_end); do
        # Write number of traces.
        echo -n "$num_traces;" | tee -a "$OUTFILE_CSV"

        # Attack and extract:
        # 1) The sum of the hamming distance.
        # 1) The number of correct bytes.
        sc-attack --no-plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $num_traces \
                  attack-recombined $PROFILE_PATH --attack-algo pcc --variable p_xor_k --align --fs $FS 2>/dev/null \
            | grep -E 'HD SUM|CORRECT' \
            | cut -f 2 -d ':' \
            | tr -d ' ' \
            | tr '[\n]' '[;]' \
            | sed 's/2^//' \
            | sed 's/;$//' \
            | tee -a "$OUTFILE_CSV"

        echo "" | tee -a "$OUTFILE_CSV"
    done
}

# * Script

# Checkout corresponding branch in Screaming Channels PoC repo
(cd "$PATH_SCPOC" && git checkout feat-recombination-corr)

# ** Attacks

# TODO: Attack using recombination with major vote.
attack_recombined # | tee -a "$LOG_OUTPUT"
# grep -E "===|Best|Known|HD|SUCCESS|NUMBER|template_dir" "$LOG_OUTPUT" > $LOG_OUTPUT_FILTERED

# ** Get data for plot

# DONE:
# Create the CSV header.
# echo "trace_nb;correct_bytes_amp;hd_sum_amp;correct_bytes_phr;hd_sum_phr;correct_bytes_i_augmented;hd_sum_i_augmented;correct_bytes_q_augmented;hd_sum_q_augmented;correct_bytes_recombined;hd_sum_bytes_recombined" | tee "$OUTFILE_CSV"
# Iterate over number of traces to attack [START STEP END].
# iterate 10 15 4000

# ** Plot stored data

# DONE:
# python3 "$PATH_EXPE"/template_attack_recombination_plot.py "$OUTFILE_CSV" "$OUTFILE_PDF"
