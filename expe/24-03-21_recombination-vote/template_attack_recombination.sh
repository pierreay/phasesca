#!/bin/bash

# * Parameters

# ** Paths

PATH_DATASET_EXTERN="$PATH_DATASET/240309_custom_firmware_phase_eval_iq_norep_modgfsk"
PATH_EXPE="$PATH_PROJ/expe/24-03-21_recombination-vote"

# Output full logs for individual attacks.
LOG_OUTPUT="$PATH_EXPE/output.log"
LOG_OUTPUT_FILTERED="${LOG_OUTPUT/.log/_filtered.log}"

# Output CSV files for Python plots.
LOG_CSV="$PATH_EXPE/attack_results.csv"

# Path of dataset used to create the profile.
TRAIN_SET="$PATH_DATASET_EXTERN/train"
# Base path used to store the created profile.
PROFILE_PATH_BASE="$PATH_DATASET_EXTERN/profile"
# Path of dataset used to perform the attack.
ATTACK_SET="$PATH_DATASET_EXTERN/attack"

# ** Numbers

# Number of traces to use for profile creation.
NUM_TRACES_PROFILE=16000
# Number of traces to use for attack.
NUM_TRACES_ATTACK=1000
# Delimiters. Small window greatly increase profile computation speed.
START_POINT=0
END_POINT=0

# NOTE: Sampling rate is hardcoded in collect_*.sh scripts.
FS=8e6

# * Functions

function attack_recombined() {
    # bruteforce="--bruteforce"
    # plot="--plot"
    echo "========================= $NUM_TRACES_ATTACK attack traces ========================="
    pois_algo="snr"
    echo "pois_algo=$pois_algo"
    export PROFILE_PATH=${PROFILE_PATH_BASE}_{}_${NUM_TRACES_PROFILE}_${pois_algo}
    sc-attack $plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_ATTACK $bruteforce \
              attack-recombined $PROFILE_PATH --attack-algo pcc --variable p_xor_k --align --fs $FS
}

# * Script

# Checkout corresponding branch in Screaming Channels PoC repo
(cd "$PATH_SCPOC" && git checkout feat-recombination)

# ** Attacks

# DONE: Attack using recombination with major vote.
attack_recombined | tee -a "$LOG_OUTPUT"
grep -E "===|Best|Known|HD|SUCCESS|NUMBER" "$LOG_OUTPUT" > $LOG_OUTPUT_FILTERED

# ** Plot
