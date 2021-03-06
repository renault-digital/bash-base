#!/usr/bin/env bash

source src/constant.sh
source src/string.sh
source src/array.sh

# @NAME
#     doc_lint_script_comment -- format the shell script, and check whether the comment is corrected man-styled
# @SYNOPSIS
#     doc_lint_script_comment shellScriptFile
# @DESCRIPTION
#     It's better format your shell script by `shfmt` firstly before using this function.
#
#     **shellScriptFile** the path of shell script file
# @EXAMPLES
#     shellScriptFile="src/reflection.sh"
#     docker run -it --rm -v "$(pwd):/src" -w /src mvdan/shfmt -l -w "${shellScriptFile}"
#     doc_lint_script_comment "${shellScriptFile}"
# @SEE_ALSO
#     doc_comment_to_markdown
function doc_lint_script_comment() {
	local shellScriptFile="$1"
	local element strAllFunctionsAndTheirTags arrAllFunctionsAndTheirTags manTags strFunctionAndItsTags arrFunctionAndItsTags intersection counter

	# format the comment
	sed -E -i'.bk' \
		-e "s/^#[[:space:]]*/#/g" \
		-e "s/^#/#     /g" \
		-e "s/^#[[:space:]]+$/#/g" \
		-e "s/^#[[:space:]]*!/#!/g" \
		-e "s/^#[[:space:]]*(@|-|#+)/# \1/g" \
		"${shellScriptFile}"
	rm -fr "${shellScriptFile}.bk"

	# valid comment tags by man page convention
	strAllFunctionsAndTheirTags=$(grep -e '^# @' -e '^function ' "${shellScriptFile}" | string_replace_regex '\(\)|#' '' | string_trim)
	string_split_to_array "{" arrAllFunctionsAndTheirTags "${strAllFunctionsAndTheirTags}"
	local manTags=('@NAME' '@SYNOPSIS' '@DESCRIPTION' '@EXAMPLES' '@SEE_ALSO')
	for strFunctionAndItsTags in "${arrAllFunctionsAndTheirTags[@]}"; do
		string_split_to_array $'\n' arrFunctionAndItsTags "${strFunctionAndItsTags}"
		array_intersection manTags arrFunctionAndItsTags intersection false
		array_equals manTags intersection false
		if [[ $? -ne 0 ]]; then
			((counter++))
			declare -p manTags intersection
			print_error "the comments is not the same as template for ${arrFunctionAndItsTags[-1]}"
		fi
	done

	if ((counter > 0)); then
		echo "there are ${counter} functions has invalid comments in file ${shellScriptFile}"
		return 1
	fi
}

# @NAME
#     doc_comment_to_markdown -- convert the shell script man-styled comment to markdown file
# @SYNOPSIS
#     doc_comment_to_markdown fromShellFile toMarkdownFile
# @DESCRIPTION
#     **fromShellFile** the path of source shell script file
#     **toMarkdownFile** the path of destination markdown file
# @EXAMPLES
#     doc_comment_to_markdown src/reflection.sh docs/references.md
# @SEE_ALSO
#     doc_lint_script_comment
function doc_comment_to_markdown() {
	local fromShellFile="$1"
	local toMarkdownFile="$2"

	local md mdComment
	md="$(
		grep '^#' "${fromShellFile}" |
			string_trim |
			string_replace_regex '^#!.*' '' |
			string_replace_regex '^#' '' |
			string_trim |
			sed '/./,$!d' | # Delete all leading blank lines at top of file (only).
			sed '1d' |      # Delete first line of file
			string_replace_regex '^(@NAME)' "${NEW_LINE_SED}---${NEW_LINE_SED}${NEW_LINE_SED}\1" |
			string_replace_regex '^(@SYNOPSIS|@EXAMPLES)' "${NEW_LINE_SED}\1${NEW_LINE_SED}\`\`\`" |
			string_replace_regex '^(@DESCRIPTION|@SEE_ALSO)' "\`\`\`${NEW_LINE_SED}${NEW_LINE_SED}\1" |
			string_replace_regex '^(\*\*)' "- \1"
	)"

	echo -e "@NAME\n${md//${NEW_LINE_SED}/\\n}" | #NEW_LINE_SED is not compatible by pandoc
		string_replace_regex '@([A-Z]+)' "##### \1" >"${toMarkdownFile}"
}
