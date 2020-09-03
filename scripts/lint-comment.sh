#!/usr/bin/env bash

source src/bash-base.sh

shellScriptFile="src/bash-base.sh"

# format script code
docker run --rm -v "$(pwd):/src" -w /src mvdan/shfmt -l -w "${shellScriptFile}"

# lint script comment
doc_lint_script_comment "${shellScriptFile}"
stop_if_failed 'the comment is not valid'
