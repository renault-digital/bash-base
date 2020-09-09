#!/usr/bin/env bash

source src/tool.sh

# @NAME
#     string_trim -- remove the white chars from prefix and suffix
# @SYNOPSIS
#     string_trim [string]
# @DESCRIPTION
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_trim " as fd "
#     string_trim < logfile
#     echo " add " | string_trim
# @SEE_ALSO
function string_trim() {
	local string="${1-$(cat)}"
	echo "${string}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' #trim ' '
}

# @NAME
#     string_repeat -- make a string by repeat n times of a token string
# @SYNOPSIS
#     string_repeat string [nbTimes]
# @DESCRIPTION
#     **string** the string to be repeated
#     **[nbTimes]** the number of times, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_repeat 'abc' 5
#     echo 5 | string_repeat 'abc'
# @SEE_ALSO
function string_repeat() {
	local string="$1"
	local nbTimes=${2-$(cat)}
	printf "${string}%.0s" $(seq 1 "$nbTimes")
}

# @NAME
#     string_length -- return the string length
# @SYNOPSIS
#     string_length [string]
# @DESCRIPTION
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_length " as fd "
#     string_length < logfile
#     echo " add " | string_length
# @SEE_ALSO
function string_length() {
	local string index
	string="${1-$(cat)}"

	index=$(string_index_first $'\n' "${string}")
	[[ "${index}" -ge 0 ]] && expr "${string}" : '.*' || echo "${#string}"
}

# @NAME
#     string_is_empty -- exit success code 0 if the string is empty
# @SYNOPSIS
#     string_is_empty [string]
# @DESCRIPTION
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_is_empty " as fd "
#     string_is_empty < logfile
#     echo " add " | string_is_empty
# @SEE_ALSO
#     string_length
function string_is_empty() {
	local string="${1-$(cat)}"

	[[ $(string_length "$string") -eq 0 ]]
}

# @NAME
#     string_revert -- revert the characters of a string
# @SYNOPSIS
#     string_revert [string]
# @DESCRIPTION
#     **[string]** the string to be reverted, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_revert 'aBc'
#     echo 'aBc' | string_revert
# @SEE_ALSO
function string_revert() {
	local string="${1-$(cat)}"
	echo "${string}" | rev
}

# @NAME
#     string_upper -- convert all characters to upper case
# @SYNOPSIS
#     string_upper [string]
# @DESCRIPTION
#     **[string]** the string to be converted, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_upper 'abc'
#     echo 'abc' | string_upper
# @SEE_ALSO
#     string_upper_first, string_lower
function string_upper() {
	local string=${1-$(cat)}
	echo "${string^^}"
}

# @NAME
#     string_lower -- convert all characters to lower case
# @SYNOPSIS
#     string_lower [string]
# @DESCRIPTION
#     **[string]** the string to be converted, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_lower 'aBc'
#     echo 'aBc' | string_lower
# @SEE_ALSO
#     string_upper, string_upper_first
function string_lower() {
	local string=${1-$(cat)}
	echo "${string,,}"
}

# @NAME
#     string_upper_first -- convert the first characters to upper case, and the others to lower case
# @SYNOPSIS
#     string_upper_first [string]
# @DESCRIPTION
#     **[string]** the string to be converted, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_upper_first 'aBc'
#     echo 'aBc' | string_upper_first
# @SEE_ALSO
#     string_lower, string_upper
function string_upper_first() {
	local string=${1-$(cat)}
	local lower="${string,,}"
	echo "${lower^}"
}

# @NAME
#     string_sub -- extract a part of string and return
# @SYNOPSIS
#     string_sub startIndex subStringLength [string]
# @DESCRIPTION
#     **startIndex** the index of first character in string, 0 based, may negative
#     **subStringLength** the length of sub string, 0 based, may negative
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_sub -5 -1 " as fd "
#     string_sub 3 5 < temp_file.txt
#     echo ' as fd ' | string_sub 2 4
# @SEE_ALSO
function string_sub() {
	local startIndex=$1
	local subStringLength=$2
	local string="${3-$(cat)}"
	echo "${string:$startIndex:$subStringLength}"
}

# @NAME
#     string_match -- test if the string match the regular expression
# @SYNOPSIS
#     string_match regExp [string]
# @DESCRIPTION
#     **regExp** the regular expression
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_match 'name;+' "name;name;"
# @SEE_ALSO
#     string_index_first
function string_match() {
	local value regExp
	regExp=${1}
	string="${2-$(cat)}"

	[[ ${string} =~ ${regExp} ]]
}

# @NAME
#     escape_sed -- escape preserved char of regex, normally for preprocessing of sed token.
# @SYNOPSIS
#     escape_sed string
# @DESCRIPTION
#     **string** the string to process
# @EXAMPLES
#     escape_sed 'a$'
# @SEE_ALSO
#     string_replace
function escape_sed() {
	echo "${1}" | sed -e 's/\//\\\//g' -e 's/\&/\\\&/g' -e 's/\./\\\./g' -e 's/\^/\\\^/g' -e 's/\[/\\\[/g' -e 's/\$/\\\$/g'
}
export -f escape_sed >/dev/null

# @NAME
#     string_replace -- replace literally the token string to new string, not support regular expression
# @SYNOPSIS
#     string_replace tokenString newString [string]
# @DESCRIPTION
#     **tokenString** the string to search, the preserved character of regular expression will be escaped
#     **newString** the new value of replacing to, the preserved character of regular expression will be escaped
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_replace 'a' 'b' 'aaa'   ==> 'bbb'
#     string_replace '$' 'b' 'a$a'   ==> 'aba'
#     string_replace '\*' 'b' 'a*a'  ==> 'aba'
# @SEE_ALSO
#     escape_sed, string_replace_regex
function string_replace() {
	local tokenString newString
	tokenString=$(escape_sed "${1}")
	newString=$(escape_sed "${2}")
	echo "${3-$(cat)}" | sed -e "s/${tokenString}/${newString}/g"
}

# @NAME
#     string_replace_regex -- replace the token string to new string, support regular expression
# @SYNOPSIS
#     string_replace_regex tokenString newString [string]
# @DESCRIPTION
#     **tokenString** the string to search, support regular expression and its modern extension
#     **newString** the new value of replacing to, support [back-references](https://www.gnu.org/software/sed/manual/html_node/Back_002dreferences-and-Subexpressions.html)
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_replace_regex 'a*' 'b' 'a*a' ==> 'b*b'
#     string_replace_regex 'a*' 'b' "aaa" ==> 'b'
#     string_replace_regex '*' 'b' 'a*a'  ==> 'aba'
# @SEE_ALSO
#     string_replace
function string_replace_regex() {
	echo "${3-$(cat)}" | sed -E -e "s/$1/$2/g"
}

# @NAME
#     string_index_first -- return the positive index of first place of token in string, -1 if not existed
# @SYNOPSIS
#     string_index_first tokenString [string]
# @DESCRIPTION
#     **tokenString** the string to search
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_index_first "s f" " as fd "
#     string_index_first "token" < logfile
#     echo " add " | string_index_first "token"
# @SEE_ALSO
#     string_before_first, string_after_first
function string_index_first() {
	local tokenString=$1
	local string="${2-$(cat)}"
	local prefix="${string%%${tokenString}*}"
	[ "${string}" == "${prefix}" ] && echo -1 || echo ${#prefix}
}

# @NAME
#     string_before_first -- find the first index of token in string, and return the sub string before it.
# @SYNOPSIS
#     string_before_first tokenString [string]
# @DESCRIPTION
#     **tokenString** the string to search
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_before_first "s f" " as fd "
#     string_before_first "str" < logfile
#     echo " add " | string_before_first "dd"
# @SEE_ALSO
#     string_index_first, string_after_first
function string_before_first() {
	local tokenString=$1
	local string="${2-$(cat)}"
	echo "${string%%${tokenString}*}" # Remove the first - and everything following it
}

# @NAME
#     string_after_first -- find the first index of token in string, and return the sub string after it.
# @SYNOPSIS
#     string_after_first tokenString [string]
# @DESCRIPTION
#     **tokenString** the string to search
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     string_after_first "s f" " as fd "
#     string_after_first "str" < logfile
#     echo " add " | string_after_first "dd"
# @SEE_ALSO
#     string_index_first, string_before_first
function string_after_first() {
	local tokenString=$1
	local string="${2-$(cat)}"
	echo "${string#*${tokenString}}" # Remove everything up to and including first -
}

# @NAME
#     string_split_to_array -- split a string to array by a delimiter character, then assign the array to a new variable name
# @SYNOPSIS
#     string_split_to_array tokenString [newArrayVarName] [string]
# @DESCRIPTION
#     **tokenString** the delimiter string
#     **[newArrayVarName]** optional, the variable name of result array, if absent, the mapped array will be joined by newline and printed to stdout
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     str="a|b|c"
#     string_split_to_array '|' newArray "$str"
#
#     branchesToSelectString=$(git branch -r --list  'origin/*')
#     string_split_to_array $'\n' branchesToSelectArray "${branchesToSelectString}"
# @SEE_ALSO
#     array_join, array_describe, array_from_describe, string_pick_to_array
function string_split_to_array() {
	local tokenString="$1"
	local newArrayVarName="$2"
	local string="${3-$(cat)}"

	local tmp=()
	while [[ "$(string_index_first "${tokenString}" "${string}")" -ge 0 ]]; do
		tmp+=("$(string_before_first "${tokenString}" "${string}")")
		string="$(string_after_first "${tokenString}" "${string}")"
	done

	if [[ -n "${string}" ]]; then
		tmp+=("${string}")
	fi

	if [[ -n "${newArrayVarName}" ]]; then
		string="\${tmp[@]}"
		command="${newArrayVarName}=(\"${string}\")"
		eval "${command}"
	else
		array_join $'\n' tmp
	fi
}

# @NAME
#     string_pick_to_array -- take value using start token and end token from a string to array, then assign the array to a new variable name
# @SYNOPSIS
#     string_pick_to_array startTokenString endTokenString [newArrayVarName] [string]
# @DESCRIPTION
#     **startTokenString** the start token string
#     **endTokenString** the end token string
#     **[newArrayVarName]** optional, the variable name of result array, if absent, the mapped array will be joined by newline and printed to stdout
#     **[string]** the string to process, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     str="[{age:12},{age:15},{age:16}]"
#     string_pick_to_array '{age:' '}' newArray "$str"
# @SEE_ALSO
#     array_join, array_describe, array_from_describe, string_split_to_array
function string_pick_to_array() {
	local startTokenString="$1"
	local endTokenString="$2"
	local newArrayVarName="$3"
	local string="${4-$(cat)}"

	local tmp=()
	while [[ "$(string_index_first "${startTokenString}" "${string}")" -ge 0 ]]; do
		string="$(string_after_first "${startTokenString}" "${string}")"
		if [[ "$(string_index_first "${endTokenString}" "${string}")" -ge 0 ]]; then
			tmp+=("$(string_before_first "${endTokenString}" "${string}")")
			string="$(string_after_first "${endTokenString}" "${string}")"
		fi
	done

	if [[ -n "${newArrayVarName}" ]]; then
		string="\${tmp[@]}"
		command="${newArrayVarName}=(\"${string}\")"
		eval "${command}"
	else
		array_join $'\n' tmp
	fi
}
