#!/bin/bash
# **
# @author Marko Schulz - <info@tuxnet24.de>
# @package Cloudflare DynDNS
# @file lib/Bootstrap.inc.sh
# @since 2024-12-04
# @version 1.0.0
#
# The bootstrap is the initialisation file for the Cloudflare DynDNS.
# The configurations and classes are loaded here.
# The classes are also configured here with environment variables.
# The bootstrap is loaded by the Cloudflare DynDNS (dyndns.sh).
# *

# Current process id
ppid=$$

# Load the configuration for dyndns
source ${cwd}/etc/Config.inc.sh

# Setup of the Logger class. You can overwrite this when you set it as environment variables.
export LOGGER_LOGFILE="${LOGGER_LOGFILE:-${cfg[logfile]}}"
export LOGGER_LOGLEVEL="${LOGGER_LOGLEVEL:-${cfg[loglevel]}}"
export LOGGER_TIMEFORMAT="${LOGGER_TIMEFORMAT:-${cfg[logtimestamp]}}"
export LOGGER_OUTPUT="${LOGGER_OUTPUT:-${cfg[logoutput]}}"

# Load the Logger class for dyndns
source ${cwd}/lib/Logger.class.sh

# Setup Crypto class - set variables
#   - secret key to en/de crypt a defined string
export CRYPTOKEY="FdjjSMPKXWiJxUAdUpnWp2C98TvYsfMq"

# Load the Crypto class for dyndns
source ${cwd}/lib/Crypto.class.sh

# Setup of the Logger class. You can overwrite this when you set it as environment variables.
export CLOUDFLARE_APIURL="${CLOUDFLARE_APIURL:-${cfg[cloudflare_apiurl]}}"
export CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-$( decrypt ${cfg[cloudflare_token]} )}"
export CLOUDFLARE_MULTITLD="${CLOUDFLARE_MULTITLD:-$( echo ${multitlds[@]} )}"

# Load the Cloudflare class for dyndns
source ${cwd}/lib/Cloudflare.class.sh

# Load the DynDNS function library for dyndns
source ${cwd}/lib/DynDNS.inc.sh

# vim: syntax=bash ts=2 sw=2 sts=2 sr noet
# EOF