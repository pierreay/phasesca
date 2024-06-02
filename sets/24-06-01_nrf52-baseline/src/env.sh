# * Variables

# Current dataset path.
export DATASET_PATH="$(realpath "$(dirname "$0")/..")"

# Recording sampling rate.
export FS="8e6"

# Git commits checked out before operating corresponding repository.
export GIT_CHECKOUT_PHASEFW="0d7f6d5b50b8b894a5ea62f519be21f4ac923455"
export GIT_CHECKOUT_SOAPYRX="e7b6da7ef3e6873038e576aee6ac02d82f26a771"
export GIT_CHECKOUT_SCAFF="4aed4cb37b968774cb9e188cf201c2335310e1e0"

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
