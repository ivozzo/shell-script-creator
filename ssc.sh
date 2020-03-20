#!/bin/bash

scriptPrefix="ssc"
scriptSources="src"
dryRun=False
declare -A properties=()

#
# Colored message
#
#   Show a colored message
#
#   params:
#     1: l_color - Required ANSI color (see http://www.csc.uvic.ca/~sae/seng265/fall04/tips/s265s047-tips/bash-using-colors.html)
#     2: l_msg - Message to print
#
function color_msg() {
    local l_color="$1"
    local l_msg="$2"
    local endColor='\e[0m'

    echo -e "${l_color}$l_msg${endColor}"
}

#
# Error
#
#   Show an error and quit with exit code 1
#
#   params:
#     1: l_msg - Error message to print
#
error() {
    local l_msg="$1"
    local red='\e[0;31m'

    color_msg "$red" "Error: $l_msg" 1>&2
    exit 1
}

#
# printProperties
#
#   Print properties and / or variables
#
printProperties() {
    echo ""
    echo '################# PROPERTIES #################'
    for property in "${properties[@]}"; do

        name=$(echo "$property" | cut -d '_' -f3)
        value=${!property}

        if echo "$property" | grep -E "^.*Parameters.*$" >/dev/null; then
            echo "### PARAMETER $name ###"
            echo "Default value: $(echo "$value" | cut -d ';' -f1)"
            echo "Mandatory: $(echo "$value" | cut -d ';' -f2 | sed -e "s/0/False/g" -e "s/1/True/g")"
            echo "Shortcut: -$(echo "$value" | cut -d ';' -f3)"
            echo "Description: $(echo "$value" | cut -d ';' -f4)"
            echo ""
        elif echo "$property" | grep -E "^.*Variables.*$" >/dev/null; then
            echo "$name"="$value"
        elif echo "$property" | grep -E "^.*Functionalities.*$" >/dev/null; then
            if [ "$value" == 1 ]; then
                echo "### FUNCTIONALITY $name ###"
                cat "$scriptSources/man/$name"
                echo ""
            fi
        fi
    done
}

#
# readProperties
#
#   Read properties file and save variables
#
#   params:
#     1: l_file - Properties file to read
#
readProperties() {
    local l_file="$1"
    local currentSection=""
    local property=""
    local value=""
    declare -i index=1

    while read -r line; do

        ## Search for sections in properties file and dynamically create variables
        if echo "$line" | grep -E "^\[.*\]$" >/dev/null; then
            currentSection=$(echo "$line" | sed -e "s/\[//g" -e "s/\]//g")
        elif echo "$line" | grep -E "^[^#].*=.*$" >/dev/null; then
            property=$(echo "$line" | cut -d'=' -f1)
            value=$(echo "$line" | cut -d'=' -f2)
            declare -g "$scriptPrefix"_"$currentSection"_"$property"="$value"
            properties[$index]="$scriptPrefix"_"$currentSection"_"$property"
            ((index++))
        fi

    done <"$l_file"
}

readProperties "$1"
printProperties
