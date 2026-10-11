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
stop_if_failed() {
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
confirm_to_continue() {
	local response
	print_args "$@"

	if [[ "${modeQuiet:-false}" != true ]]; then
		# Bash `read -p` and zsh `read "name?prompt"` are shell-specific.
		# Match Bash read -p behavior by showing the prompt only for a TTY.
		if [[ -t 0 ]]; then
			printf '%s' 'Continue ? [y/N] ' >&2
		fi
		read -r response || response=""

		case "$response" in
		[yY] | [yY][eE][sS])
			printf '%s\n' 'Continue...'
			sleep 1
			;;
		*)
			printf '%s\n' 'Exiting...'
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
#     **[subject]** optional, the subject name, default to predicate
#     **[interval]** optional, the interval of number of seconds between the checks, default to 3
# @EXAMPLES
#     wait_for 'test -f /tmp/output.txt' 'file existed' 3
# @SEE_ALSO
#     confirm_to_continue, stop_if_failed
wait_for() {
	local predicate="${1}"
	local subject="${2-${predicate}}"
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
declare_heredoc() {
	local _bash_base_heredoc_target="${1-}"
	local _bash_base_heredoc_content

	# Only identifier names may appear as the left-hand side of an eval.
	case "$_bash_base_heredoc_target" in
	'' | [!a-zA-Z_]* | *[!a-zA-Z0-9_]*) return 2 ;;
	esac

	_bash_base_heredoc_content="$(cat)"
	# Expand the content as a variable value, never parse it as shell code.
	eval "${_bash_base_heredoc_target}=\"\$_bash_base_heredoc_content\""
}
