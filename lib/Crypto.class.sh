#!/bin/bash
# **
# @author Marko Schulz - <info@tuxnet24.de>
# @package Crypto
# @file lib/Crypto.class.sh
# @since 2024-12-05
# @version 1.0.0
#
# This function acting as a pseudo-class. This works only from Bash >=4.2
#
# The Crypto class provides methods for encrypting and decrypting strings using a secret key defined in $CRYPTOKEY.
# It relies on Perl for better handling of strings and special characters.
# *

function Crypto () {

    # **
    # This function encrypts a string using the secret key $XORKEY.
    #
    # @access public
    # @param string $1 The string which will be encrypted
    # @return string
    # *
    function encrypt () {

        local input="$1"

        if ! _requirements; then return 1; fi

        # Pass the string and the key to Perl for encryption
        local encrypted=$(perl -e '
            use strict;
            use warnings;
            my ($input, $key) = @ARGV;
            my $key_len = length($key);
            my $output = "";
            for my $i (0 .. length($input) - 1) {
                my $char = substr($input, $i, 1);
                my $key_char = substr($key, $i % $key_len, 1);
                $output .= chr(ord($char) ^ ord($key_char));
            }
            print unpack("H*", $output);  # Hexadezimal ausgeben
        ' "$input" "$CRYPTOKEY")

        echo "$encrypted"
        
    }

    # **
    # This function decrypts a string using the secret key $CRYPTOKEY.
    #
    # @access public
    # @param string $1 The string which will be decrypted
    # @return string
    # *
    function decrypt() {

        local input="$1"

        if ! _requirements; then return 1; fi

        # Pass the hex string and the key to Perl for decryption
        local decrypted=$(perl -e '
            use strict;
            use warnings;
            my ($hex, $key) = @ARGV;
            my $input = pack("H*", $hex);  # Hexadezimal in Binärdaten umwandeln
            my $key_len = length($key);
            my $output = "";
            for my $i (0 .. length($input) - 1) {
                my $char = substr($input, $i, 1);
                my $key_char = substr($key, $i % $key_len, 1);
                $output .= chr(ord($char) ^ ord($key_char));
            }
            print $output;  # Klartext ausgeben
        ' "$input" "$CRYPTOKEY")

        echo "$decrypted"

    }

    # **
    # This function check, if all class variables are set.
    #
    # @access private
    # @param string $1 The variable key
    # @return bool
    # *
    function _requirements () {

        # Check, if the CRYPTOKEY is defined
        if ! _isset 'CRYPTOKEY'; then
            echo "The secret key \$CRYPTOKEY has not been set." >&2
            return 1
        fi
        return 0

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
        if declare -p "$var_name" &>/dev/null; then
            if [ ! -n "$var_name" ]; then
                return 1
            fi
        else
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

    export -f encrypt
    export -f decrypt

}

# Check, if we have bash version greater equal 4.2
if [ "$(echo "$BASH_VERSION" | grep -oE '^[0-9]+(\.[0-9]+)?' | sed 's/\.//')" -lt 42 ]; then
    echo "Error: You cannot include the ${BASH_SOURCE[0]} file because your Bash version is outdated. At least version bash 4.2 is required!" >&2
    exit 1
fi

# Load the Crypto class
Crypto

# vim: syntax=bash ts=2 sw=2 sts=2 sr noet
# EOF
