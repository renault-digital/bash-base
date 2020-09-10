#!/usr/bin/env bash

source src/document.sh
source src/tool.sh

shellScriptFile="bin/bash-base.sh"
referencesMarkdownFile="docs/references.md"
referencesManPageFile="man/bash-base.1"

print_header 'Clean before generation'
rm -fr "${shellScriptFile}" "${referencesMarkdownFile}" "${referencesManPageFile}"

print_header 'Audit source code'
./scripts/lint-comment.sh

print_header "Generate ${shellScriptFile}"
echo -e "#!/usr/bin/env bash\n" >"${shellScriptFile}"
for filename in src/*.sh; do
	sed -E -e 's/^[[:space:]]*\#\!\/.*$//g' -e 's/^[[:space:]]*source .*$//g' "${filename}" >>"${shellScriptFile}"
done
docker run --rm -v "$(pwd):/src" -w /src mvdan/shfmt -l -w "${shellScriptFile}"

print_header 'Generate references markdown from script comment'
doc_comment_to_markdown "${shellScriptFile}" "${referencesMarkdownFile}"

print_header 'Generate man page from markdown using pandoc'
docker run --rm --volume "$(pwd):/data" --user "$(id -u):$(id -g)" pandoc/core:2.10 \
	-f markdown \
	-t man \
	--standalone \
	--variable=section:1 \
	--variable=header:"bash-base functions reference" \
	"${referencesMarkdownFile}" \
	-o "${referencesManPageFile}"

print_header 'Verify some lines of man page'
man -P cat "${referencesManPageFile}" | head -50 || exit 1
