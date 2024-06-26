# * Variables

# Current dataset path.
export DATASET_PATH="$(realpath "$(dirname "$0")/..")"

# Recording sampling rate.
export FS="8e6"

# Git commits checked out before operating corresponding repository.
export GIT_CHECKOUT_PHASEFW="master"
export GIT_CHECKOUT_SOAPYRX="master"
export GIT_CHECKOUT_SCAFF="master"

# * Functions

function git_checkout_logged() {
    REPO="${1}"
    COMMIT="${2}"
    echo "INFO: Checkout ${COMMIT} -> ${REPO}"
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
