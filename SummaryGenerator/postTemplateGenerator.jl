function usage()
    println(stderr, "Usage: julia --project=. $(basename(@__FILE__)) path/to/dataFileDesc.jlda [title] [options]\n",
            "path/to/dataFileDesc.jldat",
            "You may need to run julia --project=. -e 'using Pkg; Pkg.instantiate()' before\n",
            "running this script in order to download the necessary packages.")
end

# "Main" script.
# If we don't have enough information, bail.
if length(ARGS) < 1
    usage()
    exit(-1)
end

const fileIn = ARGS[1]
if !isfile(fileIn)
    @error "Input file $(fileIn) not found."
    exit(-1)
end

# Deserialize descriptions/figure titles from plot generation script output
# This will work as long as the Julia version does not change between generating
# the images and generating the corresponding markdown template.
using Serialization
const fileDescriptions = open(fileIn, "r") do st
    deserialize(st)
end

# Emit image in markdown format.
function imageStr(pathToImage, altText = "")
    string("![", altText, "](", pathToImage, ")")
end


using Dates

# Detect if image file based on file extension
isImg(fn) = endswith(fn, ".png")

# Generate template to stdout
function generateTemplate(title, dirIn, desc)
    filesInDir = readdir(dirIn)
    println("""
---
title: "$(title)"
description: ""
draft: false
date: "$(Dates.now())"
---""")
    if "TotalStats.txt" in filesInDir
        println(readchomp(joinpath(dirIn, "TotalStats.txt")))
        delete!(desc, "TotalStats.txt")
    end

    for file in filter(isImg, filesInDir)
        fdesc = haskey(desc, file) ? desc[file] : ""
        println("\n",
                imageStr(
                    file,
                    fdesc
                ),
                "\n\n",
                fdesc
                )
    end

end

const title = length(ARGS) >= 2 ? ARGS[2] : "MAC Activity, File in $(dirname(fileIn))"

generateTemplate(title, dirname(fileIn), fileDescriptions)
