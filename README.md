# SwiperDataDownloader

[![Build Status](https://travis-ci.org/FITMath/SwiperDataDownloader.svg?branch=master)](https://travis-ci.org/FITMath/SwiperDataDownloader)

Scripts for automatically downloading and combining swipe data.

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
It is tested on Travis through PyPy, Python 2, and Python 3.

