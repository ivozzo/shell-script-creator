#!/bin/bash

scriptPrefix="ssc"
declare -A properties=()

#
# printProperties
#
#   Print properties and / or variables
#
printProperties() {
    echo ""
    echo '################# PROPERTIES #################'
    #declare -p | grep -vE "^.*(PWD).*$" | grep -E "^.*$scriptPrefix\_.*\_.*$" | awk '{print $3}'
    for property in "${properties[@]}"; do
            echo $property=${!property}
        done
}

#
# readProperties
#
#   Read properties file and save variables
#
#   params:
#     1: l_file - Properties file to read
readProperties() {
    local l_file="$1"
    local currentSection=""
    local property=""
    local value=""

    declare -i index=1

    while read -r line; do

        ## Search for section
        if echo "$line" | grep -E "^\[.*\]$" >/dev/null; then
            currentSection=$(echo "$line" | sed -e "s/\[//g" -e "s/\]//g")
            echo "Found section $currentSection"
        elif echo "$line" | grep -E "^.*=.*$" >/dev/null; then
            property=$(echo "$line" | cut -d'=' -f1)
            value=$(echo "$line" | cut -d'=' -f2)

            echo "Found property $property with value $value"
            declare -g "$scriptPrefix"_"$currentSection"_"$property"="$value"
            properties[$index]="$scriptPrefix"_"$currentSection"_"$property"
            ((index++))
        fi

    done <"$l_file"
}

readProperties "$1"
printProperties
