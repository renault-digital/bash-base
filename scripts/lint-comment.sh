#!/usr/bin/env bash

source src/document.sh
source src/tool.sh

shellScriptFile="bin/bash-base.sh"

print_header 'format source code'
npm run shfmt

print_header 'lint script comment'
doc_lint_script_comment "${shellScriptFile}"
stop_if_failed 'the comment is not valid'
