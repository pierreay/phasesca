# * Variables

# Current dataset path.
export DATASET_PATH="$(realpath "$(dirname "$0")/..")"

# Recording sampling rate [Hz].
# NOTE: Synchronized with "collect.toml" file for "collect.py".
export COLLECT_FS="10e6"
# Recording center frequency [Hz].
export COLLECT_FC="63.9992e6"
# Recording duration [s].
export COLLECT_DUR="0.16"
# Number of traces.
export COLLECT_NUM_TRACES_TRAIN=8000
export COLLECT_NUM_TRACES_ATTACK=2000
# YKush configuration (only for YKush reset / power-cycle).
export COLLECT_YKUSH_PORT=1

# Git commits checked out before operating corresponding repository.
export GIT_CHECKOUT_PHASEFW="fb9b060"
export GIT_CHECKOUT_SOAPYRX="d5db344"
export GIT_CHECKOUT_SCAFF="23aad15"

# If set, use new Tmux pane for background processes.
export TMUX_PANE=1

# List of parameters for the created profiles.
export PROFILE_COMP_LIST=(amp phr)
# export PROFILE_NUM_TRACES_LIST=(4000 8000)
export PROFILE_NUM_TRACES_LIST=(4000)
export PROFILE_POIS_ALGO_LIST=(r)
export PROFILE_POIS_NB_LIST=(1)
# Delimiters. Small window greatly increase profile computation speed.
export PROFILE_START_POINT=0
export PROFILE_END_POINT=0

# Suffix for the following paths (e.g., "_filtered") corresponding to a
# post-processing. May be empty.
export PROCESSING_SUFFIX="_filt_lh1e6"
# Base path used to store the created profile.
export PROFILE_PATH_BASE="${DATASET_PATH}/profile${PROCESSING_SUFFIX}"
# Path of dataset used to create the profile.
export TRAIN_SET="${DATASET_PATH}/train${PROCESSING_SUFFIX}"
# Path of dataset used for the attack.
export ATTACK_SET="${DATASET_PATH}/attack${PROCESSING_SUFFIX}"
# Base path used to store the attack log.
export LOG_PATH_BASE="${DATASET_PATH}/logs${PROCESSING_SUFFIX}"

# Number of traces to attack.
export ATTACK_NUM_TRACES_LIST=(250 500 1000 2000)

# * Functions

function git_checkout_logged() {
    REPO="${1}"
    COMMIT="${2}"
    log_info "Checkout ${COMMIT} -> ${REPO}"
    cd "${REPO}" && git checkout "${COMMIT}"
}

# * Libraries

# ** Logging (log.sh)

# Colors definition.
black="\e[30;1m"
red="\e[31;1m"
green="\e[32;1m"
yellow="\e[33;1m"
blue="\e[34;1m"
magenta="\e[35;1m"
cyan="\e[36;1m"
white="\e[37;1m"

# Reset text attributes to normal without clearing screen.
function creset() {
    tput sgr0
}

# Color-echo.
# Argument $1 = message
# Argument $2 = color
function cecho() {
    message="$1"          # Defaults to default message.
    color="${2:-$green}"  # Defaults to green, if not specified.
    echo -n -e "$color"
    echo -n "$message"
    creset
}

function log_error() {
    cecho "[ERROR] " $red
    echo $1
}

function log_warn() {
    cecho "[WARN] " $yellow
    echo $1
}

function log_debug() {
    cecho "[DEBUG] " $white
    echo $1
}

function log_info() {
    cecho "[INFO] " $green
    echo $1
}

# log_error "This is an error message!"
# log_warn "This is a warning message!"
# log_debug "This is a debugging message!"
# log_info "This is an information message!"

# * End

# Successfully sourced environment flag.
export ENV_FLAG=1
