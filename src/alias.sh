#!/usr/bin/env bash

source src/out.sh
source src/tool.sh

#     Backward-compatible command names.  Use wrapper functions rather than aliases:
#     aliases need different non-interactive expansion rules in Bash and zsh, while
#     functions work identically when this library is sourced by either shell.

# @NAME
#     args_confirm -- show the name and value of variables, and continue execute if args_confirm by user, or exit if not
# @SYNOPSIS
#     args_confirm variableName...
# @DESCRIPTION
#     **variableName...** some existed variable names to show its value
# @EXAMPLES
#     a="correct value"
#     b="wrong value"
#     args_confirm a b
# @SEE_ALSO
#     args_print, stop_if_failed
args_confirm() {
	confirm_to_continue "$@"
}

# @NAME
#     args_print -- if LOG_LEVEL<=$LOG_LEVEL_WARN, show the name and value of variables
# @SYNOPSIS
#     args_print variableName...
# @DESCRIPTION
#     **variableName...** some existed variable names to show its value
# @EXAMPLES
#     var1="value 1"
#     var2="value 2"
#     args_print var1 var2
# @SEE_ALSO
#     print_header, print_error, print_success, print_warn, print_info, print_debug
args_print() {
	print_args "$@"
}
