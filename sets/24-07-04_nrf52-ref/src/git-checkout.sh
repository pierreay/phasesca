#!/bin/bash

env="$(realpath $(dirname $0))/env.sh"
echo "INFO: Source file: $env"
source "$env"

# Safety-guard.
if [[ -z $ENV_FLAG ]]; then
    echo "ERROR: Environment can't been sourced!"
    exit 1
fi

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [process | attack_ta | attack_cra]"
    exit 1
fi

if [[ "${1}" == "process" ]]; then
    git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF_TA}"
elif [[ "${1}" == "attack_ta" ]]; then
    git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF_TA}"
elif [[ "${1}" == "attack_cra" ]]; then
    git_checkout_logged "${PATH_SCAFF}" "${GIT_CHECKOUT_SCAFF_CRA}"
else
    echo "Error: Bad argument: ${1}"
    exit 1
fi

git_checkout_logged "${PATH_SOAPYRX}" "${GIT_CHECKOUT_SOAPYRX}"
