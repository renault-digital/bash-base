#!/usr/bin/env bash

source src/constant.sh
source src/out.sh

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
#     confirm_to_continue
function stop_if_failed() {
	if [[ $? -ne 0 ]]; then
		print_error "$*"
		exit 1
	fi
}

# @NAME
#     confirm_to_continue -- show the name and value of variables, and continue execute if confirm_to_continueed by user, or exit if not
# @SYNOPSIS
#     confirm_to_continue variableName...
# @DESCRIPTION
#     **variableName...** some existed variable names to show its value
# @EXAMPLES
#     a="correct value"
#     b="wrong value"
#     confirm_to_continue a b
# @SEE_ALSO
#     print_args, stop_if_failed
function confirm_to_continue() {
	local response
	print_args "$@"
	if ! [ "${modeQuiet}" == true ]; then
		read -r -p "Continue ? [y/N] " response

		case "${response}" in
		[yY][eE][sS] | [yY])
			echo -e "Continue..."
			sleep 1s
			;;
		*)
			echo -e "Exiting..."
			exit 1
			;;
		esac
	fi
}

# @NAME
#     wait_for -- wait the subject predicate to be true before continue
# @SYNOPSIS
#     wait_for predicate [subject] [interval]
# @DESCRIPTION
#     **predicate** a string of command, used to check is ok or not
#     **[subject]** optional, the subject name
#     **[interval]** optional, the interval of number of seconds between the checks, default to 3
# @EXAMPLES
#     wait_for 'test -f /tmp/output.txt' 'file existed' 3
# @SEE_ALSO
#     confirm_to_continue, stop_if_failed
function wait_for() {
	local predicate="${1}"
	local subject="${2-it}"
	local interval=${3-3}

	while ! eval "${predicate}"; do
		print_warn "Waiting for ${subject} to be ok"
		sleep "${interval}"
	done
	print_success "${subject} is ok now."
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
