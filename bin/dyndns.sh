#!/bin/bash
# **
# @author Marko Schulz - <info@tuxnet24.de>
# @package Cloudflare DynDNS
# @file bin/dyndns.sh
# @since 2024-12-04
# @version 1.0.0
#
# This is the main program for the Cloudflare DynDNS. 
# *

# Get the current working directory one directory upper from here
cwd="$(dirname -- "$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)")"

# Load the Initialization file for dyndns
source ${cwd}/lib/Bootstrap.inc.sh

# ***************************************************************
# MAIN

# Clean the house on exit
trap "rm -f ${cfg[errorlogfile]}" EXIT

# Get arguments
arg=$1

# If we have an argument
if [ -n "${arg}" ]; then
    # Display usage of this programm when -h or --help was entered
    if [ "${arg}" = "-h" -o "${arg}" = "--help" ]; then
        usage
    else
        # encrypt the given string
        encrypt "${arg}" && exit 0
    fi
fi

# Default value for the last ip address
lastip="null"

# Get the current public ip of this server
myip=$( dig +short myip.opendns.com @resolver1.opendns.com )

# Get the last ip address, if the file exists
if [ -f "${cfg[lastipaddr]}" ]; then
    lastip=$( cat ${cfg[lastipaddr]} 2>/dev/null || echo null)
fi

# Check if the last ip address is the same like $myip
if [ $lastip = $myip ]; then
    info "The DynDNS domain ${cfg[dyndns_domain]} has the current ip address ${lastip}."
    exit 0
fi

# Update the DynDNS domain with the new ip address
update_dns "${myip}"

# vim: syntax=bash ts=2 sw=2 sts=2 sr noet
# EOF