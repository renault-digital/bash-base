#!/usr/bin/env bash

source src/constant.sh

# @NAME
#     print_header -- print the header value with prefix '\n###' and bold font
# @SYNOPSIS
#     print_header string
# @DESCRIPTION
#     **string** the string of header title
# @EXAMPLES
#     print_header "My header1"
# @SEE_ALSO
#     print_error, print_success, print_warn, print_info, args_print
function print_header() {
	echo -e "${COLOR_BOLD_BLACK}\n### $* ${COLOR_END}"
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
#     print_header, print_error, print_warn, print_info, args_print
function print_success() {
	echo -e "${COLOR_BOLD_GREEN}OK: $* ${COLOR_END}"
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
#     print_header, print_error, print_success, print_warn, args_print
function print_info() {
	echo -e "${COLOR_END}$*"
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
#     print_header, print_error, print_success, print_info, args_print
function print_warn() {
	echo -e "${COLOR_BOLD_YELLOW}WARN: $* ${COLOR_END}"
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
#     print_header, print_success, print_warn, print_info, args_print
function print_error() {
	echo -e "${COLOR_BOLD_RED}ERROR: $* ${COLOR_END}"
}
