#!/bin/bash

file=FC_128e6_SR_30e6_76db.npy

# DONE: On Saren:
if [[ ! -f ./$file ]]; then
    cp /home/drac/storage/dataset/experiments/2024-02-06_firmware-instrumentation-for-phase-rot-leak/nf/$file .
fi

