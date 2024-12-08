#!/bin/bash
# **
# @author Marko Schulz - <info@tuxnet24.de>
# @package Cloudflare DynDNS
# @file lib/Cloudflare.class.sh
# @since 2024-12-04
# @version 1.0.0
#
# This function acting as a pseudo-class. This works only from Bash >=4.2
#
# The Tools function contains useful functions that have no dependencies
# on other functions and can be included into your code without hesitation.
# *
function Cloudflare () {

    # **
    # This function modify an cloudflare dns record.
    #
    # @access public
    # @param string $1 The zone ID
    # @param string $2 The record ID
    # @param string $3 The record value like hostname
    # @param string $4 The record value like ip address of an A record
    # @param string $5 The record type (Default: A)
    # @return bool
    # *
    function record_modify () {

        local type=${5:-A} # Default record type

        if ! _requirements ; then
            return 1
        fi

        if [ ! -n "$1" ] ; then
            echo "You have to define a zone ID as first argument." >&2
            return 1
        fi

        if [ ! -n "$2" ] ; then
            echo "You have to define a record ID as second argument." >&2
            return 1
        fi

        if [ ! -n "$3" ] ; then
            echo "You have to define a name for the ${type} record as the third argument." >&2
            return 1
        fi

        if [ ! -n "$4" ] ; then
            echo "You have to define a value for the ${type} record as the fourth argument." >&2
            return 1
        fi

        # Build the post data as application/json
        local postdata="{\"type\": \"${type^^}\", \"name\": \"${3}\", \"content\": \"${4}\"}"

        local response=$( curl -s -X PUT "${CLOUDFLARE_APIURL}/zones/${1}/dns_records/${2}" \
            -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" -d "${postdata}" -w "%{http_code}" )

        # Separate response body and status code
        local code="${response: -3}"
        local body="${response:0:${#response}-3}"

        if [ "$code" -eq 200 ]; then
            if [[ $(echo "$body" | jq -r '.success') == "true" ]]; then
                return 0
            else
                echo "$(echo "$body" | jq -r '.messages[]')" >&2
                return 1
            fi
        else
            _httperror $code
            return 1
        fi

    }

    # **
    # This function get the record ID of a defined zone ID by the defined dns entry.
    #
    # @access public
    # @param string $1 The zone ID
    # @param string $2 The dns entry
    # @param string $3 The record type (Default: A)
    # @return string
    # *
    function record_id () {

        local type=${3:-A} # Default record type

        if ! _requirements ; then
            return 1
        fi

        if [ ! -n "$1" ] ; then
            echo "You have to define a zone ID as first argument." >&2
            return 1
        fi

        if [ ! -n "$2" ] ; then
            echo "You have to define a DNS entry as second argument." >&2
            return 1
        fi

        local response=$( curl -s -X GET "${CLOUDFLARE_APIURL}/zones/${1}/dns_records?type=${type^^}&name=${2}" \
            -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" -w "%{http_code}" )

        # Separate response body and status code
        local code="${response: -3}"
        local body="${response:0:${#response}-3}"

        if [ "$code" -eq 200 ]; then
            echo "${body}" | jq -r '.result[] | .id'
            return 0
        else
            _httperror $code
            return 1
        fi

    }

    # **
    # This function get the zone ID of a defined zone (apex domain).
    #
    # @access public
    # @param string $1 The domain
    # @return string
    # *
    function zones_id () {

        if ! _requirements ; then
            return 1
        fi

        if [ ! -n "$1" ] ; then
            echo "You have to define a domain as argument." >&2
            return 1
        fi

        local response=$( curl -s -X GET "${CLOUDFLARE_APIURL}/zones" \
            -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" -w "%{http_code}" )

        # Separate response body and status code
        local code="${response: -3}"
        local body="${response:0:${#response}-3}"

        if [ "$code" -eq 200 ]; then
            echo "${body}" | \
                jq -r --arg domain "$1" '.result[] | select(.name==($domain)) | .id'
            return 0
        else
            _httperror $code
            return 1
        fi

    }

    # **
    # This function get the apex domain of a defined dns entry.
    #
    # @access public
    # @param string $1 The dns entry like www.example.com
    # @return string
    # *
    function get_apex_domain () {

        local domain=$1
        local -a tlds_array=()
        local tld

        # First split the domain into parts
        local domain_parts=(${domain//./ })

        # Convert the string into an array, if CLOUDFLARE_MULTITLD is defined
        if _isset 'CLOUDFLARE_MULTITLD'; then
            read -a tlds_array <<< "$CLOUDFLARE_MULTITLD"
        fi

        # If the domain has only one part (e.g. "example" instead of "example.com")
        if [[ ${#domain_parts[@]} -eq 1 ]]; then
            echo "$domain"
            return
        fi

        # Check whether the last two parts form a multi-part TLD
        for tld in "${tlds_array[@]}"; do
            # If the last parts match a multi-part TLD
            if [[ "${domain_parts[-2]}.${domain_parts[-1]}" == "$tld" ]]; then
                # Then return what goes up to this TLD
                echo "${domain_parts[-3]}.${domain_parts[-2]}.${domain_parts[-1]}"
                return
            fi
        done

        # If no multi-part TLD is found, extract the domain up to the last point
        echo "${domain_parts[-2]}.${domain_parts[-1]}"

    }

    # **
    # This function return the right status message of the defined status code.
    #
    # @access private
    # @param int $1 The http status code
    # @return string
    # *
    function _httperror () {

        case $1 in
            400)
                echo "400 - Bad request, please check the syntax of the request." >&2
                ;;
            401)
                echo "401 - Authentication required, please check your credentials." >&2
                ;;
            403)
                echo "403 - Access denied, you do not have permission." >&2
                ;;
            404)
                echo "404 - The requested resource was not found." >&2
                ;;
            500)
                echo "500 - Internal server error, please try again later." >&2
                ;;
            502)
                echo "502 - Invalid response from the server, please try again later." >&2
                ;;
            503)
                echo "503 - Service unavailable, please try again later." >&2
                ;;
            *)
                echo "Unexpected error with status code $1." >&2
                ;;
        esac

    }

    # **
    # This function check, if all class variables are set.
    #
    # @access private
    # @param string $1 The variable name (only the name, var not $var)
    # @return bool
    # *
    function _requirements () {

        # Check, if the CLOUDFLARE_APIURL is defined
        if _isset 'CLOUDFLARE_APIURL'; then
            # Check if the CLOUDFLARE_APIURL is a vailid url
            if ! _is_url "${CLOUDFLARE_APIURL}" ; then
                echo "\$CLOUDFLARE_APIURL does not contain a valid URL" >&2
                return 1
            fi
        else
            echo "\$CLOUDFLARE_APIURL does not exists" >&2
            return 1
        fi
        # Check, if the CLOUDFLARE_TOKEN is defined
        if ! _isset 'CLOUDFLARE_TOKEN'; then
            echo "\$CLOUDFLARE_TOKEN does not exists" >&2
            return 1
        fi
        return 0

    }

    # **
    # This function check the format of an URL.
    #
    # @access private
    # @param string $1 The URL to check
    # @return bool
    # *
    function _is_url () {

        # Checks whether the parameter passed corresponds to the regex
        if echo "$1" | grep -q -P '^(https?|ftp)://[a-zA-Z0-9.-]+(?:\.[a-zA-Z]{2,})+(?::[0-9]+)?(/.*)?$'; then
            return 0  # valid URL
        else
            return 1  # invalid format
        fi

    }

    # **
    # This function check, if a defined variable exist
    # or if an array index/key exists.
    #
    # @access private
    # @param string $1 The variable key
    # @param string $2 The array key/index
    # @return bool
    # *
    function _isset() {

        local var_name="$1"
        local key="$2"

        # Check whether the variable or array exists
        if ! declare -p "$var_name" &>/dev/null; then
            return 1
        fi

        # If a key has been specified, check whether it exists in the array
        if [ -n "$key" ]; then
            if [ "${!var_name[$key]+_}" ]; then
                return 0
            else
                return 1
            fi
        fi

        return 0

    }

    # Export all public methods
    export -f zones_id
    export -f record_id
    export -f record_modify
    export -f get_apex_domain

}

# Check, if we have bash version greater equal 4.2
if [ "$(echo "$BASH_VERSION" | grep -oE '^[0-9]+(\.[0-9]+)?' | sed 's/\.//')" -lt 42 ]; then
    echo "Error: You cannot include the ${BASH_SOURCE[0]} file because your Bash version is outdated. At least version bash 4.2 is required!" >&2
    exit 1
fi

# Load the Cloudflare class
Cloudflare

# vim: syntax=bash ts=2 sw=2 sts=2 sr noet
# EOF