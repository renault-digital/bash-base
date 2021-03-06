#shellcheck shell=bash

Include src/document.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe 'doc_lint_script_comment'
    It 'valid script'
        When call doc_lint_script_comment src/document.sh
        The status should eq "0"
    End

    It 'invalid script'
        cat <<-EOF > my_script.sh
					#!/usr/bin/env bash

					# @NAME
					#     func_with_invalid_comment -- not good
					function func_with_invalid_comment() {
					  echo
					}
				EOF
        When call doc_lint_script_comment my_script.sh
        The status should eq "1"
        The output should include "the comments is not the same as template for function func_with_invalid_comment"

        rm -fr my_script.sh
    End
End


Describe 'doc_comment_to_markdown'
    It '-'
        rm -fr docs/references-test.md

        When call doc_comment_to_markdown src/document.sh docs/references-test.md
        The status should eq "0"
        The contents of file "docs/references.md" should include "args_parse -- parse the script argument values to positional variable"

        rm -fr docs/references-test.md
    End
End
