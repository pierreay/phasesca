#!/bin/bash

SCRIPT_WD="$(dirname $(realpath $0))"

function ff() {
    subdir=ff
    # Wideband analysis
    # DONE:
    export G=76; export SR=56e6; export FC=2.545e9; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db.npy --plot --no-cut --gain=$G
    # DONE:
    export G=76; export SR=56e6; export FC=2.500e9; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db.npy --plot --no-cut --gain=$G

    # Phase analysis under 2nd harmonic
    # DONE:
    export G=76; export SR=8e6; export FC=2.510e9; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db.npy --plot --no-cut --gain=$G
    # DONE:
    export G=76; export SR=8e6; export FC=2.512e9; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db.npy --plot --no-cut --gain=$G
    # DONE:
    export G=76; export SR=8e6; export FC=2.512e9; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db_dcdc-on.npy --plot --no-cut --gain=$G

    # Phase analysis at carrier
    # DONE:
    export G=40; export SR=5e6; export FC=2.400e9; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db.npy --plot --no-cut --gain=$G
    # DONE:
    export G=40; export SR=5e6; export FC=2.400e9; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db_dcdc-on.npy --plot --no-cut --gain=$G
}

function nf() {
    subdir=nf
    # DONE:
    export G=76; export SR=8e6; export FC=138e6; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db.npy --plot --no-cut --gain=$G
    # DONE:
    export G=76; export SR=30e6; export FC=128e6; ./radio.py record $FC $SR --duration=0.5 --save $SCRIPT_WD/$subdir/FC_${FC}_SR_${SR}_${G}db.npy --plot --no-cut --gain=$G
}

# DONE:
# ff
# DONE:
# nf
