# SwiperDataDownloader

[![Build Status](https://travis-ci.org/FITMath/SwiperDataDownloader.svg?branch=master)](https://travis-ci.org/FITMath/SwiperDataDownloader)

Scripts for automatically downloading and combining swipe data.

## Example Automated Download/Backup

By combining these files with some shell scripts, we can easily automate data downloads and
backups from a CAS-authenticated source.
The script below will download the latest version of this repository to a local directory, use the included functionality, and remove the repository afterwards.
This ensures we're always using the "latest" version of the functionality, and don't accrue untracked fixes.
You'll have to set the corresponding paths to the report directory, the path to Julia, and the username and password.

The calls shelling out to `date` allow us to request dates between last Friday and a week previous.

```
#!/bin/bash
# set -euo pipefail
# IFS=$'\n\t'

# Usage message
usage() {
	echo "usage: $0 script_args"
	echo " Download the SwiperDataDownloader package, run a backup script, and cleanup after ourselves."
}

ReportOutputDir=...
JuliaPath=...
export FITAPIUsername=...
export FITAPIPassword=...

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

mkdir -p ${ReportOutputDir}

cd ${GITREPODEST} && ${JuliaPath} batch-output-swipes.jl command=Detail "" $(date --date='last Friday -1 week' +%m/%d/%Y) $(date --date='last Friday' +%m/%d/%Y) > ${ReportOutputDir}/all-$(date --date='last Friday' +%m-%d-%Y).csv && cd ..
```

## batch-output-swipes.jl

The Julia script `batch-output-swipes.jl` is a simple wrapper for the CAS interface script
`cas-get.sh` (see below) that constructs the necessary API calls to download data.

It can be used to download "Summary" or "Detail" reports, and should work on any version
of Julia greater then or equal to v0.6, but it is tested on Travis' Linux platform with
version 1.0.

To get usage information, run

```
julia batch-output-swipes.jl
```

To get, for instance, Athlete Study Hours, run

```
julia batch-output-swipes.jl command=Detail "Athlete Study Hours" since until
```

where `since` and `until` are dates in the format `m/d/Y`. The environment parameters
`FITAPIUsername` and `FITAPIPassword` must be available.

To request all contexts, simply pass and empty string as the second parameter, e.g.

```
julia batch-output-swipes.jl command=Detail "" since until
```


## cas-get.sh

The core script automating the authentication with CAS and subsequent data download,
`cas-get.sh`, depends only on Bash and Curl; run

```
./cas-get.sh
```

to see usage information.

You should be able to, for instance, download the page `access.fit.edu` by running 
```
./cas-get.sh https://access.fit.edu username password
```

## extractHtmlInputValue.py

`extractHtmlInputValue.py` is a helper script that leverages the Python HTML parser stdlib
to extract the necessary form fields from the CAS login page.

## Contributions/Testing

This package was created by Jonathan Goldfarb; your use-cases, fixes, etc. are welcome!

To the extent possible, we supplement existing and new features with automated tests.
Additions currently implemented will be open sourced and added to this repository
It is tested on Travis through PyPy, Python 2, and Python 3.