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
LOG_OUTPUT="$PATH_EXPE/logs/output.log"
LOG_OUTPUT_FILTERED="${LOG_OUTPUT/.log/_filtered.log}"

# Output CSV file for Python plot.
OUTFILE_CSV="$PATH_EXPE/logs/attack_results.csv"
# Output PDF file for Python plot.
OUTFILE_PDF="$PATH_EXPE/plots/attack_results_{}.pdf"

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
    corr_method=${4-"add"}
    # Iteration over number of traces.
    for num_traces in $(seq $i_start $i_step $i_end); do
        # Write number of traces.
        echo -n "$num_traces;" | tee -a "$OUTFILE_CSV"

        # Attack and extract:
        # 1) The sum of the hamming distance.
        # 1) The number of correct bytes.
        sc-attack --no-plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $num_traces \
                  attack-recombined $PROFILE_PATH --attack-algo pcc --variable p_xor_k --align --fs $FS --corr-method $corr_method 2>/dev/null                   \
            | grep -E 'CORRECT|HD SUM|actual rounded' \
            | cut -f 2 -d ':'                         \
            | tr -d ' '                               \
            | tr '[\n]' '[;]'                         \
            | sed 's/2^//g'                           \
            | sed 's/;$//'                            \
            | tee -a "$OUTFILE_CSV"

        echo "" | tee -a "$OUTFILE_CSV"
    done
}

# * Script

(cd "$PATH_SCPOC" && git checkout feat-recombination-corr)

# ** Single attack evaluation

if [[ ! -f "$LOG_OUTPUT" ]]; then
    clear && mkdir -p "$(dirname ${LOG_OUTPUT})"
    attack_recombined
    tmux capture-pane -pS - > $LOG_OUTPUT
    grep -E "===|Best|Known|HD|SUCCESS|NUMBER|template_dir|actual rounded|comp=" "${LOG_OUTPUT}" > "${LOG_OUTPUT_FILTERED}"
else
    echo "SKIP: File exists: $LOG_OUTPUT"
fi

# ** Sweep attacks for plot

if [[ ! -f ${OUTFILE_CSV} ]]; then
    # Create the CSV header.
    echo -n "trace_nb"                                                           | tee "$OUTFILE_CSV"
    echo -n ";correct_bytes_amp;hd_sum_amp;log2(key_rank)_amp"                   | tee -a "$OUTFILE_CSV"
    echo -n ";correct_bytes_phr;hd_sum_phr;log2(key_rank)_phr"                   | tee -a "$OUTFILE_CSV"
    echo ";correct_bytes_recombined;hd_sum_recombined;log2(key_rank)_recombined" | tee -a "$OUTFILE_CSV"
    # Iterate over number of traces to attack [START STEP END].
    iterate 10 15 4000
else
    echo "SKIP: File exists: ${OUTFILE_CSV}"
fi

# ** Plot stored data

if [[ ! -f ${OUTFILE_PDF/'{}'/hd} ]]; then
    mkdir -p "$(dirname ${OUTFILE_PDF})"
    python3 "$PATH_EXPE"/plot.py "$OUTFILE_CSV" "$OUTFILE_PDF"
else
    echo "SKIP: File exists: ${OUTFILE_PDF/'{}'/hd}"
fi

# * Dirty code tested only once (to delete or refactor when copying this script)

# ** Use the multiplication for "corr-method"

# Output CSV file for Python plot.
OUTFILE_CSV="$PATH_EXPE/logs/attack_results_corr-method_mul.csv"
# Output PDF file for Python plot.
OUTFILE_PDF="$PATH_EXPE/plots/attack_results_corr-method_mul_{}.pdf"

if [[ ! -f ${OUTFILE_CSV} ]]; then
    # Create the CSV header.
    echo -n "trace_nb"                                                           | tee "$OUTFILE_CSV"
    echo -n ";correct_bytes_amp;hd_sum_amp;log2(key_rank)_amp"                   | tee -a "$OUTFILE_CSV"
    echo -n ";correct_bytes_phr;hd_sum_phr;log2(key_rank)_phr"                   | tee -a "$OUTFILE_CSV"
    echo ";correct_bytes_recombined;hd_sum_recombined;log2(key_rank)_recombined" | tee -a "$OUTFILE_CSV"
    # Iterate over number of traces to attack [START STEP END].
    iterate 10 250 4000 "mul"
else
    echo "SKIP: File exists: ${OUTFILE_CSV}"
fi

if [[ ! -f ${OUTFILE_PDF} ]]; then
    mkdir -p "$(dirname ${OUTFILE_PDF})"
    python3 "$PATH_EXPE"/plot.py "$OUTFILE_CSV" "$OUTFILE_PDF"
else
    echo "SKIP: File exists: ${OUTFILE_PDF}"
fi
