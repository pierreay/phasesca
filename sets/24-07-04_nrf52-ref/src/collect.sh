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

Set -l to the desired Python LOGLEVEL for collection script [default = INFO].
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
    readonly NUM_TRACES=${COLLECT_NUM_TRACES_TRAIN}
elif [[ "${ARG_SUBSET}" == "attack" ]]; then
    readonly NUM_TRACES=${COLLECT_NUM_TRACES_ATTACK}
fi

# Subset path.
readonly TARGET_PATH="${DATASET_PATH}/${ARG_SUBSET}"
# First IQ raw trace path.
readonly TMP_TRACE_PATH="${TARGET_PATH}/0_iq.npy"
# Template path.
readonly TEMPLATE_PATH="${TARGET_PATH}/template.npy"

# Sentinels.
readonly CALIBRATION_FLAG_PATH="${TARGET_PATH}/.calibration_done"
readonly COLLECTION_FLAG_PATH="${TARGET_PATH}/.collection_started"

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
    elif [[ "${ARG_SUBSET}" == "train" ]]; then
         num_points="${COLLECT_NUM_TRACES_TRAIN}"
    elif [[ "${ARG_SUBSET}" == "attack" ]]; then
         num_points="${COLLECT_NUM_TRACES_ATTACK}"
    fi
    local fixed_key="--no-fixed-key"
    if [[ "${ARG_SUBSET}" == "attack" ]]; then
        fixed_key="--fixed-key"
    fi
    local ykush_port=0
    if [[ "${OPT_RESTART_YKUSH}" -eq 1 ]]; then
        ykush_port="${COLLECT_YKUSH_PORT}"
    fi
    local continue_flag="--continue"
    if [[ "${plot}" == "--plot" ]]; then
        continue_flag="--no-continue"
    fi
    local average_out="--average-out=${TEMPLATE_PATH}"
    if [[ "${plot}" == "--no-plot" ]]; then
         average_out=""
    fi
    local template_path=""
    if [[ "${plot}" == "--no-plot" ]]; then
        template_path="--template=${TEMPLATE_PATH}"
    fi

    # Ensure SDR tool version.
    git_checkout_logged "${PATH_SOAPYRX}" "${GIT_CHECKOUT_SOAPYRX}"

    # If we are collecting.
    if [[ "${cmd}" != "extract" ]]; then
        # Kill previously started radio server.
        if [[ "${OPT_RESTART_RADIO}" -eq 1 ]]; then
            log_info "Stop radio..."
            # Gentle stop.
            pgrep soapyrx && soapyrx server-stop ; sleep 2
            # Brutal stop.
            pgrep soapyrx && pkill -9 soapyrx ; sleep 1
        fi

        # Start SDR server.
        if [[ "${OPT_RESTART_RADIO}" -eq 1 ]]; then
            log_info "Start radio..."
            local soapyrx_starter="soapyrx --loglevel INFO --config '${DATASET_PATH}/src/soapyrx.toml' server-start 0 '${COLLECT_FC}' '${COLLECT_FS}' --duration='${COLLECT_DUR}' --no-agc"
            if [[ "${TMUX_PANE}" -eq 1 ]]; then
                tmux split-window "tmux set-window-option remain-on-exit on; ${soapyrx_starter}"
            else
                eval "${soapyrx_starter} &"
            fi
            soapyrx server-wait
        fi

        # Start collection and plot result.
        log_info "Start collection..."
        eval "${DATASET_PATH}/src/collect.py" --loglevel="${OPT_LOGLEVEL}" --device=$(nrfjprog --com | cut - -d " " -f 5) --ykush-port="${ykush_port}" "${continue_flag}" "${template_path}" "${DATASET_PATH}/src/collect.toml" \
                                         "${cmd}" "${TARGET_PATH}" "${plot}" "${saveplot}" "${average_out}" --num-points="${num_points}" "${fixed_key}"
    # If we are analyzing.
    else
        log_info "Start analysis..."
        eval "${DATASET_PATH}/src/collect.py" --loglevel="${OPT_LOGLEVEL}" "${continue_flag}" "${template_path}" "${DATASET_PATH}/src/collect.toml" \
                                         "${cmd}" "${TMP_TRACE_PATH}" "${TARGET_PATH}" "${plot}" "${saveplot}" "${average_out}"
    fi    
}

# * Script

# Restart subset if desired.
if [[ "${OPT_RESTART_COLLECT}" -eq 1 ]]; then
    rm -r "${TARGET_PATH}"
fi

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
    experiment --no-plot --no-saveplot collect
else
    log_info "Skip collection: File exists: $COLLECTION_FLAG_PATH"
fi

# ** Step 3: Extraction & Filtering

local target=""
if [[ "${ARG_SUBSET}" == "train" ]]; then
    target="${TRAIN_SET}"
elif [[ "${ARG_SUBSET}" == "attack"]]; then
    target="${ATTACK_SET}"
fi
# Extract.
if [[ ! -d "${target}" ]]; then
    mkdir -p "${target}"
    cp -t "${target}" "${ARG_SUBSET}/pt.txt" "${ARG_SUBSET}/key.txt"
    scaff --config "${DATASET_PATH}/src/collect.toml" extract "${ARG_SUBSET}" "${target}"
else
    log_info "Skip extraction: Directory exists: ${target}"
fi

