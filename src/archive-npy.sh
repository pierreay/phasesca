#!/bin/bash

VERBOSE=0
PRUNE=0

function path_directory_to_archive() {
    path="${1}"
    printf "${path//\//_}.tar"
}

function check_datasets_under() {
    for dataset in $(realpath $(find "$1" -maxdepth 1 -type d -regex ".*23.*\|.*24.*")); do
        if [[ $VERBOSE == 1 ]]; then
            echo "INFO: Check: ${dataset}"
        fi
        # NOTE: List from .gitignore.
        for directory in train attack; do
            archive="$(path_directory_to_archive "${directory}")"
            if [[ -d "${dataset}/${directory}" ]]; then
                size_run=$(stat -c "%s" "${dataset}/${directory}")
                size_stage=0
                if [[ -f "${dataset}/${archive}" ]]; then
                    size_stage=$(stat -c '%s' "${dataset}/${archive}")
                fi
                if [[ $VERBOSE == 1 ]]; then
                    echo size_run="$size_run"
                    echo size_stage="$size_stage"
                fi
                if [[ "$size_run" -gt "$size_stage" ]]; then
                    if [[ "${PRUNE}" -eq 1 ]]; then
                        echo "WARN: Please, compress ${directory} into ${archive}: ${dataset}"
                    else
                        (
                            cd "${dataset}"
                            tar cvf "${archive}" "${directory}"
                        )
                    fi
                fi
            fi
        done
        if [[ $VERBOSE == 1 ]]; then
            echo "DONE!"
        fi
    done    
}

check_datasets_under "${PATH_PROJ}/sets"
check_datasets_under "${PATH_PROJ}/expe"
