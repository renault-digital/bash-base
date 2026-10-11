#!/usr/bin/env bash

source src/constant.sh

if [[ -n "${ZSH_VERSION:-}" ]]; then
	# zsh may temporarily replace $0 with the sourced filename when
	# FUNCTION_ARGZERO is enabled. ZSH_ARGZERO always keeps the invocation name.
	_bash_base_argzero="${ZSH_ARGZERO:-$0}"
else
	_bash_base_argzero="$0"
fi
THIS_SCRIPT_PATH="$_bash_base_argzero"               # script source path for args_valid_* lookup
THIS_SCRIPT_NAME="$(basename "$_bash_base_argzero")" # the main script name
unset _bash_base_argzero

SHORT_DESC="${THIS_SCRIPT_NAME%%.*}"
SHORT_DESC="${SHORT_DESC/[\-_]/ }" # redefine it to show your script short description in the 'NAME' field of generated -h response
USAGE=''                           # redefine it in your script only if the generated -h response is not good for you

# @NAME
#     args_parse -- parse the script argument values to positional variable names, process firstly the optional param help(-h) / quiet(-q) if existed
# @SYNOPSIS
#     args_parse $# "$@" positionalVarName...
# @DESCRIPTION
#     **positionalVarName...** some new variable names to catch the positional argument values
# @EXAMPLES
#     args_parse $# "$@" newVar1 newVar2 newVar3
# @SEE_ALSO
args_parse() {
	local nbArgValues nbPositionalVarNames option OPTARG OPTIND nbPositionalArgValues
	local showUsage=false
	local element validCommand description defaultUsage
	local strPositionalVarNames="" strPositionalValuesExamples=""
	local -a positionalArgValues positionalVarNames
	# Bash legacy contract: prompt, possibleValues, i, descriptions and
	# onlyPositionalVarNames were caller-visible, not function-local.

	nbArgValues=$1
	shift 1
	nbPositionalVarNames=$(($# - nbArgValues))

	while getopts ":qh" option; do
		case ${option} in
		q)
			modeQuiet=true
			;;
		h)
			showUsage=true
			;;
		\?)
			print_error "invalid option: -$OPTARG" >&2
			showUsage=true
			;;
		esac
	done
	shift $((OPTIND - 1))

	nbPositionalArgValues=$((nbArgValues - OPTIND + 1))
	positionalArgValues=()
	# Split positional values from destination names without a new local
	# counter; the historical Bash `i` global is handled below.
	while (($# > nbPositionalVarNames)); do
		positionalArgValues+=("$1")
		shift
	done
	positionalVarNames=("$@")

	onlyPositionalVarNames=()
	descriptions=''

	# Pair values with variable names without relying on Bash's 0-based array
	# indexes (zsh uses a different default array index base).
	set -- "${positionalArgValues[@]}"
	for element in "${positionalVarNames[@]}"; do
		# Do not introduce a local value variable: callers may legally name
		# their destination positionalValue (or prompt).  Save it only in $1.

		# zsh FUNCTION_ARGZERO may change $0 to the current function name.
		# Only scan a caller script when there is an actual script file.
		validCommand=''
		if [[ -f "${THIS_SCRIPT_PATH:-}" ]]; then
			validCommand="$(
				grep -E "^[[:space:]]*args_valid.*[[:space:]]+${element}[[:space:]]+" "$THIS_SCRIPT_PATH" | head -1 |
					awk -F "'" -v OFS="'" '{
                    for (i=2; i<=NF; i+=2) {
                        gsub(/ /, "_SPACE_", $i);
                        gsub(/\$/, "_DOLLAR_", $i);
                        gsub(/\(/, "_PARENTHESES_LEFT_", $i);
                        gsub(/\)/, "_PARENTHESES_RIGHT_", $i);
                    }
                    print
                }' |
					sed -e "s/\'//g"
			)"
		fi

		if [[ -z $validCommand ]]; then
			eval "${element}=\"\${1-}\""
			onlyPositionalVarNames+=("${element}")
			description="a valid value for ${element}"
		else
			if [[ "$validCommand" == *args_valid_or_select_pipe* ]]; then
				eval "${element}=\"\${1-}\""
				onlyPositionalVarNames+=("${element}")
				prompt="$(reflect_nth_arg 4 "$validCommand")"
				possibleValues=", possible values: $(reflect_nth_arg 3 "$validCommand")"
			elif [[ "$validCommand" == *args_valid_or_select_args* ]]; then
				eval "${element}=\"\${1-}\""
				onlyPositionalVarNames+=("${element}")
				prompt="$(reflect_nth_arg 3 "$validCommand")"
				possibleValues=", you can select one using wizard if you do not know which value is valid"
			elif [[ "$validCommand" == *args_valid_or_select* ]]; then
				eval "${element}=\"\${1-}\""
				onlyPositionalVarNames+=("${element}")
				prompt="$(reflect_nth_arg 4 "$validCommand")"
				possibleValues=", you can select one using wizard if you do not know which value is valid"
			elif [[ "$validCommand" == *args_valid_or_read* ]]; then
				eval "${element}=\"\${1-}\""
				onlyPositionalVarNames+=("${element}")
				prompt="$(reflect_nth_arg 4 "$validCommand")"
				if [[ -n $(reflect_nth_arg 5 "$validCommand") ]]; then
					prompt="${prompt}, proposed value: $(reflect_nth_arg 5 "$validCommand")"
				fi
				possibleValues=""
			elif [[ "$validCommand" == *args_valid_or_default* ]]; then
				prompt="optional, $(reflect_nth_arg 4 "$validCommand"). should be set like ${element}=value before ${THIS_SCRIPT_NAME} or export to OS environment"
				if [[ -n $(reflect_nth_arg 5 "$validCommand") ]]; then
					prompt="${prompt}. if absent, fallback to: $(reflect_nth_arg 5 "$validCommand")"
				else
					prompt="${prompt}, empty if absent"
				fi
				possibleValues=""
			fi

			prompt="$(
				printf '%s\n' "${prompt}" |
					string_replace "_SPACE_" " " |
					string_replace "_DOLLAR_" "$" |
					string_replace "_PARENTHESES_LEFT_" "(" |
					string_replace "_PARENTHESES_RIGHT_" ")"
			)"

			description="${prompt}${possibleValues}"
		fi
		descriptions+="$(printf "\n    %-20s%s" "${element} " "${description}")"
		if (($# > 0)); then
			shift
		fi
	done
	if [[ -n "${BASH_VERSION:-}" && $nbPositionalVarNames -gt 0 ]]; then
		# The original Bash implementation used a caller-visible `i` as
		# a loop counter over output names. Respect a destination named i.
		if ! array_in i "${positionalVarNames[@]}"; then
			i=$((nbPositionalVarNames - 1))
		fi
	fi

	if [ ${#onlyPositionalVarNames[@]} -gt 0 ]; then
		strPositionalVarNames=" $(array_join ' ' onlyPositionalVarNames)"
		strPositionalValuesExamples=" \"$(array_join 'Value" "' onlyPositionalVarNames)Value\""
	fi

	declare_heredoc defaultUsage <<EOF
${COLOR_BOLD_YELLOW}NAME${COLOR_END}
    ${THIS_SCRIPT_NAME} -- ${SHORT_DESC}

${COLOR_BOLD_YELLOW}SYNOPSIS${COLOR_END}
    [optionalVariable=value ...] ./${THIS_SCRIPT_NAME} [-qh]${strPositionalVarNames}

${COLOR_BOLD_YELLOW}DESCRIPTION${COLOR_END}
    [-h]                help, print the usage
    [-q]                optional, Run quietly, no confirmation
${descriptions}

${COLOR_BOLD_YELLOW}EXAMPLES${COLOR_END}
    help, print the usage:
        ./${THIS_SCRIPT_NAME} -h

    run with all params, if run in quiet mode with -q, be sure all the params are valid:
        ./${THIS_SCRIPT_NAME} [-q]${strPositionalValuesExamples}

    run using wizard, input value for params step by step:
        ./${THIS_SCRIPT_NAME}

    run with optional variables, example:
        myOpt1=myValue1 myOpt2=myValue2 ./${THIS_SCRIPT_NAME}

    or you can run with some params, and input value for other params using wizard.
EOF

	if [[ "$showUsage" == true ]]; then
		printf '%b\n' "${USAGE:-$defaultUsage}"
		exit 0
	fi
}

# @NAME
#     args_valid_or_select -- test whether the value contains by the array, if not contained, require to select a new one from array and assign it to the value variable name
# @SYNOPSIS
#     args_valid_or_select valueVarName arrayVarName prompt
# @DESCRIPTION
#     **valueVarName** the variable name of the value to valid and the new value assign to,
#     **arrayVarName** the variable name of array
#     **prompt** the prompt message to show when requiring to select a new one from array
# @EXAMPLES
#     arr=("a" "b" "c" "ab" "f" "g")
#     appName="abc"
#     args_valid_or_select appName arr "Which app"
#     varEmpty=""
#     args_valid_or_select varEmpty arr "Which app"
# @SEE_ALSO
#     args_valid_or_select_pipe, args_valid_or_read, args_valid_or_default
args_valid_or_select() {
	local valueVarName validValuesVarName prompt value PS3
	local -a validValues

	valueVarName="${1}"
	validValuesVarName="$2"
	prompt="${3}"
	eval 'value="${'"$valueVarName"'-}"'
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Preserve Bash's historical echo/word-splitting normalization, without
		# reparsing the value with eval (which would execute input as code).
		# shellcheck disable=SC2086,SC2116
		value="$(echo $value)"
	fi
	eval "validValues=( \"\${${validValuesVarName}[@]}\" )"

	while ! array_contains "${validValuesVarName}" "${value}"; do
		printf '\n%s ?\n' "$prompt"
		[[ -n "${value}" ]] && print_error "the input '${value}' is not valid."

		PS3="choose one by ${COLOR_BOLD_YELLOW}number${COLOR_END} [1|2|...] ? "
		select value in "${validValues[@]}"; do
			break
		done
	done

	eval "${valueVarName}=\"\$value\""
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# shellcheck disable=SC2086,SC2116
		value="$(echo $value)"
	fi
	printf "Selected value: ${COLOR_BLUE}'%s'${COLOR_END}\n" "$value"
}

# @NAME
#     args_valid_or_select_pipe -- test whether the value contains by the array, if not contained, require to select a new one from array and assign it to the value variable name
# @SYNOPSIS
#     args_valid_or_select_pipe valueVarName strValidValues prompt
# @DESCRIPTION
#     **valueVarName** the variable name of the value to valid and the new value assign to,
#     **strValidValues** values joined by pipe '|'
#     **prompt** the prompt message to show when requiring to select a new one from array
# @EXAMPLES
#     sel="abc"
#     args_valid_or_select_pipe sel "a|ab|d" "which value"
# @SEE_ALSO
#     args_valid_or_select, args_valid_or_select_args, args_valid_or_read, args_valid_or_default
args_valid_or_select_pipe() {
	local valueVarName validValues prompt
	local -a newArray
	valueVarName="${1}"
	validValues="${2}"
	prompt="${3}"

	string_split_to_array '|' newArray "$validValues"
	args_valid_or_select "${valueVarName}" newArray "$prompt"
}

# @NAME
#     args_valid_or_select_args -- test whether the value contains by the array, if not contained, require to select a new one from array and assign it to the value variable name
# @SYNOPSIS
#     args_valid_or_select_args valueVarName prompt arrayElement1 arrayElement2 ...
# @DESCRIPTION
#     **valueVarName** the variable name of the value to valid and the new value assign to,
#     **prompt** the prompt message to show when requiring to select a new one from array
#     **arrayElement1...** the elements of array, quote the element which contains space
# @EXAMPLES
#     sel="abc"
#     args_valid_or_select_args sel "which value" "a" "ab" "d"
# @SEE_ALSO
#     args_valid_or_select, args_valid_or_select_pipe, args_valid_or_read, args_valid_or_default
args_valid_or_select_args() {
	local valueVarName value prompt PS3
	valueVarName="${1}"
	eval 'value="${'"$valueVarName"'-}"'
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Preserve Bash's historical echo/word-splitting normalization, without
		# reparsing the value with eval (which would execute input as code).
		# shellcheck disable=SC2086,SC2116
		value="$(echo $value)"
	fi
	prompt="${2}"
	shift 2

	while ! array_in "${value}" "$@"; do
		printf '\n%s ?\n' "$prompt"
		[[ -n "${value}" ]] && print_error "the input '${value}' is not valid."

		PS3="choose one by ${COLOR_BOLD_YELLOW}number${COLOR_END} [1|2|...] ? "
		select value in "$@"; do
			break
		done
	done

	eval "${valueVarName}=\"\$value\""
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# shellcheck disable=SC2086,SC2116
		value="$(echo $value)"
	fi
	printf "Selected value: ${COLOR_BLUE}'%s'${COLOR_END}\n" "$value"
}

# @NAME
#     args_valid_or_read -- test whether the value matched the valid regular expression, if not matched, require input a new one and assign it to the value variable name
# @SYNOPSIS
#     args_valid_or_read valueVarName strRegExp prompt [proposedValue]
# @DESCRIPTION
#     **valueVarName** the variable name of the value to valid and the new value assign to,
#     **strRegExp** a string of regular expression to be used for validation
#     **prompt** the prompt message to show when requiring to read a new one from stdin
#     **[proposedValue]** the proposed spare value to show for user, or to used when quite mode
# @EXAMPLES
#     args_valid_or_read destProjectSIA '^[0-9a-z]{3,3}$' "SIA (lowercase, 3 chars)"
#     args_valid_or_read destProjectIRN '^[0-9]{5,5}$' "IRN (only the 5 digits)"
#     args_valid_or_read destRootPackage '^.+$' "Destination root package" "${defaultDestRootPackage}"
# @SEE_ALSO
#     args_valid_or_select, args_valid_or_select_args, args_valid_or_select_pipe, args_valid_or_default
args_valid_or_read() {
	local valueVarName="$1"
	local regExp="${2}"
	local prompt="${3}"
	local proposedValue="${4-}"
	local value

	eval 'value="${'"$valueVarName"'-}"'
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Preserve Bash's historical echo/word-splitting normalization, without
		# reparsing the value with eval (which would execute input as code).
		# shellcheck disable=SC2086,SC2116
		value="$(echo $value)"
	fi

	if [[ -n "${proposedValue}" ]]; then
		prompt="${prompt} [${proposedValue}]"
		if [[ -z "${value}" && "${modeQuiet:-false}" == true ]]; then
			value="${proposedValue}"
		fi
	fi

	while ! [[ $value =~ $regExp ]]; do
		[[ -n "${value}" ]] && print_error "the input '${value}' is not valid, please input again."
		if [[ -t 0 ]]; then
			printf '%s: ' "$prompt" >&2
		fi
		read -r value || value=""
		if [[ -z "${value}" ]]; then
			value="${proposedValue}"
		fi
	done

	eval "${valueVarName}=\"\$value\""
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Legacy Bash printed via `eval echo $name`: collapse display-only
		# whitespace, but leave the actual assigned value unchanged.
		# shellcheck disable=SC2086,SC2116
		printf "Inputted value: ${COLOR_BLUE}'%s'${COLOR_END}\n" "$(echo $value)"
	else
		printf "Inputted value: ${COLOR_BLUE}'%s'${COLOR_END}\n" "$value"
	fi
}

# @NAME
#     args_valid_or_default -- description of the optional params, value will fallback to empty or default if it no match the regular expression.
# @SYNOPSIS
#     args_valid_or_default valueVarName strRegExp prompt [defaultValue]
# @DESCRIPTION
#     the optional params should be set in OS environment like 'export optional_variable=value && ./my_script.sh',
#     or be placed before the $0 like 'optionalVariable1=value1 optionalVariable2=value2 ./my_script.sh'.
#
#     **valueVarName** the variable name of the value to valid and the new value assign to,
#     **strRegExp** a string of regular expression to be used for validation
#     **prompt** the description of the argument in generated help usage
#     **[defaultValue]** optional, the default value to fallback on
# @EXAMPLES
#     args_valid_or_default destProjectSIA '^[0-9a-z]{3,3}$' "SIA (lowercase, 3 chars)"
#     args_valid_or_default destProjectIRN '^[0-9]{5,5}$' "IRN (only the 5 digits)"
#     args_valid_or_default destRootPackage '^.+$' "Destination root package" "${defaultDestRootPackage}"
# @SEE_ALSO
#     args_valid_or_select, args_valid_or_select_args, args_valid_or_select_pipe, args_valid_or_read
args_valid_or_default() {
	local valueVarName="$1"
	local regExp="${2}"
	local prompt="${3}"
	local defaultValue="${4-}"
	local value

	eval 'value="${'"$valueVarName"'-}"'
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Preserve Bash's historical echo/word-splitting normalization, without
		# reparsing the value with eval (which would execute input as code).
		# shellcheck disable=SC2086,SC2116
		value="$(echo $value)"
	fi

	if [[ -z "${value}" || ! $value =~ $regExp ]]; then
		prompt="for param ${valueVarName}:"
		[[ -n "${value}" ]] && prompt+=" the input '${value}' is not valid" || prompt+=" no input"
		[[ -n "${defaultValue}" ]] && prompt+=", fallback to default value '${defaultValue}'" || prompt+=", fallback to empty"
		print_warn "${prompt}"
		value="${defaultValue}"
	fi

	eval "${valueVarName}=\"\$value\""
	if [[ -n "${BASH_VERSION:-}" ]]; then
		# Legacy Bash printed via `eval echo $name`: collapse display-only
		# whitespace, but leave the actual assigned value unchanged.
		# shellcheck disable=SC2086,SC2116
		printf "Inputted value: ${COLOR_BLUE}'%s'${COLOR_END}\n" "$(echo $value)"
	else
		printf "Inputted value: ${COLOR_BLUE}'%s'${COLOR_END}\n" "$value"
	fi
}
