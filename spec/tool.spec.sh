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


Describe 'wait_for'
    It 'ok'
        When call wait_for 'test 1 -eq 1' slowTask 2
        The status should be success
        The output should include "OK: slowTask is ok now"
    End

    It 'not ok'
        rm -fr a.txt
        func() {  actual=$( wait_for 'test -f a.txt' slowTask 2 & touch a.txt); }
        When run func
        The status should be success
        The value "${actual}" should include "WARN: Waiting for slowTask to be ok"
        The value "${actual}" should include "OK: slowTask is ok now"
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


Describe 'confirm_to_continue'
    var1="value 1"
    var2="value 2"

    It 'modeQuiet true'
        modeQuiet="true"
        func() { actual=$(confirm_to_continue var1 var2 && echo 'Excuting following code'); }
        When run func
        The value "$(echo ${actual} | sed -e 's/ //g' -e 's/\n//g')" should eq "var1:${COLOR_BLUE}value1${COLOR_END}var2:${COLOR_BLUE}value2${COLOR_END}Excutingfollowingcode"
    End

    It 'modeQuiet false and input y'
        modeQuiet="false"
        func() { actual=$(echo y | confirm_to_continue var1 var2 && echo 'Excuting following code'); }
        When run func
        The value "$(echo ${actual} | sed -e 's/ //g' -e 's/\n//g')" should eq "var1:${COLOR_BLUE}value1${COLOR_END}var2:${COLOR_BLUE}value2${COLOR_END}Continue...Excutingfollowingcode"
    End

    It 'modeQuiet false and input n'
        modeQuiet="false"
        func() { eval "echo 'n' | confirm_to_continue var1 var2 && echo 'Excuting following code'"; }
        When run func
        The output should include "var1:                         ${COLOR_BLUE}value 1${COLOR_END}"
        The output should include "var2:                         ${COLOR_BLUE}value 2${COLOR_END}"
        The output should end with "Exiting..."
        The status should be failure
    End
End
