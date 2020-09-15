#shellcheck shell=bash

Include src/tool.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe 'print_header'
    It '-'
        When call print_header abc
        The output should eq "${COLOR_BOLD_MAGENTA}
### abc ${COLOR_END}"
    End
End


Describe 'print_success'
    It '-'
        When call print_success abc
        The output should eq "${COLOR_BOLD_GREEN}OK: abc ${COLOR_END}"
    End
End


Describe 'print_debug'
    It '-'
        LOG_LEVEL=$LOG_LEVEL_DEBUG
        When call print_debug abc
        The output should eq "${COLOR_GRAY}DEBUG: abc${COLOR_END}"
        LOG_LEVEL=$LOG_LEVEL_INFO
    End

    It '-'
        LOG_LEVEL=$LOG_LEVEL_INFO
        When call print_debug abc
        The output should eq ""
    End
End


Describe 'print_info'
    It '-'
        When call print_info abc
        The output should eq "${COLOR_END}INFO: abc"
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


Describe 'print_args'
    It '-'
        var1="value 1"
        var2="value 2"
        func() { actual=$(print_args var1 var2); }
        When run func
        The value "$(echo ${actual} | sed -e 's/ //g' -e 's/\n//g')" should eq "var1:${COLOR_BLUE}value1${COLOR_END}var2:${COLOR_BLUE}value2${COLOR_END}"
    End
End
