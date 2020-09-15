#shellcheck shell=bash

Include src/tool.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


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


Describe 'print_info'
    It '-'
        When call print_info abc
        The output should eq "${COLOR_END}abc"
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

