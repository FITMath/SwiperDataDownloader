#!/bin/bash
# set -euo pipefail
# IFS=$'\n\t'

# Usage message
usage() {
	echo "usage: $0 script_args [CAS_HOSTNAME]"
	echo " Download this package, run the given script, and cleanup after ourselves."
}

GITREMOTE=https://github.com/FITMath/SwiperDataDownloader.git
GITREPODEST=./SwiperDataDownloader

# Cleanup function
cleanup_git() {
	rm -rf ${GITREPODEST}
}
# Cleanup on exit
trap cleanup_git EXIT

cleanup_git

git clone ${GITREMOTE} ${GITREPODEST}

cd ${GITREPODEST} && eval "$@" && cd ..
