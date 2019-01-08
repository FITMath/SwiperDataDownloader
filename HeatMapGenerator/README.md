# [`HeatMapGenerator`](../blob/master/HeatMapGenerator)

generates more representative heat maps from data downloaded from our Swipe card system.

Based on the data scraped by `batch-output-swipes.jl` ([see here](../blob/master)) we generate plots representing a high resolution estimate of the number of students present during a given time interval in the lab.

Usage: To generate heatmaps to the path `$(dir stem-out)` with base filename `$(notdir stem-out)` based on data in `datafile`, run

``` shell
make heatMap DATAFILE=datafile STEMOUT=stem-out

# or

julia --project=. makeHeatMap.jl datafile stem-out
```

Running the example using `make` is preferred, since it will ensure the necessary packages are available in your environment.

## Contributions/Testing

This package was created by Jonathan Goldfarb; your use-cases, fixes, etc. are welcome!

To the extent possible, we supplement existing and new features with automated tests.
Additions currently implemented will be open sourced and added to this repository
It is tested on Travis through PyPy, Python 2, and Python 3.
