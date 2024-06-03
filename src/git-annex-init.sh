#!/bin/bash

LARGEFILES='largerthan=500kb'

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 DESC"
    echo "Initialize and configure a git-annex repository in the current directory using DESC as description"
    exit 0
fi

if [[ -d .git ]]; then
    echo "Repository already initialized!"
    exit 1
fi

git init
git annex init "$1"
git config annex.thin true
git config annex.backend WORM
git update-index --index-version 4
GIT_INDEX_FILE=.git/annex/index git update-index --index-version 4
git config annex.diskreserve "10 gb"
git config merge.renamelimit 999999
git config annex.sshcaching true
git annex config --set annex.addunlocked true
git annex config --set annex.dotfiles true
git annex config --set annex.largefiles $LARGEFILES
