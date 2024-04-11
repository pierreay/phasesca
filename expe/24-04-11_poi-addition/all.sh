#!/bin/bash

# * Global variables

# ** Parameters

# Number of traces to use for profile creation.
NUM_TRACES_PROFILE=16000
# Number of traces to use for attack.
NUM_TRACES_ATTACK=2000
# Delimiters. Small window greatly increase profile computation speed.
START_POINT=0
END_POINT=0

# NOTE: Sampling rate is hardcoded in collect_*.sh scripts.
FS=8e6

# POIs algorithm.
POIS_ALGO="r"

# Attacked component.
COMP="amp"

# ** Paths

PATH_DATASET_EXTERN="$PATH_DATASET/240309_custom_firmware_phase_eval_iq_norep_modgfsk"
PATH_EXPE="$PATH_PROJ/expe/24-04-11_poi-addition"

# Output full logs for individual attacks.
LOG_OUTPUT="$PATH_EXPE/logs/output.log"

# Path of dataset used to create the profile.
TRAIN_SET="$PATH_DATASET_EXTERN/train"
# Base path of the profile.
PROFILE_PATH_BASE="$PATH_DATASET_EXTERN/profile"
# Pattern of the used profile.
PROFILE_PATH="${PROFILE_PATH_BASE}_${COMP}_${NUM_TRACES_PROFILE}_${POIS_ALGO}"
# Path of dataset used to perform the attack.
ATTACK_SET="$PATH_DATASET_EXTERN/attack"

# * Functions

function patch_recombination() {
    echo "INFO: Patch POI recombination function"
    (cd "$PATH_SCPOC" && sed -i 's/maxcpa\[bnum\]\[kguess\] = 1/maxcpa\[bnum\]\[kguess\] = 0/' experiments/src/screamingchannels/attack.py)
    (cd "$PATH_SCPOC" && sed -i 's/maxcpa\[bnum\]\[kguess\] \*= r/maxcpa\[bnum\]\[kguess\] \+= r/' experiments/src/screamingchannels/attack.py)
    (cd "$PATH_SCPOC" && git diff)
}

function unpatch_recombination() {
    echo "INFO: Unpatch POI recombination function"
    (cd "$PATH_SCPOC" && git restore experiments/src/screamingchannels/attack.py)
    (cd "$PATH_SCPOC" && git status)
}

# * Script

(cd "$PATH_SCPOC" && git checkout feat-recombination-corr)

# ** Profile creation using 1 POI

PROFILE_1POI="${PATH_DATASET_EXTERN}/profile_${COMP}_${NUM_TRACES_PROFILE}_${POIS_ALGO}_1poi"

if [[ ! -d ${PROFILE_1POI} ]]; then
    train_set="${PATH_DATASET_EXTERN}/train"
    mkdir -p "$PROFILE_1POI"
    sc-attack --plot --save-images --norm --data-path $train_set --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_PROFILE --comp ${COMP} profile $PROFILE_1POI --pois-algo $POIS_ALGO --num-pois 1 --poi-spacing 1 --variable p_xor_k --align --fs $FS
else
    echo "SKIP: Directory exists: $PROFILE_1POI"
fi

# ** Profile creation using 2 POIs

PROFILE_2POIS="${PATH_DATASET_EXTERN}/profile_${COMP}_${NUM_TRACES_PROFILE}_${POIS_ALGO}_2pois"

if [[ ! -d ${PROFILE_2POIS} ]]; then
    train_set="${PATH_DATASET_EXTERN}/train"
    mkdir -p "$PROFILE_2POIS"
    sc-attack --plot --save-images --norm --data-path $train_set --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_PROFILE --comp ${COMP} profile $PROFILE_2POIS --pois-algo $POIS_ALGO --num-pois 2 --poi-spacing 1 --variable p_xor_k --align --fs $FS
else
    echo "SKIP: Directory exists: $PROFILE_2POIS"
fi

# ** Attack using 1 POI

LOG_OUTPUT_1=${LOG_OUTPUT/.log/_1poi.log}
if [[ ! -f "$LOG_OUTPUT_1" ]]; then
    clear && mkdir -p "$(dirname ${LOG_OUTPUT})"
    sc-attack --no-plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_ATTACK --no-bruteforce --comp ${COMP} \
              attack $PROFILE_1POI --attack-algo pcc --variable p_xor_k --align --fs $FS --num-pois 1
    tmux capture-pane -pS - > $LOG_OUTPUT_1
else
    echo "SKIP: File exists: $LOG_OUTPUT_1"
fi

# ** Attack using 2 POIs using multiplication

LOG_OUTPUT_2=${LOG_OUTPUT/.log/_2pois_mul.log}
if [[ ! -f "$LOG_OUTPUT_2" ]]; then
    clear && mkdir -p "$(dirname ${LOG_OUTPUT})"
    sc-attack --no-plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_ATTACK --no-bruteforce --comp ${COMP} \
              attack $PROFILE_2POIS --attack-algo pcc --variable p_xor_k --align --fs $FS --num-pois 2
    tmux capture-pane -pS - > $LOG_OUTPUT_2
else
    echo "SKIP: File exists: $LOG_OUTPUT_2"
fi

# ** Attack using 2 POIs using addition

LOG_OUTPUT_3=${LOG_OUTPUT/.log/_2pois_add.log}
if [[ ! -f "$LOG_OUTPUT_3" ]]; then
    clear && mkdir -p "$(dirname ${LOG_OUTPUT})"
    patch_recombination
    
    sc-attack --no-plot --norm --data-path $ATTACK_SET --start-point $START_POINT --end-point $END_POINT --num-traces $NUM_TRACES_ATTACK --no-bruteforce --comp ${COMP} \
              attack $PROFILE_2POIS --attack-algo pcc --variable p_xor_k --align --fs $FS --num-pois 2
    tmux capture-pane -pS - > $LOG_OUTPUT_3

    unpatch_recombination
else
    echo "SKIP: File exists: $LOG_OUTPUT_3"
fi
