#shellcheck shell=bash

Include src/alias.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe 'args_confirm'
    var1="value 1"
    var2="value 2"

    It 'alias args_confirm'
        modeQuiet="true"
        func() { actual=$(args_confirm var1 var2 && echo 'Excuting following code'); }
        When run func
        The value "$(echo ${actual} | sed -e 's/ //g' -e 's/\n//g')" should eq "var1:${COLOR_BLUE}value1${COLOR_END}var2:${COLOR_BLUE}value2${COLOR_END}Excutingfollowingcode"
    End
End

Describe 'args_print'
    It '-'
        var1="value 1"
        var2="value 2"
        func() { actual=$(args_print var1 var2); }
        When run func
        The value "$(echo ${actual} | sed -e 's/ //g' -e 's/\n//g')" should eq "var1:${COLOR_BLUE}value1${COLOR_END}var2:${COLOR_BLUE}value2${COLOR_END}"
    End
End
