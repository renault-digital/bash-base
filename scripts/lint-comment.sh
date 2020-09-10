#!/usr/bin/env bash

source src/document.sh
source src/tool.sh

print_header 'format source code'
npm run shfmt

print_header 'lint script comment'
for filename in src/*.sh; do
	doc_lint_script_comment "${filename}" || ((nbFailed++))
done

print_header 'print global result'
if [[ "${nbFailed}" -gt 0 ]]; then
	print_error 'invalid comment existed'
	exit 1
else
	print_success 'all comments are valid'
fi
