#shellcheck shell=bash

Include src/reflection.sh
Include src/string.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe 'reflect_nth_arg example'
    It 'with arguments array'
        When call reflect_nth_arg 3 'ab cdv "ha ho"'
        The output should eq "ha ho"
    End

    It 'with variable'
        string="args_valid_or_read myVar '^[0-9a-z]{3,3}$' \"SIA\""
        When call reflect_nth_arg 4 $string
        The output should eq "SIA"
    End

    It 'regexp include space'
        string="args_valid_or_read myVar '^[A-Za-z ]{2,}$' \"SIA\""
        When call reflect_nth_arg 4 $string
        The output should eq "SIA"
    End

    It 'with variable and single quote'
        string="args_valid_or_read myVar '^[0-9a-z]{3,3}$' 'SIA (lowercase, 3 chars)'"
        When call reflect_nth_arg 4 $string
        The output should eq "SIA (lowercase, 3 chars)"
    End

    It 'with variable and double quote'
        string="args_valid_or_read myVar '^[0-9a-z]{3,3}$' \"SIA (lowercase, 3 chars)\""
        When call reflect_nth_arg 4 $string
        The output should eq "SIA (lowercase, 3 chars)"
    End

    It 'with variable with slash dollar'
        string="args_valid_or_read myVar ^[0-9a-z]{3,5,9}\$ \"SIA (lowercase, 3 chars)\""
        When call reflect_nth_arg 4 $string
        The output should eq "SIA (lowercase, 3 chars)"
    End

    It 'with variable with regular expression and redirection'
        string="args_valid_or_read myVar '^(?<=prefix.*)&nbsp;\/\|[0-9a-z]{3,5,9}(?!suffix+)$' \"SIA (lowercase, 3 chars)\" \${proposedValue} | cat <input >output 2>&1"
        When call reflect_nth_arg 4 $string
        The output should eq "SIA (lowercase, 3 chars)"
    End

    It 'index in the string'
        string="4 args_valid_or_read myVar '^(?<=prefix.*)&nbsp;\/\|[0-9a-z]{3,5,9}(?!suffix+)$' \"SIA (lowercase, 3 chars)\" \${proposedValue} | cat <input >output 2>&1"
        When call reflect_nth_arg "$string"
        The output should eq "SIA (lowercase, 3 chars)"
    End
End


Describe 'reflect_nth_arg'
    Parameters
        "="
        "~"
        "-"
        "*"
        "?"
        "."
        "&"
        "+"
        "\\"
        "/"
        "^"
        '$'
        "%"
        "!"
        "|"
        "#"
        " "
        "{"
        "}"
        "<"
        ">"
        "["
        "]"
        "("
        ")"
    End

    Example "with string contains $1"
        string="args_valid_or_read myVar 'a$1b' \"c$1d\" 'SIA (lowercase, 3 chars)'"
        When call reflect_nth_arg 5 $string
        The output should eq "SIA (lowercase, 3 chars)"
    End
End


Describe 'reflect_get_function_definition'
    It 'bash-base function'
        When call reflect_get_function_definition reflect_nth_arg
        The status should eq "0"
        The output should include "reflect_nth_arg"
    End

    It 'test function'
        When call reflect_get_function_definition array_describe_equals
        The status should eq "0"
        The output should include "array_describe_equals"
    End
End


Describe 'reflect_function_names_of_file'
    It '-'
        shellScriptFile="bash-base-for-test.sh"
        rm -fr "${shellScriptFile}"
        for filename in src/*.sh; do
          sed -E -e 's/^[[:space:]]*\#\!\/.*$//g' -e 's/^[[:space:]]*source .*$//g' "${filename}" >>"${shellScriptFile}"
        done

        When call reflect_function_names_of_file "${shellScriptFile}"
        The status should eq "0"
        The output should include "reflect_nth_arg"
        The lines of output should eq 59

        rm -fr "${shellScriptFile}"
    End
End


Describe 'reflect_function_definitions_of_file'
    It '-'
        When call reflect_function_definitions_of_file src/reflection.sh
        The status should eq "0"
        The output should include "reflect_nth_arg() {"
    End
End


Describe 'reflect_search_function'
    It 'normal pattern'
        When call reflect_search_function reflect
        The status should eq "0"
        The output should include "reflect_nth_arg"
    End

    It 'regular expression pattern'
        When call reflect_search_function '^reflect_.*'
        The status should eq "0"
        The output should include "reflect_nth_arg"
    End
End


Describe 'reflect_search_variable'
    It 'normal pattern'
        When call reflect_search_variable COLOR
        The status should eq "0"
        The output should include "COLOR_BLUE"
    End

    It 'regular expression pattern'
        When call reflect_search_variable '^COLOR.*'
        The status should eq "0"
        The output should include "COLOR_BLUE"
    End
End
