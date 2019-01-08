using Dates
using CSV

"""
`detailDF`: date format for attendance data.
"""
const detailDF = dateformat"Y-m-d H:M:S"

"""
    parseDetailData(fileIn)

Extract data from a give CSV file `fileIn`, assuming it is the result of a "Detailed" report.
"""
function parseDetailData(fileIn::String)
    # For old data, we may have "junk" in the first line.
    headerRow = startswith(readline(fileIn), "cmdOut") ? 2 : 1

    CSV.File(fileIn, header=headerRow, normalizenames=true, dateformat=detailDF, types=Dict(8 => Union{Missing, DateTime}, 9 => Union{Missing, DateTime}))
end
