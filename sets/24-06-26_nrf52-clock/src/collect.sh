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
# Arguments described in help().
ARG_SUBSET=""
# Options described in help().
OPT_LOGLEVEL="INFO"
OPT_REFLASH_FW=0
OPT_RESTART_YKUSH=0
OPT_RESTART_RADIO=0
OPT_RESTART_COLLECT=0

# Program's help.
function help() {
    cat << EOF
Usage: collect.sh [-l LOGLEVEL] [-w] [-y] [-r] [-f] SUBSET

SUBSET is the desired subset collection [attack | train].

Set -l to the desired Python LOGLEVEL [default = INFO].
Set -w to reflash the firmware before collecting [default = False].
Set -y to reset YKush switch before collecting [default = False].
Set -r to restart radio before collecting [default = False].
Set -f to restart collection from scratch [default = False].
EOF
    exit 0
}

# Get the scripts options.
while getopts "h?l:wyrf" opt; do
    case "$opt" in
        h|\?)
            help
            ;;
        l) OPT_LOGLEVEL=$OPTARG
           ;;
        w) OPT_REFLASH_FW=1
           ;;
        y) OPT_RESTART_YKUSH=1
           ;;
        r) OPT_RESTART_RADIO=1
           ;;
        f) OPT_RESTART_COLLECT=1
           ;;
    esac
done

# Get the scripts arguments, by suppressing all arguments processed by getopts.
shift $((OPTIND-1))
ARG_SUBSET="${@}"

# Check arguments.
if [[ "${ARG_SUBSET}" != "train" && "${ARG_SUBSET}" != "attack" ]]; then
    log_error "Bad SUBSET value!"
    exit 0
fi

# * Variables

# Select appropriate number of traces.
if [[ "${ARG_SUBSET}" == "train" ]]; then
    NUM_TRACES=${COLLECT_NUM_TRACES_TRAIN}
elif [[ "${ARG_SUBSET}" == "attack" ]]; then
    NUM_TRACES=${COLLECT_NUM_TRACES_ATTACK}
fi

# Subset path.
TARGET_PATH="${DATASET_PATH}/${ARG_SUBSET}"

# Sentinels.
CALIBRATION_FLAG_PATH="${TARGET_PATH}/.calibration_done"
COLLECTION_FLAG_PATH="${TARGET_PATH}/.collection_started"

# * Functions

# ** Firmware

function flash_firmware_once() {
    firmware_src="${PATH_PHASEFW}/nrf52832/sc-poc/pca10040/blank/armgcc/_build/nrf52832_xxaa.hex"
    firmware_dst="${DATASET_PATH}/bin/nrf52832_xxaa.hex"
    if [[ -f "${firmware_dst}" ]]; then
        if [[ "${OPT_REFLASH_FW}" -ne 1 ]]; then
            log_info "Skip flash firmware: File exists: ${firmware_dst}"
            return 0
        fi
    fi
    
    git_checkout_logged "${PATH_PHASEFW}" "${GIT_CHECKOUT_PHASEFW}"
    
    log_info "Flash custom firmware..."
    cd ${PATH_PHASEFW}/nrf52832/sc-poc
    direnv exec . make -C pca10040/blank/armgcc flash
    log_info "Save firmware: ${firmware_src} -> ${firmware_dst}"
    mkdir -p "$(dirname "$firmware_dst")" && cp "${firmware_src}" "${firmware_dst}"
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
    log_info "$config_file: $param_name=$param_value"
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
    if [[ "$ARG_SUBSET" == "train" ]]; then
        configure_param_json $CONFIG_JSON_PATH_DST "fixed_key" "false"
    elif [[ "${ARG_SUBSET}" == "attack" ]]; then
        configure_param_json $CONFIG_JSON_PATH_DST "fixed_key" "true"
    fi
}

# ** Instrumentation

function experiment() {
    # Get args.
    local plot="${1}"
    local saveplot="${2}"
    local cmd="${3}"      # ["collect" | "extract"]
    # Set options based on args.
    local num_points=-1
    if [[ "${plot}" == "--plot" ]]; then
        num_points=1
    fi
    local fixed_key="--no-fixed-key"
    if [[ "${ARG_SUBSET}" == "attack" ]]; then
        fixed_key="--fixed-key"
    fi

    # Ensure SDR tool version.
    git_checkout_logged "${PATH_SOAPYRX}" "${GIT_CHECKOUT_SOAPYRX}"

    # Handle USB and radio if we are not only extracting previous recording.
    if [[ "${cmd}" != "extract" ]]; then
        # Kill previously started radio server.
        if [[ "${OPT_RESTART_RADIO}" -eq 1 ]]; then
            soapyrx server-stop
        fi
        # Power cycle all YKush device.
        if [[ "${OPT_RESTART_YKUSH}" -eq 1 ]]; then
            sudo ykushcmd -d a
            sleep 2
            sudo ykushcmd -u a
            sleep 4
        fi

        # Start SDR server.
        if [[ "${OPT_RESTART_RADIO}" -eq 1 ]]; then
            soapyrx --loglevel "${PY_LOGLEVEL}" server-start 0 "${COLLECT_FC}" "${COLLECT_FS}" --duration="${COLLECT_DUR}" --no-agc &
            sleep 10
        fi
    fi

    # Start collection and plot result.
    "${DATASET_PATH}/src/collect.py" --loglevel="${PY_LOGLEVEL}" --device=$(nrfjprog --com | cut - -d " " -f 5) \
                                     "${cmd}" "${DATASET_PATH}/src/collect.json" "${TARGET_PATH}" "${plot}" "${saveplot}" --average-out="${TARGET_PATH}/template.npy" --num-points="${num_points}" "${fixed_key}"
}

# * Script

# Ensure collection directory is created.
mkdir -p "${TARGET_PATH}"

# Ensure target device is available.
if [[ -z "$(nrfjprog --com | cut - -d " " -f 5)" ]]; then
    log_error "Cannot found device: nrfjprog return empty string"
    exit 1
fi

# ** Step 1: Calibratation

# If calibration has not been done.
if [[ ! -f "${CALIBRATION_FLAG_PATH}" ]]; then
    # Flash custom firmware.
    flash_firmware_once

    # Set the JSON configuration file for one recording analysis.
    configure_json_plot

    # Record a new trace if not already done.
    if [[ ! -f "${TMP_TRACE_PATH}" ]]; then
        experiment --plot --saveplot collect
    # Analyze only.
    else
        log_info "Skip new recording: File exists: ${TMP_TRACE_PATH}"
        experiment --plot --no-saveplot extract
    fi

    read -p "Press [ENTER] to confirm calibration, otherwise press [CTRL-C]..."
    touch "${CALIBRATION_FLAG_PATH}"
else
    log_info "Skip calibration: File exists: $CALIBRATION_FLAG_PATH"
fi

# ** Step 2: Collection

if [[ ! -f "${TARGET_PATH}/template.npy" ]]; then
    log_error "Template has not been created: File not exists: $TARGET_PATH/template.npy"
    exit 1
fi

# If collection has not been started.
if [[ ! -f "${COLLECTION_FLAG_PATH}" ]]; then
    touch "${COLLECTION_FLAG_PATH}"
    configure_json_collect
    experiment --no-plot --no-saveplot collect
else
    log_info "Skip collection: File exists: $COLLECTION_FLAG_PATH"
fi
