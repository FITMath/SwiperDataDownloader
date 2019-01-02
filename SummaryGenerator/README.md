# [`SummaryGenerator`](../blob/master/SummaryGenerator)

is a report generator for data downloaded from our Swipe card system.
Based on the data scraped by `batch-output-swipes.jl` ([see here](../blob/master)) we generate plots representing the "level of business" in the lab, as well as a blog post template for integration with our Hugo site generator.

See the [corresponding blog post](https://jgoldfar.github.io/blog/automating-attendance-reports) to see a detailed description of the processing and setup.

## Contributions/Testing

This package was created by Jonathan Goldfarb; your use-cases, fixes, etc. are welcome!

To the extent possible, we supplement existing and new features with automated tests.
Additions currently implemented will be open sourced and added to this repository
It is tested on Travis through PyPy, Python 2, and Python 3.
