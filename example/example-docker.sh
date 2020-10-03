#!/usr/bin/env bash

# import, install only if not existed
source <(docker run --rm renaultdigital/bash-base)

# customize the short description of default help usage
SHORT_DESC='an example shell script to show how to use bash-base '

print_header "collect information"
args_parse $# "$@" firstName lastName age sex country

args_valid_or_read firstName '^[A-Za-z ]{2,}$' "Your first name (only letters)"
args_valid_or_read lastName '^[A-Za-z ]{2,}$' "Your last name (only letters)"
args_valid_or_read age '^[0-9]{1,2}$' "Your age (maxim 2 digits))"
args_valid_or_select_pipe sex 'man|woman' "Your sex"

response=$(curl -sS 'https://restcountries.eu/rest/v2/regionalbloc/eu' --compressed)
string_pick_to_array '{"name":"' '","topLevelDomain' countryNames "$response"
args_valid_or_select country countryNames "Which country"

confirm_to_continue firstName lastName age sex country

print_header "say hello"
cat <<-EOF
	Hello $(string_upper_first "$firstName") $(string_upper "$lastName"),
	nice to meet you.
EOF

# you can run this script with -h to get the help usage
#     ./example-npm.sh -h
