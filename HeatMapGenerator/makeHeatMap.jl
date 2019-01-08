## Begin "main" data input portion of script
const fileIn = get(ARGS, 1, "")
const stemOut = get(ARGS, 2, "traffic")
if isempty(fileIn) || !isfile(fileIn)
    exit(-1)
end
## End "main" data input

using Dates

# Histogram data storage.
"""
    visitorHistogramData

Data container for visitors during a vector of time intervals.

* `initialTimes`: Vector of time values to be considered the start of a measurement period.

* `resolution`: step size for time vector. TODO: Remove this field.

* `visitors`: Vector such that `visitors[i]` is an approximate number of students in MAC between
`initialTimes[i]` and `initialTimes[i] + resolution`.
"""
struct visitorHistogramData{T1, T2, T3}
    initialTimes::T1
    resolution::T2
    visitors::T3
end
function visitorHistogramData(startTime::Time, resolution::Period, endTime::Time)
    initialTimes = startTime:resolution:endTime
    visitors = zeros(Int, length(initialTimes))
    return visitorHistogramData(initialTimes, resolution, visitors)
end

"""
    reset!(v::visitorHistogramData)

Clear recorded visitor information.
"""
function reset!(v::visitorHistogramData{T1, T2, T3}) where {T1, T2, T3}
    fill!(v.visitors, 0)
end

# Define scaling on a visitorHistogramData instance as a scaling for
# the val.visitors field.
function rescale(val::visitorHistogramData{T1, T2, T3}, factor = maximum(val.visitors)) where {T1, T2, T3}
    visitorHistogramData(val.initialTimes, val.resolution, val.visitors / factor)
end
function rescale(vals::Vector{visitorHistogramData{T1, T2, T3}}, factor) where {T1, T2, T3}
    [rescale(val, factor) for val in vals]
end
function rescale(vals::Vector{visitorHistogramData{T1, T2, T3}}) where {T1, T2, T3}
    factor = maximum(maximum(val.visitors) for val in vals)
    rescale(vals, factor)
end

# Day names
const dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

"""
    extractVisitors!(logVector, data)

Extract vector of visitor values from given CSV (or row-oriented) `data`.
`logVector` should have 5 values, each corresponding to a given day of the week.
After this routine runs over the values in `data`, each element of `logVector`
will have complete `visitorHistogramData` structures.
"""
function extractVisitors!(logVector, data)
    for row in data
        ti = row.Time_In
        to = row.Time_Out
        if ismissing(ti) || ismissing(to)
            continue
        end

        # Assume we checked in & out on the same day of the week
        # which is used to index into the day vector
        dow = Dates.dayofweek(ti)

        # Extract time component from time in & time out
        tiTime = Time(ti)
        toTime = Time(to)

        # No student is checked in before the center opens
        checkedIn = false

        # Extract component of DaysAndTimes corresponding to the given day
        dataForCheckin = logVector[dow]

        # The time resolution is fixed
        res = dataForCheckin.resolution

        # Iterate over all initial time values
        for (k, e) in enumerate(dataForCheckin.initialTimes)
            # If checked in during [e, e + resolution], consider us checked in
            if !checkedIn && (tiTime >= e) && (tiTime <= e + resolution)
                checkedIn = true
            end

            # Tabulate everyone checked in during a given time
            if checkedIn
                dataForCheckin.visitors[k] += 1
                # If we check out during this interval, record that here.
                if toTime <= e + resolution
                    checkedIn = false
                end
            end
        end
    end
end

# Import plotting routines
import PyPlot

# Using pyplot (Python) style syntax
const plt = PyPlot

"""
    createPlotFromDay(logVals::visitorHistogramData, dayName, title_short, omit_ylabels)

Create a single line plot of the log values in `logVals`, with title generated from `dayName`.
The title will have more detail if `title_short` is false (the default) but for use in
subplots, you probably want `title_short = true`.
y-labels are only added if `omit_ylabels = false`.

## Example with subplots
Assuming the data is present in `visitorLogVector`, we can create a collection of line graphs
as follows:

```julia
# Figure with Raw Data
rawFigure = plt.figure("Raw Data", figsize = (8, 10))

plt.subplot(510 + 1)
p, ax = createPlotFromDay(visitorLogVector[1], dayNames[1], true, true)

for i in 2:5
    plt.subplot(510 + i, sharex = ax, sharey = ax)
    global p, ax = createPlotFromDay(visitorLogVector[i], dayNames[i], true, true)
end

# Adjust vertical spacing in subplot
plt.subplots_adjust(hspace=0.1)

# Modify x-axis formatting
rawFigure[:autofmt_xdate](bottom=0.2,rotation=30,ha="right")

# Update layout
PyPlot.tight_layout()

# Update the figure
rawFigure[:canvas][:draw]()
rawFigure[:suptitle]("Raw Traffic Data", y=1.01, x=0.5)
```
"""
function createPlotFromDay(
        logVals::visitorHistogramData{T1, T2, T3},
        dayName::String,
        title_short::Bool = false,
        omit_ylabels::Bool = true) where {T1, T2, T3}
    ax = plt.gca()

    # Times are represented as nanoseconds in Julia.
    timeRaw = logVals.initialTimes

    # But in Matplotlib, they use whole numbers as day after epoch and
    # decimals for percentage of the day
    times = map(v->(Dates.value(v) // (10^9 * 60 * 60 * 24)) + 1, timeRaw)

    dispFmt = dateformat"HH:MM:SS"

    font1 = Dict("fontname" => "Sans", "style" => "normal")
    majorFormatter = plt.matplotlib[:dates][:DateFormatter]("%H:%M:%S")
    # AutoDateLocator is useful for debugging the tick mark locations
    majorLocator = plt.matplotlib[:dates][:HourLocator](interval=1, byhour=0:23)

    p1 = plt.plot_date(
        times,
        logVals.visitors,
        linestyle = "-",
        marker = "None",
        label = "Raw Data"
    )

    # Adjust axis layout
    plt.axis("tight")

    # Set title and labels
    if title_short
        plt.title(dayName)
    else
        timespan = Dates.format(minimum(timeRaw), dispFmt) * " - " * Dates.format(maximum(timeRaw), dispFmt)
        plt.title("Student Traffic on " * dayName * "\n" * timespan)
    end

    plt.xlabel("Time", fontdict = font1)
    if !omit_ylabels
        plt.ylabel("Student Traffic", fontdict = font1)
    end

    # Turn on grid
    plt.grid("on")

    # Customize x-axis formatting
    ax[:xaxis][:set_major_formatter](majorFormatter)
    ax[:xaxis][:set_major_locator](majorLocator)
    p1, ax
end

"""
    createPlotFromDays(logVector::Vector{visitorHistogramData}, figureTitle)

Create a single line plot of the vector of logged traffic data values in
`logVector`, with a figure title generated from `figureTitle`. Individual plot titles
are taken from the corresponding entry of `dayNames`.

each title will have more detail if `title_short` is false (the default) but for use in
subplots, you probably want `title_short = true`.
y-labels are only added if `omit_ylabels = false`.

## Example
Assuming the parsed data is in `visitorLogVector`, simply run
```julia
createPlotFromDays(visitorLogVector, "Raw Traffic Data")
```

To save the resulting figure, use
```julia
PyPlot.savefig("traffic-data-raw.png", dpi=300)
```
"""
function createPlotFromDays(
    logVector::Vector{visitorHistogramData{T1, T2, T3}},
    figureTitle::String
) where {T1, T2, T3}
    # Figure with Raw Data
    f = plt.figure(figureTitle, figsize = (8, 10))

    plt.subplot(510 + 1)
    p, ax = createPlotFromDay(logVector[1], dayNames[1], true, true)

    for i in 2:5
        plt.subplot(510 + i, sharex = ax, sharey = ax)
        p, ax = createPlotFromDay(logVector[i], dayNames[i], true, true)
    end

    # Adjust vertical spacing in subplot
    plt.subplots_adjust(hspace=0.1)

    # Modify x-axis formatting
    f[:autofmt_xdate](bottom=0.2, rotation=30, ha="right")

    # Update layout
    PyPlot.tight_layout()

    # Update the figure
    f[:canvas][:draw]()
    f[:suptitle](figureTitle, y=1.01, x=0.5)
    f
end

"""
    createHeatmap(dataVals::Vector{visitorHistogramData}, nxTicks)

Create a heatMap from the collection of visitor traffic data in `dataVals`.
Each element of the vector should correspond to a day of the week.
We aim to place `nxTicks` x tick locations.

## Example
Assuming the data is present in `visitorLogVector`, we first rescale the entire week
worth of values, and then plot the heatMap.

```julia
visitorLogVectorScaled = rescale(visitorLogVector)
heatImage, f, ax = createHeatmap(visitorLogVectorScaled)
```
"""
function createHeatmap(
        dataVals::Vector{visitorHistogramData{T1, T2, T3}},
        nxTicks::Int = 6) where {T1, T2, T3}
    # Use first element of dataVals to set some parameters
    val = first(dataVals)

    # Assume visitor vectors are the same size (TODO: Remove assumption)
    nvisitors = length(val.visitors)

    # Interval between x tick values (err on the side of more ticks rather than less)
    xTickInterval = floor(Int, nvisitors / nxTicks)

    # Create matrix of to store heatMap data
    heatData = zeros(5, nvisitors)
    for j in 1:5
        for i in 1:nvisitors
            heatData[j, i] = dataVals[j].visitors[i]
        end
    end

    f, ax = plt.subplots(figsize = (8, 4))

    # Build heatmap
    heatImage = plt.imshow(heatData)

    # Create colorbar
    plt.colorbar(heatImage, ax=ax, shrink=0.7, orientation = "horizontal")

    # Setup x tick labels
    tickLabelFormat = dateformat"HH:MM"
    xTickLabels = map(
        v->Dates.format(v, tickLabelFormat),
        val.initialTimes[1:xTickInterval:end]
        )

    # We want to show all ticks and label them with the respective list entries
    plt.xticks(0:xTickInterval:nvisitors, xTickLabels)
    plt.yticks(0:4, dayNames)
    heatImage, f, ax
end

## Main data output routines
# parseDetailData included from here
include(joinpath(@__DIR__, "..", "swipeDataUtils.jl"))

# Parse data from dataFile
const dataIn = parseDetailData(fileIn)

# Define start and end time for our plot
const startTime = Time(8, 0)
const endTime = Time(19, 0)
const resolution = Minute(15)

# Data for each day of the week
const logVector = [visitorHistogramData(startTime, resolution, endTime) for k in 1:5]

# To reset each histogram data structure
# foreach(reset!, logVector)

# Parse CSV data into logVector
extractVisitors!(logVector, dataIn)

# Normalize number of visitors according to the maximum number of visitors
# in any time interval
const logVectorNormalized = rescale(logVector)

# Modify (increase) the DPI this if planning to include this plot in a printed
# medium.
const outputDPI = 80

# Create "Raw" data line plot and output it to a file
const fRawLine = createPlotFromDays(logVector, "Raw Traffic Data")
plt.savefig(string(stemOut, "-raw-line.png"), dpi=outputDPI)

const fNormLine = createPlotFromDays(logVectorNormalized, "Normalized Traffic Data")
plt.savefig(string(stemOut, "-norm-line.png"), dpi=outputDPI)

const fHeatPlot = createHeatmap(logVectorNormalized)
plt.savefig(string(stemOut, "-heatmap.png"), dpi=outputDPI)
