#shellcheck shell=bash

Include src/array.sh
Include src/tool.sh
Include src/string.sh
Include src/reflection.sh
Include src/argument.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe args_parse
    It 'params'
        set -- "param 1" "param 2"

        When call args_parse $# "$@" var1 var2
        The value "$#" should eq "2"
        The value "$1" should eq "param 1"
        The variable var1 should eq "param 1"
        The variable var2 should eq "param 2"
    End

    It 'modeQuiet'
        set -- "-q"

        When call args_parse $# "$@" var1 var2
        The value "$#" should eq "1"
        The value "$1" should eq "-q"
        The variable var1 should eq ""
        The variable var2 should eq ""
        The variable modeQuiet should eq "true"
    End

    It 'print customized USAGE'
        set -- "-h"
        USAGE="Usage:..."

        When run args_parse $# "$@" var1 var2
        The value "$#" should eq "1"
        The value "$1" should eq "-h"
        The variable var1 should be undefined
        The variable var2 should be undefined
        The status should be success
        The output should eq "Usage:..."
    End

    It 'print generated usage with customized SHORT_DESC'
        cat <<-EOF > my_script.sh
					#!/usr/bin/env bash

          source src/array.sh
          source src/tool.sh
          source src/string.sh
          source src/reflection.sh
          source src/argument.sh

					SHORT_DESC='this is a script for test generated help usage'

					args_parse \$# "\$@" myVar1 myVar2 myVar3 myVar4 myVar5 myVar44 fromEnv varWithoutValidation
					args_valid_or_read myVar1 '^[0-9a-z ]{3,}$' 'SIA (lowercase, 3 chars)'
					args_valid_or_read myVar2 '^[0-9a-z ]{3,}$' 'SIA <lowercase, 3 chars>'
					args_valid_or_read myVar3 '^[0-9a-z ]{3,}$' 'SIA [lowercase, 3 chars]'
					args_valid_or_read myVar4 '^[0-9a-z ]{3,}$' 'SIA \${lowercase, 3 chars}'
					args_valid_or_read myVar5 '^[0-9a-z ]{3,}$' 'SIA |lowercase, 3 chars'
					args_valid_or_select myVar44 arrBranchesToSelectCleaned "The base of merge request (normally it's develop or integration)"
					args_valid_or_select_pipe fromEnv 'int|qua|sta|rec|ope' "Which env of DCP Alpine" int
				EOF
        chmod +x my_script.sh

        declare_heredoc expected <<-EOF
					${COLOR_BOLD_BLACK}NAME${COLOR_END}
					    my_script.sh -- this is a script for test generated help usage

					${COLOR_BOLD_BLACK}SYNOPSIS${COLOR_END}
					    ./my_script.sh [-qh] myVar1 myVar2 myVar3 myVar4 myVar5 myVar44 fromEnv varWithoutValidation

					${COLOR_BOLD_BLACK}DESCRIPTION${COLOR_END}
					    [-h]                help, print the usage
					    [-q]                optional, Run quietly, no confirmation

					    myVar1              SIA (lowercase, 3 chars)
					    myVar2              SIA <lowercase, 3 chars>
					    myVar3              SIA [lowercase, 3 chars]
					    myVar4              SIA \${lowercase, 3 chars}
					    myVar5              SIA |lowercase, 3 chars
					    myVar44             The base of merge request (normally its develop or integration), you can select one using wizard if you do not know which value is valid
					    fromEnv             Which env of DCP Alpine, possible values: int|qua|sta|rec|ope
					    varWithoutValidation a valid value for varWithoutValidation

					${COLOR_BOLD_BLACK}EXAMPLES${COLOR_END}
					    help, print the usage:
					        ./my_script.sh -h

					    run with all params, if run in quiet mode with -q, be sure all the params are valid:
					        ./my_script.sh [-q] "myVar1Value" "myVar2Value" "myVar3Value" "myVar4Value" "myVar5Value" "myVar44Value" "fromEnvValue" "varWithoutValidationValue"

					    run using wizard, input value for params step by step:
					        ./my_script.sh

					    or you can run with some params, and input value for other params using wizard.
				EOF

        When run script my_script.sh -h
        The status should be success
        The output should eq "$expected"

        rm -fr my_script.sh
    End

    It 'option invalid'
        set -- "-d"

        When run args_parse $# "$@" var1 var2
        The value "$#" should eq "1"
        The value "$1" should eq "-d"
        The variable var1 should be undefined
        The variable var2 should be undefined
        The status should be success
        The error should include "ERROR: invalid option: -d"
    End
End


Describe args_valid_or_select {
    arr=("a" "ab" "d")
    It 'init valid'
        sel="ab"
        When call args_valid_or_select sel arr "which value"
        The variable sel should eq "ab"
        The output should start with "Selected value: ${COLOR_BLUE}'ab'"
    End

    It 'init value invalid and select the first one'
        sel="abc"
        When call eval 'yes 1 | args_valid_or_select sel arr "which value" | grep "Selected"'
        The output should eq "Selected value: ${COLOR_BLUE}'a'${COLOR_END}"
        The error should include "choose one by"
    End

    It 'init value invalid and select the second one'
        sel="abc"
        When call eval 'yes 2 | args_valid_or_select sel arr "which value" | grep "Selected"'
        The output should eq "Selected value: ${COLOR_BLUE}'ab'${COLOR_END}"
        The error should include "choose one by"
    End
End


Describe args_valid_or_select_pipe {
    It 'init value valid'
        sel="ab"
        When call args_valid_or_select_pipe sel "a|ab|d" "which value"
        The variable sel should eq "ab"
        The output should start with "Selected value: ${COLOR_BLUE}'ab'"
    End

    It 'init value invalid and select the first one'
        sel="abc"
        When call eval 'yes 1 | args_valid_or_select_pipe sel "a|ab|d" "which value" | grep "Selected"'
        The output should eq "Selected value: ${COLOR_BLUE}'a'${COLOR_END}"
        The error should include "choose one by"
    End

    It 'init value invalid and select the second one'
        sel="abc"
        When call eval 'yes 2 | args_valid_or_select_pipe sel "a|ab|d" "which value" | grep "Selected"'
        The output should eq "Selected value: ${COLOR_BLUE}'ab'${COLOR_END}"
        The error should include "choose one by"
    End

    It 'init value invalid and save result to variable'
        sel="abc"
        func() { actual=$(yes 1 | args_valid_or_select_pipe sel "a|ab|d" "which value" | grep "Selected"); }
        When run func
        The variable actual should eq "Selected value: ${COLOR_BLUE}'a'${COLOR_END}"
        The error should include "choose one by"
    End
End


Describe args_valid_or_read
    It 'the value is unset'
        When call eval "yes 70022 | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN (only the 5 digits)' | grep 'Inputted'"
        The output should eq "Inputted value: ${COLOR_BLUE}'70022'${COLOR_END}"
    End

    It 'the value is empty'
        irn=""
        When call eval "yes 70022 | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN (only the 5 digits)' | grep 'Inputted'"
        The output should eq "Inputted value: ${COLOR_BLUE}'70022'${COLOR_END}"
    End

    It "the value is not valid"
        irn="225"
        When call eval "yes 70022 | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN (only the 5 digits)' | grep 'Inputted'"
        The output should eq "Inputted value: ${COLOR_BLUE}'70022'${COLOR_END}"
    End

    It "the value is valid"
        irn="70033"
        When call eval "yes 70022 | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN (only the 5 digits)'"
        The variable irn should eq "70033"
        The output should eq "Inputted value: ${COLOR_BLUE}'70033'${COLOR_END}"
    End

    It 'take proposedValue when the value is unset and modeQuiet is true'
        modeQuiet="true"
        When call eval "yes 70022 | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN (only the 5 digits)' 70088 | grep 'Inputted'"
        The output should eq "Inputted value: ${COLOR_BLUE}'70088'${COLOR_END}"
    End

    It 'take proposedValue when the value is empty and modeQuiet is true'
        irn=""
        modeQuiet="true"
        When call eval "yes 70022 | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN (only the 5 digits)' 70088 | grep 'Inputted'"
        The output should eq "Inputted value: ${COLOR_BLUE}'70088'${COLOR_END}"
    End

    It 'take proposedValue when user input nothing'
        modeQuiet="false"
        When call eval "yes '' | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN (only the 5 digits)' 70088 | grep 'Inputted'"
        The output should eq "Inputted value: ${COLOR_BLUE}'70088'${COLOR_END}"
    End

    It 'not take proposedValue when value is valid'
        modeQuiet="false"
        irn="70033"
        When call eval "yes '' | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN (only the 5 digits)' 70088 | grep 'Inputted'"
        The output should eq "Inputted value: ${COLOR_BLUE}'70033'${COLOR_END}"
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


Describe 'args_confirm'
    var1="value 1"
    var2="value 2"

    It 'modeQuiet true'
        modeQuiet="true"
        func() { actual=$(args_confirm var1 var2 && echo 'Excuting following code'); }
        When run func
        The value "$(echo ${actual} | sed -e 's/ //g' -e 's/\n//g')" should eq "var1:${COLOR_BLUE}value1${COLOR_END}var2:${COLOR_BLUE}value2${COLOR_END}Excutingfollowingcode"
    End

    It 'modeQuiet false and input y'
        modeQuiet="false"
        func() { actual=$(yes | args_confirm var1 var2 && echo 'Excuting following code'); }
        When run func
        The value "$(echo ${actual} | sed -e 's/ //g' -e 's/\n//g')" should eq "var1:${COLOR_BLUE}value1${COLOR_END}var2:${COLOR_BLUE}value2${COLOR_END}Starting...Excutingfollowingcode"
    End

    It 'modeQuiet false and input n'
        modeQuiet="false"
        func() { eval "yes 'n' | args_confirm var1 var2 && echo 'Excuting following code'"; }
        When run func
        The output should include "var1:                         ${COLOR_BLUE}value 1${COLOR_END}"
        The output should include "var2:                         ${COLOR_BLUE}value 2${COLOR_END}"
        The output should end with "Exiting..."
        The status should be failure
    End
End