#!/usr/bin/env bash

NEW_LINE_SED="\\$(echo -e '\r\n')" # Constant: the return and new line character, used with sed
COLOR_BOLD_BLACK=$'\e[1;30m'       # Constant: color for printing Header
COLOR_BOLD_RED=$'\e[1;91m'         # Constant: color for printing message of Error/KO
COLOR_BOLD_GREEN=$'\e[1;32m'       # Constant: color for printing message of OK
COLOR_BLUE=$'\e[0;34m'             # Constant: color for printing Value
COLOR_END=$'\e[0m'                 # Constant: color for others, reset to default
export NEW_LINE_SED COLOR_BOLD_BLACK COLOR_BOLD_RED COLOR_BOLD_GREEN COLOR_BLUE COLOR_END
