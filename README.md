# SwiperDataDownloader

[![Build Status](https://travis-ci.org/FITMath/SwiperDataDownloader.svg?branch=master)](https://travis-ci.org/FITMath/SwiperDataDownloader)

Scripts for automatically downloading and combining swipe data.

## Examples

To download all swipe information for the previous week (Friday to Friday, run on a day after Friday) run

```
julia batch-output-swipes.jl command=Detail "" $(date --date='last Friday -1 week' +%m/%d/%Y) $(date --date='last Friday' +%m/%d/%Y)
```

To run this report automatically every Saturday, add the following to your [crontab](https://en.wikipedia.org/wiki/Cron):

```
0 0 * * 6 FITAPIUsername=... FITAPIPassword=... julia batch-output-swipes.jl command=Detail "" $(date --date='last Friday -1 week' +%m/%d/%Y) $(date --date='last Friday' +%m/%d/%Y) > /path/to/outputfile.csv
```

## SummaryGenerator

See [the README](../blob/master/SummaryGenerator/README) for more information.

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
To choose no context, just pass an empty string as the second argument:

```
julia batch-output-swipes.jl command=Detail "" since until
```

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

## download-and-run.sh

Though running scripts off the internet is generally not a good idea, it is likely fine to run trusted scripts.
We can trust scripts we've written ourselves, right?
The script `download-and-run.sh` is provided as an example of how one might ensure you're always running the latest version of this repository's files.
It will download the repository to a temporary directory, do some work in that directory, and remove everything afterwards.
You can provide environment variables on the command line or (for instance) in your `bashrc` file.

For example,

```
FITAPIUsername=... FITAPIPassword=... download-and-run.sh julia command=
```

will run the given command "julia command=" with the package files available. I use a similar script to automate the data collection from the swipe card system on a weekly basis:

```
#!/bin/bash
# set -euo pipefail
# IFS=$'\n\t'

# Usage message
usage() {
	echo "usage: $0 script_args"
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

mkdir -p ${ReportOutputDir}

cd ${GITREPODEST} && julia batch-output-swipes.jl command=Detail "" $(date --date='last Friday -1 week' +%m/%d/%Y) $(date --date='last Friday' +%m/%d/%Y) > ${ReportOutputDir}/all-$(date --date='last Friday' +%m-%d-%Y).csv && cd ..
```

## Contributions/Testing

This package was created by [Jonathan Goldfarb](mailto:jgoldfar@my.fit.edu); your use-cases, fixes, etc. are welcome.
Contributions, issues, and suggestions are also welcome via the issue tracker on [this Github repository](https://github.com/FITMath/SwiperDataDownloader)

To the extent possible, we supplement existing and new features with automated tests.
Additions currently implemented will be open sourced and added to this repository
It is tested on Travis through PyPy, Python 2, and Python 3.
