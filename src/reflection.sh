#!/usr/bin/env bash

# @NAME
#     reflect_nth_arg -- parse a string of arguments, then extract the nth argument
# @SYNOPSIS
#     reflect_nth_arg index arguments...
# @DESCRIPTION
#     **index** a number based on 1, which argument to extract
#     **arguments...** the string to parse, the arguments and may also including the command.
# @EXAMPLES
#     reflect_nth_arg 3 ab cdv "ha ho" ==>  "ha ho"
#
#     string="args_valid_or_read myVar '^[0-9a-z]{3,3}$' \"SIA\""
#     reflect_nth_arg 4 $string ==> "SIA"
# @SEE_ALSO
reflect_nth_arg() {
	local index string word position

	if [[ -n "${ZSH_VERSION:-}" ]]; then
		# zsh's lexer splits shell-quoted words without executing their contents.
		# Keep this expansion in eval so Bash can still parse the source file.
		string="$*"
		local -a __bash_base_reflect_words
		eval '__bash_base_reflect_words=( "${(@Q)${(z)string}}" )' || return 1
		set -- "${__bash_base_reflect_words[@]}"
	else
		string="$(printf '%s\n' "$*" | string_replace_regex '(\\|\||\{|>|<|&)' '\\\1')"

		# Parse the same shell-like argument string as the historical implementation,
		# but use positional parameters instead of an indexed array so Bash/zsh array
		# index bases cannot change the result.
		eval "set -- ${string}"
	fi
	index="${1-}"
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Bash legacy indexing addressed the entire parsed list, including
		# the index argument at [0]; missing indexes printed a blank line.
		# Keep that behavior, including Bash's native negative indexes.
		local -a __bash_base_legacy_reflect_words
		__bash_base_legacy_reflect_words=("$@")
		echo "${__bash_base_legacy_reflect_words[$index]}"
		return 0
	fi
	shift || true

	if ! [[ "$index" =~ ^[0-9]+$ ]] || ((index < 1)); then
		return 1
	fi

	position=1
	for word in "$@"; do
		if ((position == index)); then
			printf '%s\n' "$word"
			return 0
		fi
		position=$((position + 1))
	done

	return 1
}

# @NAME
#     reflect_get_function_definition -- print the definition of the specified function in system
# @SYNOPSIS
#     reflect_get_function_definition functionName
# @DESCRIPTION
#     **functionName** the specified function name
# @EXAMPLES
#     reflect_get_function_definition confirm_to_continue
# @SEE_ALSO
#     reflect_function_names_of_file
reflect_get_function_definition() {
	local functionName="$1"
	typeset -f "$functionName"
}

# @NAME
#     reflect_function_names_of_file -- print the function names defined in a shell script file
# @SYNOPSIS
#     reflect_function_names_of_file shellScriptFile
# @DESCRIPTION
#     **shellScriptFile** the path of shell script file
# @EXAMPLES
#     reflect_function_names_of_file $0
#     reflect_function_names_of_file scripts/my_script.sh
# @SEE_ALSO
#     reflect_get_function_definition
reflect_function_names_of_file() {
	local shellScriptFile="$1"
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Existing Bash callers may rely on the original output spelling.
		grep -E '^[[:space:]]*(function)?[[:space:]]*[0-9A-Za-z_\-]+[[:space:]]*\(\)[[:space:]]*\{?' "$shellScriptFile" | cut -d'(' -f1 | sed -e 's/function//'
		return
	fi
	grep -E '^[[:space:]]*(function[[:space:]]+)?[0-9A-Za-z_-]+[[:space:]]*\(\)[[:space:]]*\{?' "$shellScriptFile" | sed -E -e 's/^[[:space:]]*function[[:space:]]+//' -e 's/[[:space:]]*\(\).*//' -e 's/[[:space:]]+$//'
}

# @NAME
#     reflect_function_definitions_of_file -- print the function definitions defined in a shell script file
# @SYNOPSIS
#     reflect_function_definitions_of_file shellScriptFile
# @DESCRIPTION
#     **shellScriptFile** the path of shell script file
# @EXAMPLES
#     reflect_function_definitions_of_file $0
#     reflect_function_definitions_of_file scripts/my_script.sh
# @SEE_ALSO
#     reflect_get_function_definition
reflect_function_definitions_of_file() {
	local shellScriptFile="$1"
	if [[ -n "${BASH_VERSION:-}" ]]; then
		sed -E -n '/^[[:space:]]*(function)?[[:space:]]*[0-9A-Za-z_\-]+[[:space:]]*\(\)[[:space:]]*\{?/,/^[[:space:]]*}/p' "$shellScriptFile"
		return
	fi
	sed -E -n '/^[[:space:]]*(function[[:space:]]+)?[0-9A-Za-z_-]+[[:space:]]*\(\)[[:space:]]*\{?/,/^[[:space:]]*}/p' "$shellScriptFile"
}

# @NAME
#     reflect_search_function -- search usable function by name pattern
# @SYNOPSIS
#     reflect_search_function functionNamePattern
# @DESCRIPTION
#     **functionNamePattern** the string of function name regular expression pattern
# @EXAMPLES
#     reflect_search_function args
#     reflect_search_function '^args_.*'
# @SEE_ALSO
#     reflect_search_variable
reflect_search_function() {
	local functionNamePattern="$1"

	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Exact Bash legacy extraction/output (no new sorting or dedupe).
		typeset -f | grep -E '\s+\(\)\s+' | sed -E 's/[(){ ]//g' | grep -Ei "$functionNamePattern"
	elif [[ -n "${ZSH_VERSION:-}" ]]; then
		# Hide zsh-only parameter-expansion flags inside eval so the file still
		# parses in Bash.
		eval 'printf "%s\\n" "${(k)functions[@]}"' | LC_ALL=C sort -u | grep -Ei "$functionNamePattern"
	fi
}

# @NAME
#     reflect_search_variable -- search usable variable by name pattern
# @SYNOPSIS
#     reflect_search_variable variableNamePattern
# @DESCRIPTION
#     **variableNamePattern** the string of variable name regular expression pattern
# @EXAMPLES
#     reflect_search_variable COLOR
#     reflect_search_variable '^COLOR'
# @SEE_ALSO
#     reflect_search_function
reflect_search_variable() {
	local variableNamePattern="$1"

	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Enumerate Bash variables directly. Parsing typeset -p using \s/\w
		# depends on grep extensions unavailable on some macOS versions.
		compgen -A variable | grep -Ei "$variableNamePattern"
	elif [[ -n "${ZSH_VERSION:-}" ]]; then
		eval 'printf "%s\\n" "${(k)parameters[@]}"' | LC_ALL=C sort -u | grep -Ei "$variableNamePattern"
	fi
}
