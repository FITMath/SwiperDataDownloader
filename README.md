# SwiperDataDownloader

[![Build Status](https://travis-ci.org/FITMath/SwiperDataDownloader.svg?branch=master)](https://travis-ci.org/FITMath/SwiperDataDownloader)

Scripts for automatically downloading and combining swipe data.

The core script automating the data download depends only on Bash and Curl; run

```
./cas_get.sh
```

to see usage information.

You should be able to, for instance, download the page `access.fit.edu` by running 
```
./cas_get.sh https://access.fit.edu username password
```
