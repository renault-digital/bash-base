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
doc_lint_script_comment() {
	local shellScriptFile="$1"
	local element strAllFunctionsAndTheirTags arrAllFunctionsAndTheirTags manTags strFunctionAndItsTags arrFunctionAndItsTags intersection
	local counter=0 lastFunction=""

	# format the comment
	sed -E -i'.bk' \
		-e "s/^#[[:space:]]*/#/g" \
		-e "s/^#/#     /g" \
		-e "s/^#[[:space:]]+$/#/g" \
		-e "s/^#[[:space:]]*!/#!/g" \
		-e "s/^#[[:space:]]*(@|-|#+)/# \\1/g" \
		"${shellScriptFile}"
	rm -fr "${shellScriptFile}.bk"

	# Accept both historical `function name()` declarations and the shared
	# Bash/zsh `name()` form.
	strAllFunctionsAndTheirTags=$(grep -E -e '^# @' -e '^[[:space:]]*(function[[:space:]]+)?[0-9A-Za-z_-]+[[:space:]]*\(\)[[:space:]]*\{' "${shellScriptFile}" | string_replace_regex '\(\)|#' '' | string_trim)
	string_split_to_array "{" arrAllFunctionsAndTheirTags "${strAllFunctionsAndTheirTags}"
	manTags=('@NAME' '@SYNOPSIS' '@DESCRIPTION' '@EXAMPLES' '@SEE_ALSO')
	for strFunctionAndItsTags in "${arrAllFunctionsAndTheirTags[@]}"; do
		string_split_to_array $'\n' arrFunctionAndItsTags "${strFunctionAndItsTags}"
		array_intersection manTags arrFunctionAndItsTags intersection false
		array_equals manTags intersection false
		if [[ $? -ne 0 ]]; then
			counter=$((counter + 1))
			typeset -p manTags intersection
			lastFunction=""
			for element in "${arrFunctionAndItsTags[@]}"; do
				lastFunction="$element"
			done
			print_error "the comments is not the same as template for ${lastFunction}"
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
doc_comment_to_markdown() {
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

	printf '%b\n' "@NAME\n${md//${NEW_LINE_SED}/\\n}" | # NEW_LINE_SED is not compatible by pandoc
		string_replace_regex '@([A-Z]+)' "##### \1" >"${toMarkdownFile}"
}
