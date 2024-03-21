#!/bin/bash

function cp_if_missing() {
    file="$1"
    if [[ ! -f ./"$file" ]]; then
        cp "/home/drac/pro_storage/dataset/240305_custom_firmware_phase_eval_iq/attack/$1" .
    fi    
}

# DONE:
cp_if_missing amp__0.npy
cp_if_missing phr__0.npy
cp_if_missing i__0.npy
cp_if_missing q__0.npy
cp_if_missing i_augmented__0.npy
cp_if_missing q_augmented__0.npy
