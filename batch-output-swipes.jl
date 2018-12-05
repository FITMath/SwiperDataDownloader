@static if VERSION >= v"0.6-"
	import Dates
	using DelimitedFiles
else
	import Base.Dates
end

const casGetScript = joinpath(@__DIR__, "cas-get.sh")
const baseURL = "https://apps2.fit.edu/swiper/reports"

# Vector of usage messages
const usageMessages = Vector{String}()

# Default dates for Summary information
const n = Dates.now()
const nMinusAWeek = Dates.toprev(n, 1) # find date representing previous week
const defaultSinceDate = Dates.Date(Dates.year(nMinusAWeek), Dates.month(nMinusAWeek), Dates.day(nMinusAWeek))
const defaultUntilDate = Dates.Date(Dates.year(n), Dates.month(n), Dates.day(n))

const username = get(ENV, "FITAPIUsername", "")
const pword = get(ENV, "FITAPIPassword", "")

# Format of dates expected from, and to be submitted to swiper API
"""
Date format for "internal" requests and arguments to this script (m/d/Y)
"""
const urlDateFormat = Dates.DateFormat("m/d/Y")

"""
Date format for "nice" or external requests (Y-m-d)
"""
const urlDateSubmitFormat = Dates.DateFormat("Y-m-d")

"""
    getDateOrDefault(value, defaultValue)

Parse the given `value` as a date in the form `urlDateFormat`, unless `value` is
empty, in which case, return the `defaultValue`.
"""
function getDateOrDefault(value, defaultValue)
	if isempty(value)
		return defaultValue
	else
		try
			return Dates.DateTime(value, urlDateFormat)
		catch e
			@warn "Failed to parse DateTime $(value)"
			return defaultValue
		end
	end
end

"""
    dateToURlAndSubmit(date)

Format the given `date` into `urlDateFormat` and `urlDateSubmitFormat`.
"""
function dateToURlAndSubmit(date)
	dateURL = Dates.format(date, urlDateFormat)
	dateSubmit = Dates.format(date, urlDateSubmitFormat)
	
	return dateURL, dateSubmit
end


# API call corresponding to, for instance,
# http://swiper.stage.fit.edu/reports/summary?starting_date=&starting_date_submit=&starting_time=&starting_time_submit=&ending_date=&ending_date_submit=&ending_time=&ending_time_submit=&context[]=Athlete+Study+Hours&action=Download+as+CSV
# will be constructed by calling this script with arguments
# command=Summary "Athlete Study Hours" since until
## 
push!(usageMessages, """
COMMAND=summary: Download summary CSV report
\tARGS = Context since until
\tContext: identical to value in the corresponding drop-down field.
\tsince: Start date for output in the format m/d/Y.
\tuntil: Start date for output in the format m/d/Y.""")

# http://swiper.stage.fit.edu/reports/detail?starting_date=&starting_date_submit=&starting_time=&starting_time_submit=&ending_date=&ending_date_submit=&ending_time=&ending_time_submit=&context[]=Athlete+Study+Hours&action=Download+as+CSV
push!(usageMessages, """
COMMAND=detail: Download detailed CSV report
\tARGS = Context since until
\tContext: identical to value in the corresponding drop-down field.
\tsince: Start date for output in the format m/d/Y.
\tuntil: Start date for output in the format m/d/Y.""")

function mainSummary(
		summaryPage::Bool = true, Context = get(ARGS, 2, ""),
		since = get(ARGS, 3, ""), until = get(ARGS, 4, "")
		)
		
	# Get script input from command line arguments
	# Context has to be passed to API escaped
	ContextEncoded = if isempty(Context)
		""
	else
		string("&context[]=", replace(Context, " " => "+"))
	end

	# If we don't have enough information, return
	if isempty(username) || isempty(pword)
		@info "Ensure that the environment variables FITAPIUsername and"
		@info " FITAPIPassword are set correctly."
		return 1
	end

	# Parse begin date
	sinceParsed = getDateOrDefault(since, defaultSinceDate)
	# and format as required by API
	sinceUrl, sinceSubmit = dateToURlAndSubmit(sinceParsed)

	# Parse end date
	untilParsed = getDateOrDefault(until, defaultUntilDate)
	# and format as required by API
	untilUrl, untilSubmit = dateToURlAndSubmit(untilParsed)
	
	@info "Collecting swipe card information for context $(Context) between $(sinceUrl) and $(untilUrl)."
	
	# Form URL for submission
	basePage = summaryPage ? "summary" : "detail"
	URL=string(	baseURL, "/", basePage,
				"?starting_date=$(sinceUrl)&starting_date_submit=", sinceSubmit,
				"&ending_date=$(untilUrl)&ending_date_submit=", untilSubmit,
				ContextEncoded, "&action=Download+as+CSV")
	@info "URL Requested: $(URL)"

	# Form command line call to casGetScript
	casCmd = Cmd(`$(casGetScript) $(URL) $(username) $(pword)`,
				 dir=@__DIR__,
				 ignorestatus = false)
	
	if in("--dry-run", ARGS)
		return 0
	end
	
	cmdOut = IOBuffer(readchomp(pipeline(casCmd, stderr=stderr)))

	@show cmdOut

	# Parse output as a CSV file
	parsedCmdOut = readdlm(cmdOut, ',', String, '\n', quotes = true)
	nr, nc = size(parsedCmdOut)
	idPrinted = String[]
	for r in 1:nr
		# Avoid repeating any names unless the "detail" page is requested
		if summaryPage
			if parsedCmdOut[r, 1] in idPrinted
				continue
			else
				push!(idPrinted, parsedCmdOut[r, 1])
			end
		end
		# Print output as CSV
		for c in 1:(nc - 1)
			print("\"", parsedCmdOut[r, c], "\", ")
		end
		println("\"", parsedCmdOut[r, nc], "\"")
	end

	return 0
end

# Print all accumulated usage messages
function usage()
	@info "Usage: $(basename(@__FILE__)) command=COMMAND ARGS"
	@info "\t Parameters FITAPIUsername and FITAPIPassword are expected to be set in"
	@info "\t the calling environment. Run with --dry-run as the last argument to print"
	@info "\t the URL that would be downloaded, but bail before attempting to download it."
	for usageMessage in usageMessages
		@info usageMessage
	end
end

if !isinteractive()
	if "command=summary" in map(lowercase, ARGS)
		exit(mainSummary(true))
	elseif "command=detail" in map(lowercase, ARGS)
		exit(mainSummary(false))
	else
		usage()
		exit(0)
	end
end
