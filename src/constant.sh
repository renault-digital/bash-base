#!/usr/bin/env bash

NEW_LINE_SED="\\$(echo -e '\r\n')" # Constant: the return and new line character, used with sed
export NEW_LINE_SED

COLOR_BOLD_MAGENTA=$'\e[1;35m' # Constant: color for printing Header
COLOR_GRAY=$'\e[0;37m'         # Constant: color for printing message of Debug
COLOR_BOLD_RED=$'\e[1;91m'     # Constant: color for printing message of Error/KO
COLOR_BOLD_YELLOW=$'\e[0;33m'  # Constant: color for printing message of Warning
COLOR_BOLD_GREEN=$'\e[1;32m'   # Constant: color for printing message of OK
COLOR_BLUE=$'\e[0;34m'         # Constant: color for printing Value
COLOR_END=$'\e[0m'             # Constant: color for printing message of INFO and others, reset to default
export COLOR_BOLD_MAGENTA COLOR_GRAY COLOR_BOLD_RED COLOR_BOLD_YELLOW COLOR_BOLD_GREEN COLOR_BLUE COLOR_END

LOG_LEVEL_ERROR=4
LOG_LEVEL_WARN=3
LOG_LEVEL_INFO=2
LOG_LEVEL_DEBUG=1
export LOG_LEVEL_DEBUG LOG_LEVEL_INFO LOG_LEVEL_WARN LOG_LEVEL_ERROR
