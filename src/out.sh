#!/usr/bin/env bash

source src/constant.sh

LOG_LEVEL=$LOG_LEVEL_INFO # override this default value in your script if you want to change the log level.

# @NAME
#     print_info -- print the information message with font color gray
# @SYNOPSIS
#     print_info string
# @DESCRIPTION
#     **string** the message
# @EXAMPLES
#     print_info "my message"
# @SEE_ALSO
#     print_header, print_error, print_success, print_warn, print_args, print_info
function print_debug() {
	if [[ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]]; then
		echo -e "${COLOR_GRAY}DEBUG: $*${COLOR_END}"
	fi
}

# @NAME
#     print_info -- print the information message with font color default
# @SYNOPSIS
#     print_info string
# @DESCRIPTION
#     **string** the message
# @EXAMPLES
#     print_info "my message"
# @SEE_ALSO
#     print_header, print_error, print_success, print_warn, print_args, print_debug
function print_info() {
	if [[ $LOG_LEVEL -le $LOG_LEVEL_INFO ]]; then
		echo -e "${COLOR_END}INFO: $*"
	fi
}

# @NAME
#     print_warn -- print the warning message with prefix 'WARN:' and font color yellow
# @SYNOPSIS
#     print_warn string
# @DESCRIPTION
#     **string** the message
# @EXAMPLES
#     print_warn "my message"
# @SEE_ALSO
#     print_header, print_error, print_success, print_info, print_args, print_debug
function print_warn() {
	if [[ $LOG_LEVEL -le $LOG_LEVEL_WARN ]]; then
		echo -e "${COLOR_BOLD_YELLOW}WARN: $* ${COLOR_END}"
	fi
}

# @NAME
#     print_error -- print the error message with prefix 'ERROR:' and font color red
# @SYNOPSIS
#     print_error string
# @DESCRIPTION
#     **string** the error message
# @EXAMPLES
#     print_error "my error message"
# @SEE_ALSO
#     print_header, print_success, print_warn, print_info, print_args, print_debug
function print_error() {
	if [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]]; then
		echo -e "${COLOR_BOLD_RED}ERROR: $* ${COLOR_END}"
	fi
}

# @NAME
#     print_success -- print the success message with prefix 'OK:' and font color green
# @SYNOPSIS
#     print_success string
# @DESCRIPTION
#     **string** the message
# @EXAMPLES
#     print_success "my message"
# @SEE_ALSO
#     print_header, print_error, print_warn, print_info, print_args, print_debug
function print_success() {
	if [[ $LOG_LEVEL -le $LOG_LEVEL_WARN ]]; then
		echo -e "${COLOR_BOLD_GREEN}OK: $* ${COLOR_END}"
	fi
}

# @NAME
#     print_args -- show the name and value of variables
# @SYNOPSIS
#     print_args variableName...
# @DESCRIPTION
#     **variableName...** some existed variable names to show its value
# @EXAMPLES
#     var1="value 1"
#     var2="value 2"
#     print_args var1 var2
# @SEE_ALSO
#     print_header, print_error, print_success, print_warn, print_info, print_debug
function print_args() {
	if [[ $LOG_LEVEL -le $LOG_LEVEL_WARN ]]; then
		local varName varValue varValueOutput
		for varName in "$@"; do
			varValue=$(eval echo '$'"${varName}")
			varValueOutput=$([[ -z "${varValue}" ]] && print_error "<NULL>" || echo "${COLOR_BLUE}${varValue}${COLOR_END}")
			printf "%-30.30s%s\n" "${varName}:" "${varValueOutput}"
		done
	fi
}

# @NAME
#     print_header -- print the header value with prefix '\n###' and bold font
# @SYNOPSIS
#     print_header string
# @DESCRIPTION
#     **string** the string of header title
# @EXAMPLES
#     print_header "My header1"
# @SEE_ALSO
#     print_error, print_success, print_warn, print_info, print_args, print_debug
function print_header() {
	if [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]]; then
		echo -e "${COLOR_BOLD_MAGENTA}\n### $* ${COLOR_END}"
	fi
}
