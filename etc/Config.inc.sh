#!/bin/bash
# **
# @author Marko Schulz - <info@tuxnet24.de>
# @package Cloudflare DynDNS
# @file etc/Config.inc.sh
# @since 2024-12-04
# @version 1.0.0
#
# This is the main configuration file. All values are stored
# in the associative array cfg.
# *

# [GLOBAL CONFIGURATION]
#
# Configuration variables as cfg assoc array
declare -gA cfg

# Path to the logfile for the Logger class - Logger::LOGGER_LOGFILE
cfg[logfile]="${cwd}/log/dyndns.log"

# Path to the temporary error logfile
cfg[errorlogfile]="${cwd}/log/error.log"

# Loglevel for Logger class - Logger::LOGGER_LOGLEVEL
cfg[loglevel]="info"

# Timestamp format for the Logger class (posix date format) - Logger::LOGGER_TIMEFORMAT
cfg[logtimestamp]="%d.%m.%Y %H:%M:%S"

# Output for the Logger class (file|stdout|stderr) - Logger::LOGGER_OUTPUT
cfg[logoutput]="file"

# Cloudflare API URL - Cloudflare::CLOUDFLARE_APIURL
cfg[cloudflare_apiurl]="https://api.cloudflare.com/client/v4"

# Cloudflare API token - Cloudflare::CLOUDFLARE_TOKEN
cfg[cloudflare_token]="<Encrypted Cloudflare API token>"

# The DynDNS domain which is to be updated
cfg[dyndns_domain]="<your dyndns domain on cloudflare>"

# Path in which the last ip address is saved
cfg[lastipaddr]="${cwd}/log/lastipaddr.dat"

# Should an email be sent if the ip address was updeted?
cfg[notify_onsuccess]="Yes"

# Email of the recipient
cfg[notify_recipient]="<your email address>"

# Supject for the notify email. %s will be replace with ERROR or OK
cfg[notify_subject]="[$(whoami)@$(hostname)] DynDNS update %s"

# Email headline on success or error
cfg[notify_headline_info]="DynDNS update was successful"
cfg[notify_headline_error]="DynDNS update has failure"

# Count to display the last lines in the email message. O = No
cfg[nofify_logtrace_count]=10

# List of multi-part TLDs - Cloudflare::CLOUDFLARE_MULTITLD
declare -ga multitlds=(
    "co.uk"
    "gov.uk"
    "ac.uk"
    "org.uk"
    "co.ua"
)

# vim: syntax=bash ts=2 sw=2 sts=2 sr noet
# EOF