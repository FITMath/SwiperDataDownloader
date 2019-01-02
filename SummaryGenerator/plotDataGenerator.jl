function usage()
    println(stderr, "Usage: julia --project=. $(basename(@__FILE__)) path/to/output path/to/dataFile1.csv [path/to/dataFile2.csv...] [options]\n",
            "path/to/output should not exist before running the script, and the dataFile(s)\n",
            "are assumed to be in the correct format.\n",
            "The only option currently implemented is `--force`, which will overwrite files in\n",
            "the output directory.\n",
            "You may need to run julia --project=. -e 'using Pkg; Pkg.instantiate()' before\n",
            "running this script in order to download the necessary packages.")
end

# "Main" script
if length(ARGS) < 2
    usage()
    exit(-1)
end

const dirOut = popfirst!(ARGS)
const useForce = "--force" in ARGS
const restARGS = filter(arg -> arg != "--force", ARGS)
if isdir(dirOut) && !useForce
    @error "Output directory $(dirOut) exists."
    exit(-1)
end

mkpath(dirOut)
const filesIn = filter(isfile, restARGS)
if isempty(filesIn)
    @error "No input files found."
    exit(-1)
end
@info "Generating graphics using aggregated statistics from $(filesIn)"

# End "Main"

# Begin core functionality
using Dates
using CSV

# Define the date format for attendance data:
const fileDF = dateformat"Y-m-d H:M:S"
function extractGraphicsData(fileIn::String)
    # For old data, we may have "junk" in the first line.
    headerRow = startswith(readline(fileIn), "cmdOut") ? 2 : 1

    f = CSV.File(fileIn, header=headerRow, normalizenames=true, dateformat=fileDF, types=Dict(8 => Union{Missing, DateTime}, 9 => Union{Missing, DateTime}))

    #TODO: Only collect visitor IDs when possible (i.e. don't _require_ deanonymized data.)
    visitorIDs = Set{String}()
    busyHoursData = zeros(Int64, 23)
    busyDaysData = zeros(Int64, 7)
    totalDailyTutoringTime = zeros(Float64, 7)
    reasonForVisit = Dict{String, Int}()
    reasonForVisitClass = Dict{String, Int}()
    for row in f
        studentID = row.FIT_ID
        if !ismissing(studentID)
            push!(visitorIDs, studentID)
        end

        timein = row.Time_In
        if ismissing(timein)
            continue
        end
        busyHoursData[Dates.hour(timein)] += 1
        busyDaysData[Dates.dayofweek(timein)] += 1

        # Extract context histogram information
        rowContext = row.Context
        if ismissing(rowContext)
            reasonForVisit["Unknown"] += 1
        else
            if haskey(reasonForVisit, rowContext)
                reasonForVisit[rowContext] += 1
            else
                reasonForVisit[rowContext] = 1
            end
        end

        # Extract class histogram information
        rowClass = row.Class
        if ismissing(rowClass)
            reasonForVisitClass["Unknown"] += 1
        else
            if haskey(reasonForVisitClass, rowClass)
                reasonForVisitClass[rowClass] += 1
            else
                reasonForVisitClass[rowClass] = 1
            end
        end

        timeout = row.Time_Out
        if ismissing(timeout)
            continue
        end
        timediff = timeout - timein
        totalDailyTutoringTime[Dates.dayofweek(timein)] += timediff.value / (1000 * 60) # milliseconds -> minutes
    end

    delete!(reasonForVisitClass, "NULL")
    delete!(reasonForVisit, "NULL")

    return (visitorIDs,
            busyHoursData,
            busyDaysData,
            totalDailyTutoringTime,
            reasonForVisit,
            reasonForVisitClass
            )
end

function combineGraphicsData(d1, d2)
    visitorIDs = union(d1[1], d2[1])
    busyHoursData = d1[2] .+ d2[2]
    busyDaysData = d1[3] .+ d2[3]
    totalDailyTutoringTime = d1[4] .+ d2[4]
    # d{1,2}[{5,6}] are dictionaries with integer values and (hopefully)
    # identical keys. The `merge` method on dicts enables exactly the combination
    # or reduction process we're trying to implement.
    # The methods below combine the dicts and add values with the same key
    reasonForVisit = merge(+, d1[5], d2[5])
    reasonForVisitClass = merge(+, d1[6], d2[6])

    return (visitorIDs,
            busyHoursData,
            busyDaysData,
            totalDailyTutoringTime,
            reasonForVisit,
            reasonForVisitClass
            )
end

function extractGraphicsData(filesIn::Vector{String})
    if length(filesIn) == 1
        return extractGraphicsData(first(filesIn))
    end

    # We can assume each fileIn exists, based on command-line parsing above.
    return mapreduce(extractGraphicsData, combineGraphicsData, filesIn)
end

using Printf
using Plots
using Measures
using Serialization

function createGraphics(fileIn, dirOut)
    (
        visitorIDs,
        busyHoursData,
        busyDaysData,
        totalDailyTutoringTime,
        reasonForVisit,
        reasonForVisitClass
    ) = extractGraphicsData(fileIn)

    outputFileDescriptions = Dict{String, String}()

    currFileStem = "TotalStats.txt"
    currFileDesc = "" # Self-describing?
    open(joinpath(dirOut, currFileStem), "w") do st
        @printf st "A total of %d unique visitors came into MAC this week, spending a collective %0.1f hours receiving services." length(visitorIDs) sum(totalDailyTutoringTime/60)
    end
    outputFileDescriptions[currFileStem] = currFileDesc

    currFileStem = "busyHours.png"
    currFileDesc = "Number of Visitors to MAC each Hour"
    p = bar(8:19, busyHoursData[8:19],
            size=(800, 600), dpi=200, xlabel="Hour", ylabel="Number of Visitors",
            label="")
    savefig(p, joinpath(dirOut, currFileStem))
    outputFileDescriptions[currFileStem] = currFileDesc

    currFileStem = "busyDays.png"
    currFileDesc = "Number of Visitors to MAC each Day"
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    p2 = bar(days, busyDaysData[1:5],
             size=(800, 600), dpi=200, xlabel="Day of Week", ylabel="Number of Visitors",
             label="")
    savefig(p2, joinpath(dirOut, currFileStem))
    outputFileDescriptions[currFileStem] = currFileDesc

    currFileStem = "totalHoursByDay.png"
    currFileDesc = "Services rendered to students by Day of Week (in Hours)"
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    p3 = bar(days, totalDailyTutoringTime[1:5],
             size=(800, 600), dpi=200, xlabel="Day of Week", ylabel="Time Spent by Visitors (h)",
             label="")
    savefig(p3, joinpath(dirOut, currFileStem))
    outputFileDescriptions[currFileStem] = currFileDesc

    currFileStem = "reasonForVisitClass.png"
    currFileDesc = "Primary reason for student visit: Course"
    p4 = pie(collect(keys(reasonForVisitClass)), collect(values(reasonForVisitClass)),
             size=(900, 800), dpi=200, left_margin=20mm, right_margin=20mm)
    savefig(p4, joinpath(dirOut, currFileStem))
    outputFileDescriptions[currFileStem] = currFileDesc

    currFileStem = "reasonForVisit.png"
    currFileDesc = "Primary reason for student visit"
    p5 = pie(collect(keys(reasonForVisit)), collect(values(reasonForVisit)),
             size=(900, 800), dpi=200, left_margin=20mm, right_margin=30mm)
    savefig(p5, joinpath(dirOut, currFileStem))
    outputFileDescriptions[currFileStem] = currFileDesc

    # outputFileDescriptions["dirOut"] = dirOut
    currFileStem = "fileDescriptions.jldat"
    open(joinpath(dirOut, currFileStem), "w") do st
        serialize(st, outputFileDescriptions)
    end
    return joinpath(dirOut, currFileStem)
end
# End "Core" functionality, and finally call createGraphics


const descOut = createGraphics(filesIn, dirOut)
println(stderr, "File descriptions/titles written on $(descOut)")
