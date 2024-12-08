#!/bin/bash
# **
# @author Marko Schulz - <info@tuxnet24.de>
# @package Cloudflare DynDNS
# @file lib/DynDNS.inc.sh
# @since 2024-12-04
# @version 1.0.0
#
# This is the main program for the Cloudflare DynDNS. 
# *

# **
# This function display the usage of this program.
#
# @return void
# *
function usage () {

echo -e "Usage: $0 [OPTIONS] <TOKEN>\a\n"
echo -e "Options:"
echo -e "  -h, --help            Show this help message and exit."
echo -e "  <TOKEN>               Encrypts the provided TOKEN for use in cfg[cloudflare_token].\n"
echo -e "Examples:"
echo -e "  $0 -h                 Show the help message."
echo -e "  $0 myToken123         Encrypt 'myToken123' and output the encrypted string.\n"
exit 0

}

# **
# This function send an html email.
#
# @param string $1 The body text that will be send
# @param string $2 The subject status (INFO|ERROR)
# @return void
# *
function sendemail () {

local message="$1"     # The message to be sent
local status="$2"      # Status: INFO or ERROR
local title=${cfg[notify_headline_error]}
local logtrace=""

# If we have the $status INFO, we turn this to OK 
if [ "${status}" = "INFO" ]; then
    status="OK"
    title=${cfg[notify_headline_info]}
fi

# Set subject dynamically based on the status
local subject=$(printf "${cfg[notify_subject]}" "$status")

# Display last N line as logtrace in the email message
if [ ${cfg[nofify_logtrace_count]} -gt 0 ]; then
    logtrace="<p><pre>$( tail -n${cfg[nofify_logtrace_count]} ${cfg[logfile]} )</pre></p>"
fi

# Formatting HTML messages
local html_content="<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Email notification</title>
<style>
body{font-family:Arial,sans-serif;color:#333;background-color:#f4f4f4;padding:20px}
.container{max-width:600px;margin:0 auto;background-color:#fff;padding:20px;border-radius:8px;box-shadow:0 2px 5px rgba(0,0,0,.1)}
h2{color:#06c}
p{line-height:1.6}
</style>
</head>
<body>
    <div class=\"container\">
        <h2>${title}</h2>
        <p>${message}</p>
        ${logtrace}
        <p>Kind regards,<br>Your team from DnyDNS Serive</p>
    </div>
</body>
</html>"

# Convert ASCII to base64
subject=$( echo -n "$subject" | base64 | tr -d '\n' )

# Send emal message with 'mail'
echo -e "$html_content" | \
    mail -s "=?UTF-8?B?${subject}?=" -a "Content-Type: text/html; charset=UTF-8" "${cfg[notify_recipient]}"

}

# **
# This function send and email, write message
# to the logfile and on error to STDERR.
#
# @param string $1 The status (error|info)
# @param string $1 The message for logging, STDERR and email message
# @return void
# *
function finish () {

local status=$1; shift
local message=$*
local ecode=0

# Set the exit code depending on $status
if [ "${status}" = "error" ]; then
    ecode=1
fi

# Send notify message on error or on success when cfg[notify_onsuccess] is Yes
if [ $ecode -eq 1 ]; then
    sendemail "${msg}" "${status^^}"
elif [ $ecode -eq 0 -a ${cfg[notify_onsuccess]} = "Yes" ]; then
    sendemail "${msg}" "${status^^}"
fi

# Check, if $status exists as function
if declare -F "$status" &>/dev/null; then
    # Write log message
    $status "${message}"
fi

# Write message to STDERR
[ $ecode -eq 1 ] && echo "${message}" >&2

exit $ecode

}

# **
# This function update the DynDNS domain with the given ip address.
#
# @param string $1 The new ip address
# @return void
# *
function update_dns () {

local myip=$1
local msg=""

if [ ! -n "${myip}" ]; then
    # Get error message and finish the program
    msg="No current ip address was defined as argument."
    finish "error" "${msg}"
fi

# Get the apex domain as dns zone
dyndns_zone=$( get_apex_domain "${cfg[dyndns_domain]}" )

# Get the zone ID
zid=$( zones_id "${dyndns_zone}" 2>${cfg[errorlogfile]} )
if [ ! -n "${zid}" ]; then
    # Get error message and finish the program
    msg="$( cat ${cfg[errorlogfile]} 2>/dev/null)"
    finish "error" "${msg}"
else
    info "The zone ID of ${dyndns_zone} is $zid"
fi

# Get the record id
rid=$( record_id "$zid" "${cfg[dyndns_domain]}" 2>${cfg[errorlogfile]} )
if [ ! -n "${rid}" ]; then
    # Get error message and finish the program
    msg="$( cat ${cfg[errorlogfile]} 2>/dev/null)"
    finish "error" "${msg}"
else
    info "The record ID of ${cfg[dyndns_domain]} is $rid"
fi

# Update the record
if ! record_modify "$zid" "$rid" "${cfg[dyndns_domain]}" "${myip}" "A" 2>${cfg[errorlogfile]}; then
    # Get error message and finish the program
    msg="$( cat ${cfg[errorlogfile]} 2>/dev/null)"
    finish "error" "${msg}"
else
    # Save the last ipaddr
    echo "${myip}" >${cfg[lastipaddr]}
    # Define the message and finish the program
    msg="The record of ${cfg[dyndns_domain]} was successfuly updated with ip address ${myip}."
    finish "info" "${msg}"
fi

}

# vim: syntax=bash ts=2 sw=2 sts=2 sr noet
# EOF