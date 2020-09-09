#!/usr/bin/env bash

# @NAME
#     array_join -- join an array to string using delimiter string
# @SYNOPSIS
#     array_join delimiter arrayVarName
# @DESCRIPTION
#     **delimiter** the delimiter string
#     **arrayVarName** the variable name of the array to be processed
# @EXAMPLES
#     myArry=(" a " " b c ")
#     array_join '|' myArry ==> " a | b c "
# @SEE_ALSO
#     string_split_to_array, array_describe, array_from_describe
function array_join() {
	local delimiter="$1"
	local array="$2[@]"

	local element result delimiterLength
	for element in "${!array}"; do
		result="${result}${element}${delimiter}"
	done

	delimiterLength=$(string_length "${delimiter}")
	if string_is_empty "${result}"; then
		echo ''
	else
		string_sub 0 $((0 - delimiterLength)) "${result}"
	fi
}

# @NAME
#     array_describe -- convert the array to its string representation
# @SYNOPSIS
#     array_describe arrayVarName
# @DESCRIPTION
#     **arrayVarName** the variable name of the array to be processed
# @EXAMPLES
#     myArray=("a" "b")
#     array_describe myArray ==> ([0]='a' [1]='b')
# @SEE_ALSO
#     string_split_to_array, array_join, array_from_describe
function array_describe() {
	declare -p "$1" | string_after_first "=" | tr '"' "'"
}

# @NAME
#     array_from_describe -- restore the array from its string representation, then assign it to a variable name
# @SYNOPSIS
#     array_from_describe newArrayVarName [string]
# @DESCRIPTION
#     **newArrayVarName** the new variable name which the array will be assigned to
#     **[string]** the string of array describe, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     array_from_describe myNewArray "([0]='a' [1]='b')"
#     array_from_describe myNewArray < fileNameContentString
# @SEE_ALSO
#     string_split_to_array, array_join, array_describe
function array_from_describe() {
	local newArrayVarName="$1"
	local string="${2-$(cat)}"

	local command="${newArrayVarName}=${string}"
	eval "${command}"
}

# @NAME
#     array_contains -- exit success code 0 if array contains element, fail if not.
# @SYNOPSIS
#     array_contains arrayVarName [seekingElement]
# @DESCRIPTION
#     **arrayVarName** the variable name of array to test
#     **[seekingElement]** the element to search in array, if absent, it will be read from the standard input (CTRL+D to end)
# @EXAMPLES
#     arr=("a" "b" "c" "ab" "f" "g")
#     array_contains arr "ab"
#     echo "ab" | array_contains arr
# @SEE_ALSO
#     array_remove
function array_contains() {
	local array="$1[@]"
	local seeking="${2-$(cat)}"

	local exitCode element
	exitCode=1
	for element in "${!array}"; do
		if [[ ${element} == "${seeking}" ]]; then
			exitCode=0
			break
		fi
	done
	return $exitCode
}

# @NAME
#     array_sort -- sort the elements of array, save the result to original variable name
# @SYNOPSIS
#     array_sort arrayVarName
# @DESCRIPTION
#     **arrayVarName** the variable name of the array to be processed
# @EXAMPLES
#     myArray=('aa' 'bb' 'aa')
#     array_sort myArray ==> ([0]='aa' [1]='aa' [2]='bb')
# @SEE_ALSO
#     array_sort_distinct
function array_sort() {
	local arrayVarName="$1"
	local strSorted arrSorted

	strSorted="$(array_join $'\n' "${arrayVarName}" | sort)"
	string_split_to_array $'\n' arrSorted "${strSorted}"

	local string="\${arrSorted[@]}"
	local command="${arrayVarName}=(\"${string}\")"
	eval "${command}"
}

# @NAME
#     array_sort_distinct -- remove the duplicated elements of array, sort and save the result to original variable name
# @SYNOPSIS
#     array_sort_distinct arrayVarName
# @DESCRIPTION
#     **arrayVarName** the variable name of the array to be processed
# @EXAMPLES
#     myArray=('aa' 'bb' 'aa')
#     array_sort_distinct myArray ==> ([0]='aa' [1]='bb')
# @SEE_ALSO
#     array_sort
function array_sort_distinct() {
	local arrayVarName="$1"
	local strSorted arrSorted

	strSorted="$(array_join $'\n' "${arrayVarName}" | sort -u)"
	string_split_to_array $'\n' arrSorted "${strSorted}"

	local string="\${arrSorted[@]}"
	local command="${arrayVarName}=(\"${string}\")"
	eval "${command}"
}

# @NAME
#     array_length -- return the number of elements of array
# @SYNOPSIS
#     array_length arrayVarName
# @DESCRIPTION
#     **arrayVarName** the variable name of the array to be processed
# @EXAMPLES
#     myArray=('aa' 'bb' 'aa')
#     array_length myArray ==> 3
# @SEE_ALSO
function array_length() {
	local arrayVarName="$1"
	local string command tmp

	eval "string='$'{${arrayVarName}[@]}"
	command="tmp=(\"${string}\")"
	eval "${command}"

	echo "${#tmp[@]}"
}

# @NAME
#     array_reset_index -- reset the indexes of array to the sequence 0,1,2..., save the result to original variable name
# @SYNOPSIS
#     array_reset_index arrayVarName
# @DESCRIPTION
#     **arrayVarName** the variable name of the array to be processed
# @EXAMPLES
#     myArray=([2]='a' [5]='c' [11]='dd')
#     array_reset_index myArray ==> ([0]='a' [1]='c' [2]='dd')
# @SEE_ALSO
function array_reset_index() {
	local arrayVarName="$1"
	local string command tmp

	eval "string='$'{${arrayVarName}[@]}"
	command="tmp=(\"${string}\")"
	eval "${command}"

	string="\${tmp[@]}"
	command="${arrayVarName}=(\"${string}\")"
	eval "${command}"
}

# @NAME
#     array_equals -- test if the elements of 2 array are equal, ignore the array index
# @SYNOPSIS
#     array_equals arrayVarName1 arrayVarName2 [ignoreOrder] [ignoreDuplicated]
# @DESCRIPTION
#     **arrayVarName1** the variable name of an array
#     **arrayVarName2** the variable name of another array to compare with
#     **[ignoreOrder]** optional, a boolean value true/false, indicate whether ignore element order when compare, default true
#     **[ignoreDuplicated]** optional, a boolean value true/false, indicate whether ignore element duplicated when compare, default false
# @EXAMPLES
#     myArray1=('aa' [3]='bb' 'aa')
#     myArray2=('aa' 'aa' 'bb')
#     array_equals myArray1 myArray2 false && echo Y || echo N ==> N
#     array_equals myArray1 myArray2 true && echo Y || echo N ==> Y
# @SEE_ALSO
function array_equals() {
	local arrayVarName1="$1"
	local arrayVarName2="$2"
	local ignoreOrder=${3:-true}
	local ignoreDuplicated=${4:-false}

	local tmp1 tmp2
	array_clone "$arrayVarName1" tmp1
	array_clone "$arrayVarName2" tmp2

	if [ "${ignoreOrder}" = true ]; then
		if [ "${ignoreDuplicated}" = true ]; then
			array_sort_distinct tmp1
			array_sort_distinct tmp2
		else
			array_sort tmp1
			array_sort tmp2
		fi
	else
		array_reset_index tmp1
		array_reset_index tmp2
	fi

	[ "$(array_describe tmp1)" == "$(array_describe tmp2)" ]
}

# @NAME
#     array_intersection -- calcul the intersection of 2 arrays, and save the result to a new variable
# @SYNOPSIS
#     array_intersection arrayVarName1 arrayVarName2 newArrayVarName [ignoreOrderAndDuplicated]
# @DESCRIPTION
#     **arrayVarName1** the variable name of an array
#     **arrayVarName2** the variable name of another array
#     **newArrayVarName** the name of new variable to save the result
#     **[ignoreOrderAndDuplicated]** optional, a boolean value true/false, indicate whether ignore element duplicated and order them when save the result, default true
# @EXAMPLES
#     myArray1=('aa' [3]='bb' 'aa' 'cc')
#     myArray2=('aa' 'aa' 'dd' 'bb')
#     array_intersection myArray1 myArray2 newArray
#     array_intersection myArray1 myArray2 newArray false
# @SEE_ALSO
#     array_subtract, array_union
function array_intersection() {
	local array1="$1[@]"
	local arrayVarName2="$2"
	local newArrayVarName="$3"
	local ignoreOrderAndDuplicated=${4:-true}

	local tmp element2 string command
	tmp=()
	for element2 in "${!array1}"; do
		array_contains "$arrayVarName2" "$element2" && array_append tmp "$element2"
	done

	if [ "${ignoreOrderAndDuplicated}" = true ]; then
		array_sort_distinct tmp
	fi

	string="\${tmp[@]}"
	command="${newArrayVarName}=(\"${string}\")"
	eval "${command}"
}

# @NAME
#     array_subtract -- calcul the subtract of 2 arrays, and save the result to a new variable
# @SYNOPSIS
#     array_subtract arrayVarName1 arrayVarName2 newArrayVarName [ignoreOrderAndDuplicated]
# @DESCRIPTION
#     **arrayVarName1** the variable name of an array
#     **arrayVarName2** the variable name of another array
#     **newArrayVarName** the name of new variable to save the result
#     **[ignoreOrderAndDuplicated]** optional, a boolean value true/false, indicate whether ignore element duplicated and order them when save the result, default true
# @EXAMPLES
#     myArray1=('aa' [3]='bb' 'aa' 'cc')
#     myArray2=('aa' 'aa' 'dd' 'bb')
#     array_subtract myArray1 myArray2 newArray
#     array_subtract myArray1 myArray2 newArray false
# @SEE_ALSO
#     array_intersection, array_union
function array_subtract() {
	local array1="$1[@]"
	local arrayVarName2="$2"
	local newArrayVarName="$3"
	local ignoreOrderAndDuplicated=${4:-true}

	local tmp element2 string command
	tmp=()
	for element2 in "${!array1}"; do
		array_contains "$arrayVarName2" "$element2" || array_append tmp "$element2"
	done

	if [ "${ignoreOrderAndDuplicated}" = true ]; then
		array_sort_distinct tmp
	fi

	string="\${tmp[@]}"
	command="${newArrayVarName}=(\"${string}\")"
	eval "${command}"
}

# @NAME
#     array_union -- calcul the union of 2 arrays, and save the result to a new variable
# @SYNOPSIS
#     array_union arrayVarName1 arrayVarName2 newArrayVarName [ignoreOrderAndDuplicated]
# @DESCRIPTION
#     **arrayVarName1** the variable name of an array
#     **arrayVarName2** the variable name of another array
#     **newArrayVarName** the name of new variable to save the result
#     **[ignoreOrderAndDuplicated]** optional, a boolean value true/false, indicate whether ignore element duplicated and order them when save the result, default true
# @EXAMPLES
#     myArray1=('aa' [3]='bb' 'aa' 'cc')
#     myArray2=('aa' 'aa' 'dd' 'bb')
#     array_union myArray1 myArray2 newArray
#     array_union myArray1 myArray2 newArray false
# @SEE_ALSO
#     array_intersection, array_union
function array_union() {
	local array1="$1[@]"
	local array2="$2[@]"
	local newArrayVarName="$3"
	local ignoreOrderAndDuplicated=${4:-true}

	local tmp element2 string command
	tmp=()
	for element2 in "${!array1}"; do
		array_append tmp "$element2"
	done
	for element2 in "${!array2}"; do
		array_append tmp "$element2"
	done

	if [ "${ignoreOrderAndDuplicated}" = true ]; then
		array_sort_distinct tmp
	fi

	string="\${tmp[@]}"
	command="${newArrayVarName}=(\"${string}\")"
	eval "${command}"
}

# @NAME
#     array_append -- append some elements to original array
# @SYNOPSIS
#     array_append arrayVarName element...
# @DESCRIPTION
#     **arrayVarName** the variable name of array to process
#     **element...** the elements to append to array
# @EXAMPLES
#     myArray=()
#     array_append myArray "ele ment1" "ele ment2"
# @SEE_ALSO
#     array_remove
function array_append() {
	local arrayVarName="$1"
	shift

	local elementToAppend command
	for elementToAppend in "$@"; do
		command="$arrayVarName+=(\"${elementToAppend}\")"
		eval "${command}"
	done
}

# @NAME
#     array_remove -- remove the element from the original array
# @SYNOPSIS
#     array_remove arrayVarName element
# @DESCRIPTION
#     **arrayVarName** the variable name of array to process
#     **element** the element to remove from array
# @EXAMPLES
#     arr=("a" "b" "c" "ab" "f" "g")
#     array_remove arr "ab"
# @SEE_ALSO
#     array_contains, array_append
function array_remove() {
	local arrayVarName="$1"
	local element="$2"

	local string command tmp index
	eval "string='$'{${arrayVarName}[@]}"
	command="tmp=(\"${string}\")"
	eval "${command}"

	for index in "${!tmp[@]}"; do
		if [[ "${tmp[$index]}" == "${element}" ]]; then
			unset tmp["${index}"]
		fi
	done

	string="\${tmp[@]}"
	command="${arrayVarName}=(\"${string}\")"
	eval "${command}"
}

# @NAME
#     array_clone -- clone an array, including index/order/duplication/value, and assign the result array to a new variable name
# @SYNOPSIS
#     array_clone arrayVarName newArrayVarName
# @DESCRIPTION
#     **arrayVarName** the variable name of array to process
#     **newArrayVarName** the variable name of result array
# @EXAMPLES
#     arr=(" a " " b c ")
#     array_clone arr newArray
# @SEE_ALSO
function array_clone() {
	local arrayVarName="$1"
	local arrayVarName2="$2"

	array_from_describe "$arrayVarName2" "$(array_describe "$arrayVarName")"
}

# @NAME
#     array_map -- apply the specified map operation on each element of array, and assign the result array to a new variable name
# @SYNOPSIS
#     array_map arrayVarName pipedOperators [newArrayVarName]
# @DESCRIPTION
#     **arrayVarName** the variable name of array to process
#     **pipedOperators** a string of operations, if multiple operations will be apply on each element, join them by pipe '|'
#     **[newArrayVarName]** optional, the variable name of result array, if absent, the mapped array will be joined by newline and printed to stdout
# @EXAMPLES
#     arr=(" a " " b c ")
#     array_map arr "string_trim | wc -m | string_trim" newArray
# @SEE_ALSO
function array_map() {
	local array="$1[@]"
	local pipedOperators="$2"
	local newArrayVarName="$3"

	local tmp element mapped_value string command
	tmp=()
	for element in "${!array}"; do
		escaped="${element//\'/\'"\'"\'}" # escape the single quote
		mapped_value="$(eval "echo '${escaped}' | ${pipedOperators}")"
		tmp+=("${mapped_value}")
	done

	if [[ -n "${newArrayVarName}" ]]; then
		string="\${tmp[@]}"
		command="${newArrayVarName}=(\"${string}\")"
		eval "${command}"
	else
		array_join $'\n' tmp
	fi
}

# @NAME
#     array_filter -- filter the elements of an array, and assign the result array to a new variable name
# @SYNOPSIS
#     array_filter arrayVarName regExp [newArrayVarName]
# @DESCRIPTION
#     **arrayVarName** the variable name of array to process
#     **regExp** a string of regular expression pattern
#     **[newArrayVarName]** optional, the variable name of result array, if absent, the mapped array will be joined by newline and printed to stdout
# @EXAMPLES
#     arr=("NAME A" "NAME B" "OTHER")
#     array_filter arr 'NAME' newArray
# @SEE_ALSO
function array_filter() {
	local array="$1[@]"
	local regExp="$2"
	local newArrayVarName="$3"

	local tmp element string command
	tmp=()
	for element in "${!array}"; do
		if [[ ${element} =~ ${regExp} ]]; then
			array_append tmp "${element}"
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
