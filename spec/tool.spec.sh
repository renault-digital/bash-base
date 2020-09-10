#shellcheck shell=bash

Include src/tool.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe 'declare_heredoc'
    It '-'
        func() { declare_heredoc actual <<-EOF
					 A B
					 C
				EOF
        }
        When run func
        The variable actual should eq $' A B\n C'
    End
End


Describe 'print_header'
    It '-'
        When call print_header abc
        The output should eq "${COLOR_BOLD_BLACK}
### abc ${COLOR_END}"
    End
End


Describe 'print_success'
    It '-'
        When call print_success abc
        The output should eq "${COLOR_BOLD_GREEN}OK: abc ${COLOR_END}"
    End
End


Describe 'print_warn'
    It '-'
        When call print_warn abc
        The output should eq "${COLOR_BOLD_YELLOW}WARN: abc ${COLOR_END}"
    End
End


Describe 'print_error'
    It '-'
        When call print_error abc
        The output should eq "${COLOR_BOLD_RED}ERROR: abc ${COLOR_END}"
    End
End


Describe 'stop_if_failed'
    It 'no error'
        func() { eval "echo 'message normal'; stop_if_failed 'error occurred'"; }
        When run func
        The output should eq "message normal"
        The status should be success
    End

    It 'command not found'
        func() { eval "a_function_not_existed; stop_if_failed 'error occurred'"; }
        When run func
        The output should include "${COLOR_BOLD_RED}ERROR: error occurred ${COLOR_END}"
        The error should include "a_function_not_existed: command not found"
        The status should be failure
    End

    It 'function exit with error'
        function a_function_exit_error() {
          return 1
        }
        func() { eval "a_function_exit_error; stop_if_failed 'error occurred'"; }
        When run func
        The output should include "${COLOR_BOLD_RED}ERROR: error occurred ${COLOR_END}"
        The status should be failure
    End
End
