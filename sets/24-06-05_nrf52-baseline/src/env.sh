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

# * End

# Successfully sourced environment flag.
export ENV_FLAG=1
