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
function reflect_nth_arg() {
	local index string args

	string="$(echo "$@" | string_replace_regex '(\\|\||\{|>|<|&)' '\\\1')"
	args=()
	eval 'for word in '"${string}"'; do args+=("$word"); done'

	index="${args[0]}"
	echo "${args[$index]}"
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
function reflect_get_function_definition() {
	local functionName="$1"
	declare -f "$functionName"
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
function reflect_function_names_of_file() {
	local shellScriptFile="$1"
	grep -E '^[[:space:]]*(function)?[[:space:]]*[0-9A-Za-z_\-]+[[:space:]]*\(\)[[:space:]]*\{?' "${shellScriptFile}" | cut -d'(' -f1 | sed -e "s/function//"
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
function reflect_function_definitions_of_file() {
	local shellScriptFile="$1"
	sed -E -n '/^[[:space:]]*(function)?[[:space:]]*[0-9A-Za-z_\-]+[[:space:]]*\(\)[[:space:]]*\{?/,/^[[:space:]]*}/p' "${shellScriptFile}"
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
function reflect_search_function() {
	local functionNamePattern="$1"
	declare -f | grep -E '\s+\(\)\s+' | sed -E 's/[(){ ]//g' | grep -Ei "${functionNamePattern}"
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
function reflect_search_variable() {
	local variableNamePattern="$1"
	declare -p | grep -Eo '\s+\w+=' | sed -E 's/[= ]//g' | grep -Ei "${variableNamePattern}"
}
