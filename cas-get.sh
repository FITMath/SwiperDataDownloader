#!/bin/bash
# set -euo pipefail
# IFS=$'\n\t'

# Usage message
usage() {
	echo "usage: $0 DEST_url API_username API_password [CAS_HOSTNAME]"
	echo " Authenticate to CAS using username API_username and password API_password"
	echo " in order to navigate to DEST_url. CAS_HOSTNAME should be set to the URI of"
	echo " the CAS authentication server."
}

# If you have any errors try removing the redirects to get more information

# IP Addresses or hostnames are fine here
CAS_HOSTNAME=${4:-}
if [[ -z "${CAS_HOSTNAME}" ]] ; then
	CAS_HOSTNAME=cas.fit.edu
fi

# Temporary files used by curl to store cookies and http headers
COOKIE_JAR=.cookieJar
HEADER_DUMP_DEST=.headers

# Cleanup function
cleanup_tmps() {
	rm -f $COOKIE_JAR
	rm -f $HEADER_DUMP_DEST
}
# Cleanup on exit
trap cleanup_tmps EXIT

# and go ahead and cleanup now JIC.
cleanup_tmps

# The service or page to be requested: 
DEST="${1:-}"
if [[ -z "$DEST" ]] ; then
	usage
	exit 2
fi

# URL-encoded version (the url encoding isn't perfect, so if you're encoding complex stuff
# you may wish to replace with a different method)
ENCODED_DEST=`echo "$DEST" | perl -p -e 's/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg' | sed 's/%2E/./g' | sed 's/%0A//g'`

# Authentication details. This script only supports username/password login, but curl can
# handle certificate login if required
USERNAME=${2:-}
PASSWORD=${3:-}
if [ -z "${USERNAME}" -o -z "${PASSWORD}" ] ; then
	usage
	exit 2
fi

# Visit CAS and get a login form. This includes a unique ID for the form, which we will
# store in CAS_ID and attach to our form submission. jsessionid cookie will be set here
CAS_INFO=`curl -s -k -c $COOKIE_JAR https://$CAS_HOSTNAME/cas/login?service=$ENCODED_DEST`

# Extract "lt" and "execution" fields from output. Note: grep will fail this
# if the "lt" field is missing, which is allowed according to the CAS spec:
# https://apereo.github.io/cas/4.2.x/protocol/CAS-Protocol-Specification.html
CAS_ID=`echo "$CAS_INFO" | ./extractHtmlInputValue.py lt`

# Note: Extracting field values this way is fragile... Should use a legit HTML parser.
CAS_EXECUTION=`echo "$CAS_INFO" | ./extractHtmlInputValue.py execution`

# Submit the login form, using the cookies saved in the cookie jar and the form submission
# ID just extracted. We keep the headers from this request as the return value should be a
# 302 including a "ticket" param which we'll need in the next request

if [[ -z "$CAS_ID" ]] ; then
   curl -s -k --data "username=$USERNAME&password=$PASSWORD&_eventId=submit" --data-urlencode "execution=$CAS_EXECUTION" -i -b $COOKIE_JAR -c $COOKIE_JAR https://$CAS_HOSTNAME/cas/login?service=$ENCODED_DEST -D $HEADER_DUMP_DEST -o /dev/null
else
   curl -s -k --data "username=$USERNAME&password=$PASSWORD&lt=$CAS_ID&_eventId=submit" --data-urlencode "execution=$CAS_EXECUTION" -i -b $COOKIE_JAR -c $COOKIE_JAR https://$CAS_HOSTNAME/cas/login?service=$ENCODED_DEST -D $HEADER_DUMP_DEST -o /dev/null
fi

#Visit the URL with the ticket param to finally set the casprivacy and, more importantly,
# MOD_AUTH_CAS cookie. Now we've got a MOD_AUTH_CAS cookie, anything we do in this session
# will pass straight through CAS.

#echo "HEADER_DUMP_DEST: " $(grep Location ${HEADER_DUMP_DEST})
CURL_DEST=$(grep Location ${HEADER_DUMP_DEST} | sed 's/Location:\s*//' | tr -d '[[:space:]]')
#echo "CURL DEST: " ${CURL_DEST}

if [[ -z "$CURL_DEST" ]]; then
    echo "Cannot login. Check if you can login in a browser using the configured user/password"
    echo "and the following url:"
    echo "https://$CAS_HOSTNAME/cas/login?service=$ENCODED_DEST"
    exit 1
fi

# -g turns off globbing (to allow brackets in the URL)
curl -s -k -b $COOKIE_JAR -c $COOKIE_JAR -g -J --location-trusted --max-redirs 4 "$CURL_DEST"

#If our destination is not a GET we'll need to do a GET to, say, the user dashboard here

#Visit the place we actually wanted to go to
curl -s -k -b $COOKIE_JAR -g -J --location-trusted --max-redirs 4 "$DEST"
