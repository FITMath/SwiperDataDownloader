# SwiperDataDownloader

[![Build Status](https://travis-ci.org/FITMath/SwiperDataDownloader.svg?branch=master)](https://travis-ci.org/FITMath/SwiperDataDownloader)

Scripts for automatically downloading and combining swipe data.

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