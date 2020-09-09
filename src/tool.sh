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
#     print_error
function print_header() {
	echo -e "${COLOR_BOLD_BLACK}\n### $* ${COLOR_END}"
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
#     print_header
function print_error() {
	echo -e "${COLOR_BOLD_RED}ERROR: $* ${COLOR_END}"
}

# @NAME
#     stop_if_failed -- stop the execute if last command exit with fail code (no zero)
# @SYNOPSIS
#     stop_if_failed string
# @DESCRIPTION
#     'trap' or 'set -e' is not recommended
#     **string** the error message to show
# @EXAMPLES
#     rm -fr "${destProjectPath}"
#     stop_if_failed "ERROR: can't delete the directory '${destProjectPath}' !"
# @SEE_ALSO
function stop_if_failed() {
	if [[ $? -ne 0 ]]; then
		print_error "${1}"
		exit 1
	fi
}

# @NAME
#     declare_heredoc -- define a variable and init its value from heredoc
# @SYNOPSIS
#     declare_heredoc newVarName <<-EOF
#     ...
#     EOF
# @DESCRIPTION
#     **newVarName** the variable name, the content of heredoc will be assigned to it
# @EXAMPLES
#     declare_heredoc records <<-EOF
#     record1
#     record2
#     EOF
# @SEE_ALSO
function declare_heredoc() {
	eval "$1='$(cat)'"
}
