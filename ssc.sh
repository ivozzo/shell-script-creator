#!/bin/bash

scriptPrefix="ssc"
scriptSources="src"
scriptProperties=""
output=""
dryRun=false
verboseOutput=false
declare -A properties=()

# Colors
blue='\e[0;34m'
white='\e[1;37m'
green='\e[0;32m'

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
function error() {
    local l_msg="$1"
    local red='\e[0;31m'

    color_msg "$red" "Error: $l_msg" 1>&2
    exit 1
}

#
# Existance checker
#
#   Check if a variable has been initialized and popolated
#
#   params:
#     1: l_check - Variable to check
#     2: l_msg - Error message to print
#
function checkExistance() {
    local l_check="$1"
    local l_msg="$2"

    if [ -z "$l_check" ]; then
        error "$l_msg"
    fi
}

#
# printProperties
#
#   Print properties and / or variables
#
function printProperties() {
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
function readProperties() {
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

#
# Usage
#
#   Show script help
#
function usage() {
    echo ""
    color_msg "$green" "ONE SCRIPT TO RULE THEM ALL."
    color_msg "$white" "A shell script for creating other shell scripts with a lot of boilerplate code"
    echo ""
    color_msg "$blue" "OPTIONS:"
    echo '-h|--help' 'Show this help' | usagePrettyPrinter
    echo '-d|--dry-run' 'Flag this if you just want to print the process log and do not create your script, useful for testing purpose' | usagePrettyPrinter
    echo '-v|--verbose' 'Flag this if you wanna a verbose output' | usagePrettyPrinter
    echo '-p|--properties' 'The properties file to process' | usagePrettyPrinter
    echo ""
    exit 0
}

#
# usagePrettyPrinter
#
#   Specific function for pretty printing usage output format
#
function usagePrettyPrinter() {
    awk '{printf "    %-20s", $1; for (i=2; i<=NF; i++) printf $i " "; printf "\n"}'
}

#
# addFunctionality
#
#   Useful for adding functionalities onto the target script
#
#   params:
#     1: l_script - The script src file to read
#
function addFunctionality() {
    local l_script="$1"
    cat <"$scriptSources/$l_script" >>$output
}

#
# addBanner
#
#   Useful for adding banners onto the target script
#
#   params:
#     1: l_banner - The banner src file to read
#
function addBanner() {
    local l_banner="$1"
    cat <"$scriptSources/banner/$l_banner" >>$output
}

#
# addFromProperties
#
#   Add onto the output script the selected properties
#
#   params:
#     1: l_type - The type of properties to add
#
function addFromProperties() {
    local l_type="$1"

    case $l_type in
    "variables")
        for property in "${properties[@]}"; do
            name=$(echo "$property" | cut -d '_' -f3)
            value=${!property}
            if echo "$property" | grep -E "^.*Variables.*$" >/dev/null; then
                echo "$name"="$value" >>$output
            fi
        done
        ;;

    "parameters")
        for property in "${properties[@]}"; do
            name=$(echo "$property" | cut -d '_' -f3)
            if echo "$property" | grep -E "^.*Parameters.*$" >/dev/null; then
                value=$(echo "${!property}" | cut -d ";" -f1)
                echo "$name"="$value" >>$output
            fi
        done
        ;;
    esac
}

#
# Arguments checks
#
while test $# -gt 0; do
    case $1 in
    -h | --help)
        usage
        ;;

    -p | --properties)
        scriptProperties=$2
        ;;

    -d | --dry-run)
        dryRun=true
        ;;

    -v | --verbose)
        verboseOutput=true
        ;;

    *)
        params="$params $1"
        ;;
    esac
    shift
done

output="output/test.sh"
checkExistance "$scriptProperties" "The selected properties files is missing or can't be read"
color_msg "$white" "Parsing properties file $scriptProperties"
readProperties "$scriptProperties"

if [ $verboseOutput == "true" ]; then
    printProperties
fi

cat <<'EOF' >$output
#!/bin/bash

# Script generated by Shell Script Creator
# https://github.com/ivozzo/shell-script-creator
EOF

## Variables definitions and parameters initialization
addBanner "variables"
addFromProperties "variables"

# Parameters definition and initialization
addBanner "parameters"
addFromProperties "parameters"

## Base functionalitie
color_msg "$white" "Adding base functionalities onto the target script\n"
color_msg "$white" "Adding error message functionality"
addFunctionality "errorMessage"
