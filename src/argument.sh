#!/usr/bin/env bash

source src/constant.sh

THIS_SCRIPT_NAME="$(basename "$0")"        # the main script name
SHORT_DESC='a bash script using bash-base' # redefine it to show your script short description in the 'NAME' field of generated -h response
USAGE=''                                   # redefine it in your script only if the generated -h response is not good for you

# @NAME
#     args_parse -- parse the script argument values to positional variable names, process firstly the optional param help(-h) / quiet(-q) if existed
# @SYNOPSIS
#     args_parse $# "$@" positionalVarName...
# @DESCRIPTION
#     **positionalVarName...** some new variable names to catch the positional argument values
# @EXAMPLES
#     args_parse $# "$@" newVar1 newVar2 newVar3
# @SEE_ALSO
function args_parse() {
	local nbArgValues nbPositionalVarNames option showUsage OPTARG OPTIND nbPositionalArgValues positionalArgValues positionalVarNames
	local element validCommand description defaultUsage

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
			;;
		esac
	done
	shift $((OPTIND - 1))

	nbPositionalArgValues=$((nbArgValues - OPTIND + 1))
	positionalArgValues=("${@:1:nbPositionalArgValues}")
	positionalVarNames=("${@:nbPositionalArgValues+1:nbPositionalVarNames}")
	for i in $(seq 0 $((nbPositionalVarNames - 1))); do
		eval "${positionalVarNames[i]}='${positionalArgValues[i]}'"
	done

	# Generate default usage response for -h
	descriptions=''
	for element in "${positionalVarNames[@]}"; do
		validCommand="$(
			grep -E "^\s*args_valid.*\s+${element}\s+" "$0" |
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

		if [[ -z ${validCommand} ]]; then
			description="a valid value for ${element}"
		else
			description="$(
				reflect_nth_arg 4 "${validCommand}" |
					string_replace "_SPACE_" " " |
					string_replace "_DOLLAR_" "$" |
					string_replace "_PARENTHESES_LEFT_" "(" |
					string_replace "_PARENTHESES_RIGHT_" ")"
			)"

			if [[ "${validCommand}" =~ 'args_valid_or_select_pipe' ]]; then
				description="${description}, possible values: $(reflect_nth_arg 3 "$validCommand")"
			elif [[ "${validCommand}" =~ 'args_valid_or_select' ]]; then
				description="${description}, you can select one using wizard if you do not know which value is valid"
			fi
		fi

		descriptions+="$(printf "\n    %-20s%s" "${element} " "${description}")"
	done

	declare_heredoc defaultUsage <<-EOF
		${COLOR_BOLD_YELLOW}NAME${COLOR_END}
		    ${THIS_SCRIPT_NAME} -- ${SHORT_DESC}

		${COLOR_BOLD_YELLOW}SYNOPSIS${COLOR_END}
		    ./${THIS_SCRIPT_NAME} [-qh] $(array_join ' ' positionalVarNames)

		${COLOR_BOLD_YELLOW}DESCRIPTION${COLOR_END}
		    [-h]                help, print the usage
		    [-q]                optional, Run quietly, no confirmation
		${descriptions}

		${COLOR_BOLD_YELLOW}EXAMPLES${COLOR_END}
		    help, print the usage:
		        ./${THIS_SCRIPT_NAME} -h

		    run with all params, if run in quiet mode with -q, be sure all the params are valid:
		        ./${THIS_SCRIPT_NAME} [-q] "$(array_join 'Value" "' positionalVarNames)Value"

		    run using wizard, input value for params step by step:
		        ./${THIS_SCRIPT_NAME}

		    or you can run with some params, and input value for other params using wizard.
	EOF

	if [ "$showUsage" == true ]; then
		echo -e "${USAGE:-$defaultUsage}"
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
#     args_valid_or_select_pipe, args_valid_or_read
function args_valid_or_select() {
	local valueVarName validValuesVarName prompt value validValues PS3
	valueVarName="${1}"
	validValuesVarName=$2
	validValues="$2[@]"
	prompt="${3}"

	value=$(eval eval "echo '$'${valueVarName}")

	while ! array_contains "${validValuesVarName}" "${value}"; do
		echo -e "\n${prompt} ?"
		[[ -n "${value}" ]] && print_error "the input '${value}' is not valid."

		PS3="choose one by ${COLOR_BOLD_YELLOW}number${COLOR_END} [1|2|...] ? "
		select value in "${!validValues}"; do
			break
		done
	done
	eval "${valueVarName}='${value}'"
	printf "Selected value: ${COLOR_BLUE}'%s'${COLOR_END}\n" "$(eval echo '$'"${valueVarName}")"
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
#     args_valid_or_select, args_valid_or_read
function args_valid_or_select_pipe() {
	local valueVarName validValues prompt newArray
	valueVarName="${1}"
	validValues="${2}"
	prompt="${3}"

	string_split_to_array '|' newArray "$validValues"
	args_valid_or_select "${valueVarName}" newArray "$prompt"
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
#     args_valid_or_select, args_valid_or_select_pipe
function args_valid_or_read() {
	local value regExp prompt proposedValue
	value=$(eval eval "echo '$'$1")
	regExp=${2}
	prompt="${3}"
	proposedValue="${4}"

	if [[ -n "${proposedValue}" ]]; then
		prompt="${prompt} [${proposedValue}]"
		if [[ -z "${value}" && "${modeQuiet}" == true ]]; then
			value="${proposedValue}"
		fi
	fi
	while ! [[ ${value} =~ ${regExp} ]]; do
		[[ -n "${value}" ]] && print_error "the input '${value}' is not valid, please input again."
		read -r -p "${prompt}: " value
		if [[ -z "${value}" ]]; then
			value="${proposedValue}"
		fi
	done
	eval "${1}='${value}'"
	printf "Inputted value: ${COLOR_BLUE}'%s'${COLOR_END}\n" "$(eval echo '$'"${1}")"
}
