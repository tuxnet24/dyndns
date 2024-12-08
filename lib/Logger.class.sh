#!/bin/bash
# **
# @author Marko Schulz - <info@tuxnet24.de>
# @package Cloudflare DynDNS
# @file lib/Logger.class.sh
# @since 2024-12-04
# @version 1.0.0
#
# This function acting as a pseudo-class. This works only from
# Bash >=4.2
# The Logfile will be defined in LOGGER_LOGFILE and you
# have to set LOGGER_LOGLEVEL to set the loglevel. Also
# you can define in LOGGER_TIMEFORMAT your own format for
# the timestamp.
#
# @param string $* The debugging log message
# @return void
# *
function Logger () {

    # **
    # Log method for INFO messages.
    # 
    # @access public
    # @param string $* The log message
    # @return void
    # *
    function info () {
        _logger "INFO" "$LOGNAME" "$(_callerinfo)" "$@"
    }

    # **
    # Log method for WARN messages.
    # 
    # @access public
    # @param string $* The log message
    # @return void
    # *
    function warn () {
        _logger "WARN" "$LOGNAME" "$(_callerinfo)" "$@"
    }

    # **
    # Log method for ERROR messages.
    # 
    # @access public
    # @param string $* The log message
    # @return void
    # *
    function error () {
        _logger "ERROR" "$LOGNAME" "$(_callerinfo)" "$@"
    }

    # **
    # Log method for DEBUG messages.
    # 
    # @access public
    # @param string $* The log message
    # @return void
    # *
    function debug () {
        _logger "DEBUG" "$LOGNAME" "$(_callerinfo)" "$@"
    }

    # **
    # Main logger function to handle different log levels.
    # Logs messages to the defined logfile based on LOGGER_LOGLEVEL setting.
    # 
    # @access private
    # @param string $1 The log level (INFO, WARN, ERROR, DEBUG)
    # @param string $* The log message
    # @return void
    # *

    function _logger () {

        local level=$1;  shift # Removes the first argument (level) so $* is just the rest
        local user=$1;   shift # Removes the first argument (user) so $* is just the rest
        local caller=$1; shift # Removes the first argument (caller) so $* is just the message
        local format=${LOGGER_TIMEFORMAT:-'%Y-%m-%d %H:%M:%S'} # from env:LOGGER_TIMEFORMAT
        local log_file=${LOGGER_LOGFILE:-/dev/null}            # from env:LOGGER_LOGFILE
        local log_level=${LOGGER_LOGLEVEL:-"NONE"}             # from env: LOGGER_LOGLEVEL
        local output_target=${LOGGER_OUTPUT:-file}             # from env: LOGGER_OUTPUT

        # The array defines the loglevels
        declare -A LEVELS=( ["NONE"]=0 ["TRACE"]=1 ["DEBUG"]=2 ["INFO"]=3 ["WARN"]=4 ["ERROR"]=5 )

        local current_level=${LEVELS[${log_level^^}]:-0}   # Default to "NONE" if not set
        local message_level=${LEVELS[$level]}

        # Check if logging is necessary
        if [[ $message_level -ge $current_level ]]; then

            # Ensure log file is writable if logging is allowed
            if [[ "$log_file" != "/dev/null" && ! -w "$(dirname "$log_file")" ]]; then
                echo "The log directory $(dirname "$log_file") is not writable for ${LOGNAME:-you}!" >&2
                return 1
            fi

            # Formatting log messages
            local log_message="[$( date +"$format" )] [$level] [$user] [$caller] $*"

            # Write the log message to the defined output
            case "$output_target" in
                file)
                    echo "$log_message" >>"$LOGGER_LOGFILE"
                    ;;
                stdout)
                    echo "$log_message"
                    ;;
                stderr)
                    echo "$log_message" >&2
                    ;;
                *)
                    echo "Invalid LOGGER_OUTPUT setting: $output_target" >&2
                    return 1
                ;;
            esac

        fi

    }

    # **
    # helper function for determining the file and function of the actual caller.
    # 
    # @access private
    # @return string
    # *
    function _callerinfo () {
        local file="${BASH_SOURCE[2]:-$0}"   # The original caller (2 levels back)
        local func="${FUNCNAME[2]:--}"       # The function of the original caller (2 levels back)

        # Only the base name of the file (without path and extension)
        file="$(basename "${file}" .sh)"

        # Return as formatted character string 'file::func'
        echo "${file}::${func}"
    }

    # Export the following methods as public methods so that they can be used outside the class
    export -f info warn error debug

}

# Check, if we have bash version greater equal 4.2
if [ "$(echo "$BASH_VERSION" | grep -oE '^[0-9]+(\.[0-9]+)?' | sed 's/\.//')" -lt 42 ]; then
    echo "Error: You cannot include the ${BASH_SOURCE[0]} file because your Bash version is outdated. At least version bash 4.2 is required!" >&2
    exit 1
fi

# Load the Logger class
Logger

# vim: syntax=bash ts=2 sw=2 sts=2 sr noet
# EOF