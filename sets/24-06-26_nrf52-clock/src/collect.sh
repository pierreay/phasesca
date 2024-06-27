#!/bin/bash

# * Environment

env="$(realpath $(dirname $0))/env.sh"
source "$env"

# Safety-guard.
if [[ -z $ENV_FLAG ]]; then
    echo "ERROR: Environment can't been sourced!"
    exit 1
fi

log_info "Loaded environment: ${env}"

# * Arguments

# Reset getopts.
OPTIND=1

# Set Python logging level.
OPT_LOGLEVEL="INFO"
# If set to 1, instruct to reboot in case of repeated errors.
OPT_REBOOT=0
# If set to 1, instruct to switch YKush down and up in case of error.
OPT_YKUSH=0
# If set to 1, instruct to restart collection from 0.
OPT_RESTART=0

# Program's help.
function help() {
    cat << EOF
Usage: collect.sh [-l LOGLEVEL] [-r] [-y] [-f]

Run a full collection and record it inside \$ENVRC_DATASET_RAW_PATH. It will
record \$ENVRC_WANTED_TRACE_TRAIN and \$ENVRC_WANTED_TRACE_ATTACK number of
traces.

Concerning the radio, the sampling rate will be set at \$ENVRC_SAMP_RATE and
frequencies at \$ENVRC_NF_FREQ and \$ENVRC_FF_FREQ. The recording will be of
duration \$ENVRC_DURATION. You can enable the recordings for NF and FF traces
using \$ENVRC_NF_ID and \$ENVRC_FF_ID, or set it to -1 to disable this
recording. The \$ENVRC_RADIO_DIR will be used as a temporary storage for the
recordings.

Concerning the target, it will be connected using the \$ENVRC_VICTIM_ADDR
address and the inputs will be configured using the \$ENVRC_VICTIM_PORT dev
port.

Set -l to the desired Python LOGLEVEL [default = INFO].
Set -r to reboot computer on repeated errors. Ignored if key is fixed in target device [default = False]
Set -y to reset YKush switch on repeated errors. Ignored if key is fixed in target device [default = False]
Set -f to restart collection from trace #0 without reinitializing the dataset [default = False].
EOF
    exit 0
}

# Get the scripts arguments.
while getopts "h?l:ryf" opt; do
    case "$opt" in
        h|\?)
            help
            ;;
        l) OPT_LOGLEVEL=$OPTARG
           ;;
        r) OPT_REBOOT=1
           ;;
        y) OPT_YKUSH=1
           ;;
        f) OPT_RESTART=1
           ;;
    esac
done

# * Variables

# If we are collecting a train set or an attack set.
# MODE="train"
# NUM_TRACES=${COLLECT_NUM_TRACES_TRAIN}
NUM_TRACES=${COLLECT_NUM_TRACES_ATTACK}
MODE="attack"

# Temporary collection path.
TARGET_PATH="${DATASET_PATH}/${MODE}"

# Reflash the custom firmware.
REFLASH_FIRMWARE=1

# Restart radio server.
RESTART_RADIO=1

# ** Internals

CALIBRATION_FLAG_PATH="${TARGET_PATH}/.calibration_done"
COLLECTION_FLAG_PATH="${TARGET_PATH}/.collection_started"

# * Functions

# ** Firmware

function flash_firmware_once() {
    firmware_src="${PATH_PHASEFW}/nrf52832/sc-poc/pca10040/blank/armgcc/_build/nrf52832_xxaa.hex"
    firmware_dst="${DATASET_PATH}/bin/nrf52832_xxaa.hex"
    if [[ -f "${firmware_dst}" ]]; then
        echo "SKIP: Flash firmware: File exists: ${firmware_dst}"
        return 0
    fi
    
    git_checkout_logged "${PATH_PHASEFW}" "${GIT_CHECKOUT_PHASEFW}"
    
    echo "INFO: Flash custom firmware..."
    cd ${PATH_PHASEFW}/nrf52832/sc-poc
    direnv exec . make -C pca10040/blank/armgcc flash
    echo "INFO: Save firmware: ${firmware_src} -> ${firmware_dst}"
    mkdir -p "$(dirname "$firmware_dst")" && cp "${firmware_src}" "${firmware_dst}"
    echo "DONE!"
}

# ** Configuration

function configure_param_json_escape_path() {
    # 1. Substitute "/" to "\/".
    # 2. Add '"' around string.
    echo \"${1//\//\\/}\"
}

function configure_param_json() {
    config_file="$1"
    param_name="$2"
    param_value="$3"
    echo "$config_file: $param_name=$param_value"
    # NOTE: Handle special-case where there is no "," at the end.
    candid=$(cat "$config_file" | grep "$param_name")
    if [[ ${candid:$((${#candid} - 1)):1} == "," ]]; then
        sed -i "s/\"${param_name}\": .*,/\"${param_name}\": ${param_value},/g" "$config_file"
    else
        sed -i "s/\"${param_name}\": .*/\"${param_name}\": ${param_value}/g" "$config_file"
    fi
}

function configure_json_common() {
    export CONFIG_JSON_PATH_SRC=$PATH_SCPOC/experiments/config/example_collection_collect_plot.json
    cp $CONFIG_JSON_PATH_SRC $CONFIG_JSON_PATH_DST
    configure_param_json $CONFIG_JSON_PATH_DST "channel" "20"
    configure_param_json $CONFIG_JSON_PATH_DST "bandpass_lower" "2.0e6"
    configure_param_json $CONFIG_JSON_PATH_DST "bandpass_upper" "2.15e6"
    configure_param_json $CONFIG_JSON_PATH_DST "drop_start" "2e-1"
    # May be set to 0 for auto-computation.
    configure_param_json $CONFIG_JSON_PATH_DST "trigger_threshold" "0e3"
    # Shift signal left  = Shift window right -> decrease offset.
    # Shift signal right = Shift window left  -> increase offset.
    configure_param_json $CONFIG_JSON_PATH_DST "trigger_offset" "125e-6"
    configure_param_json $CONFIG_JSON_PATH_DST "trigger_rising" "true"
    configure_param_json $CONFIG_JSON_PATH_DST "signal_length" "200e-6"
    configure_param_json $CONFIG_JSON_PATH_DST "num_traces_per_point" 300
    configure_param_json $CONFIG_JSON_PATH_DST "num_traces_per_point_keep" 100
    configure_param_json $CONFIG_JSON_PATH_DST "modulate" "true"
    # May be set to 0 for no reject.
    configure_param_json $CONFIG_JSON_PATH_DST "min_correlation" "0.25e0"
}

function configure_json_plot() {
    export CONFIG_JSON_PATH_DST=$TARGET_PATH/example_collection_collect_plot.json
    configure_json_common
    configure_param_json $CONFIG_JSON_PATH_DST "num_points" 1
}

function configure_json_collect() {
    export CONFIG_JSON_PATH_DST=$TARGET_PATH/example_collection_collect.json
    configure_json_common
    configure_param_json $CONFIG_JSON_PATH_DST "num_points" "$NUM_TRACES"
    configure_param_json $CONFIG_JSON_PATH_DST "template_name" "$(configure_param_json_escape_path $TARGET_PATH/template.npy)"
    if [[ $MODE == "train" ]]; then
        configure_param_json $CONFIG_JSON_PATH_DST "fixed_key" "false"
    elif [[ $MODE == "attack" ]]; then
        configure_param_json $CONFIG_JSON_PATH_DST "fixed_key" "true"
    fi
}

# ** Instrumentation

function experiment() {
    # Get args.
    plot=$1
    saveplot=$2
    cmd=$3 # ["collect"]
    
    # Kill previously started radio server.
    if [[ "${RESTART_RADIO}" -eq 1 ]]; then
        soapyrx server-stop
    fi

    #sudo ykushcmd -d a # power off all ykush device
    sleep 2
    #sudo ykushcmd -u a # power on all ykush device
    #sleep 4

    # Ensure SDR tool version.
    git_checkout_logged "${PATH_SOAPYRX}" "${GIT_CHECKOUT_SOAPYRX}"

    # Start SDR server.
    # NOTE: Make sure the JSON config file is configured accordingly to the SDR server here.
    if [[ "${RESTART_RADIO}" -eq 1 ]]; then
        soapyrx --loglevel ${PY_LOGLEVEL} server-start 0 2.533e9 ${COLLECT_FS} --duration=0.3 --gain 76 &
        sleep 10
    fi

    # Start collection and plot result.
    "${DATASET_PATH}/src/reproduce.py" --loglevel=${PY_LOGLEVEL} --radio=USRP --device=$(nrfjprog --com | cut - -d " " -f 5) $cmd $CONFIG_JSON_PATH_DST $TARGET_PATH $plot $saveplot --average-out=$TARGET_PATH/template.npy
}

function analyze_only() {
    "${DATASET_PATH}/src/reproduce.py" --loglevel=${PY_LOGLEVEL} --radio=USRP --device=$(nrfjprog --com | cut - -d " " -f 5) extract $CONFIG_JSON_PATH_DST $TARGET_PATH --plot --average-out=$TARGET_PATH/template.npy
}

# * Script

# Ensure collection directory is created.
mkdir -p $TARGET_PATH

# Ensure target device is available.
if [[ -z "$(nrfjprog --com | cut - -d " " -f 5)" ]]; then
    echo "ERROR: Cannot found device: nrfjprog return empty string"
    exit 1
fi

# ** Step 1: Calibratation

# If calibration has not been done.
if [[ ! -f "$CALIBRATION_FLAG_PATH" ]]; then
    # Flash custom firmware.
    flash_firmware_once

    # Set the JSON configuration file for one recording analysis.
    configure_json_plot

    # Record a new trace if not already done.
    if [[ ! -f "${TMP_TRACE_PATH}" ]]; then
        experiment --plot --saveplot collect
    # Analyze only.
    else
        echo "SKIP: New recording: File exists: ${TMP_TRACE_PATH}"
        analyze_only
    fi

    read -p "Press [ENTER] to confirm calibration, otherwise press [CTRL-C]..."
    touch $CALIBRATION_FLAG_PATH
else
    echo "SKIP: Calibration: File exists: $CALIBRATION_FLAG_PATH"
fi

# ** Step 2: Collection

if [[ ! -f $TARGET_PATH/template.npy ]]; then
    echo "Template has not been created! (no file at $TARGET_PATH/template.npy)"
    exit 1
fi

# If collection has not been started.
if [[ ! -f "$COLLECTION_FLAG_PATH" ]]; then
    touch $COLLECTION_FLAG_PATH
    configure_json_collect
    experiment --no-plot --no-saveplot collect
else
    echo "SKIP: Collection: File exists: $COLLECTION_FLAG_PATH"
fi
