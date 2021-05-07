#shellcheck shell=bash

Include src/array.sh
Include src/string.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe array_contains
    arr=("a" "b" "c" "a b" "f" "g")

    It 'found'
        When call array_contains arr "a b"
        The status should be success
    End

    It 'found pipe'
        When call eval 'echo "a b" | array_contains arr'
        The status should be success
    End

    It 'not found'
        When call array_contains arr "abc"
        The status should be failure
    End
End


Describe array_in
    It 'found with quoted args'
        When call array_in "a b" "a" "b" "c" "a b" "f" "g"
        The status should be success
    End

    It 'not found'
        When call array_in "a b" "a"
        The status should be failure
    End

    It 'not found with empty array'
        When call array_in "a b"
        The status should be failure
    End

    It 'found in args'
        When call array_in a_b a b c a_b f g
        The status should be success
    End

    It 'found in string'
        str="a b c a_b f g"
        When call array_in "a_b" $str
        The status should be success
    End
End


Describe 'array_sort'
    It '-'
        myArray=('aa' 'bb' 'aa')
        When call array_sort myArray
        The variable myArray should satisfy array_describe_equals myArray "([0]='aa' [1]='aa' [2]='bb')"
    End
End


Describe 'array_sort_distinct'
    It '-'
        myArray=('aa' 'bb' 'aa')
        When call array_sort_distinct myArray
        The variable myArray should satisfy array_describe_equals myArray "([0]='aa' [1]='bb')"
    End
End


Describe 'array_length'
    It '-'
        myArray=('aa' 'bb' 'aa')
        When call array_length myArray
        The output should eq "3"
    End
End


Describe 'array_reset_index'
    It '-'
        myArray=([2]='a' [5]='c' [11]='dd')
        When call array_reset_index myArray
        The variable myArray should satisfy array_describe_equals myArray "([0]='a' [1]='c' [2]='dd')"
    End
End


Describe 'array_equals'
    myArray1=('aa' [3]='bb' 'aa')
    myArray2=('aa' 'aa' 'bb')
    myArray3=('bb' 'aa')

    Parameters
        myArray1 myArray2 false false "1"
        myArray1 myArray2 false true "1"
        myArray1 myArray2 true false "0"
        myArray1 myArray2 true true "0"
        myArray1 myArray3 false false "1"
        myArray1 myArray3 false true "1"
        myArray1 myArray3 true false "1"
        myArray1 myArray3 true true "0"
    End

    Example "should be $5 when ignoreOrder $3 and ignoreDuplicated $4"
        When call array_equals $1 $2 $3 $4
        The status should eq "$5"
    End
End


Describe 'array_intersection'
    myArray1=('aa' [3]='bb' 'aa' 'cc')
    myArray2=('aa' 'aa' 'dd' 'bb')

    It 'ignore duplicated and order'
        When call array_intersection myArray1 myArray2 newArray
        The variable newArray should satisfy array_describe_equals newArray "([0]='aa' [1]='bb')"
    End

    It 'not ignore duplicated and order'
        When call array_intersection myArray1 myArray2 newArray false
        The variable newArray should satisfy array_describe_equals newArray "([0]='aa' [1]='bb' [2]='aa')"
    End
End


Describe 'array_subtract'
    myArray1=('aa' [3]='bb' 'aa' 'cc' 'cc')
    myArray2=('aa' 'aa' 'dd' 'bb')

    It 'ignore duplicated and order'
        When call array_subtract myArray1 myArray2 newArray
        The variable newArray should satisfy array_describe_equals newArray "([0]='cc')"
    End

    It 'not ignore duplicated and order'
        When call array_subtract myArray1 myArray2 newArray false
        The variable newArray should satisfy array_describe_equals newArray "([0]='cc' [1]='cc')"
    End
End


Describe 'array_union'
    myArray1=('aa' [3]='bb' 'aa' 'cc' 'cc')
    myArray2=('aa' 'aa' 'dd' 'bb')

    It 'ignore duplicated and order'
        When call array_union myArray1 myArray2 newArray
        The variable newArray should satisfy array_describe_equals newArray "([0]='aa' [1]='bb' [2]='cc' [3]='dd')"
    End

    It 'not ignore duplicated and order'
        When call array_union myArray1 myArray2 newArray false
        The variable newArray should satisfy array_describe_equals newArray  "([0]='aa' [1]='bb' [2]='aa' [3]='cc' [4]='cc' [5]='aa' [6]='aa' [7]='dd' [8]='bb')"
    End
End


Describe 'array_append'
    It '-'
        When call eval 'array_append myarr " ele ment1" " ele ment2 "; array_append myarr "ele ment3" "ele ment4 "'
        The variable myarr should satisfy array_describe_equals myarr "([0]=' ele ment1' [1]=' ele ment2 ' [2]='ele ment3' [3]='ele ment4 ')"
    End
End


Describe 'array_clone'
    It '-'
        myarr=('aa' [3]='bb' 'aa')
        When call array_clone myarr myarr4
        The variable myarr4 should satisfy array_describe_equals myarr4  "([0]='aa' [3]='bb' [4]='aa')"
    End
End


Describe 'array_map'
    arr=(" a " " b '(c ")
    embeded="b '(c"

    It 'cat'
        When call array_map arr "cat" actual
        The variable actual should satisfy array_describe_equals actual "([0]=' a ' [1]=' ${embeded} ')"
    End

    It 'string_trim'
        When call array_map arr "string_trim" actual
        The variable actual should satisfy array_describe_equals actual "([0]='a' [1]='${embeded}')"
    End

    It 'string_trim stdout'
        When call array_map arr "string_trim"
        The output should eq "$(printf "a\n${embeded}" )"
    End

    It 'string_trim | wc -m | string_trim'
        When call array_map arr "string_trim | wc -m | string_trim" actual
        The variable actual should satisfy array_describe_equals actual "([0]='2' [1]='6')"
    End

    It 'sed'
        branchesArray=(
        "  origin/develop"
        "  origin/integration"
        "* origin/feature/52-new-feature")
        When call array_map branchesArray "sed -e 's/*//' -e 's/^[[:space:]]*//' -e 's/^origin\///' | string_trim" actual
        The variable actual should satisfy array_describe_equals actual "([0]='develop' [1]='integration' [2]='feature/52-new-feature')"
    End
End


Describe 'array_filter'
    arr=("NAME" "NAME B" "OTHER")

    It 'string_trim'
        When call array_filter arr 'NAME' actual
        The variable actual should satisfy array_describe_equals actual "([0]='NAME' [1]='NAME B')"
    End

    It 'string_trim stdout'
        When call array_filter arr 'NAME'
        The output should eq  $'NAME\nNAME B'
    End
End


Describe 'array_join'
    It 'normal array'
        arr=(" a " " b c ")
        When call array_join '|' arr
        The output should eq " a | b c "
    End

    It 'empty array'
        arr=()
        When call array_join '|' arr
        The output should eq ""
    End
End


Describe 'array_remove'
    It '-'
        arr=("a" " b" "c" "a b" "f" "g")
        When call array_remove arr "a b"
        The variable arr should satisfy array_describe_equals arr "([0]='a' [1]=' b' [2]='c' [3]='f' [4]='g')"
    End
End


Describe 'array_describe'
    arr=("a" " b" "c" "a b" "f" "g")
    It 'with simple value'
        When call array_describe arr
        The output should eq "([0]='a' [1]=' b' [2]='c' [3]='a b' [4]='f' [5]='g')"
    End

    It 'with mapped value'
        branchesArray=("  origin/develop" "  origin/integration" "* origin/feature/52-new-feature")
        actual=($(
            for opt in "${branchesArray[@]}"; do
                echo -e "${opt//\*/}" | string_trim | sed -e 's/^origin\///' #trim ' ' and '*'
            done
        ))

        When call array_describe actual
        The output should eq "([0]='develop' [1]='integration' [2]='feature/52-new-feature')"
    End
End

Describe 'array_from_describe'
    strDescribe="([1]=' as' [5]='fd ')"
    It 'with value'
        When call array_from_describe actual "${strDescribe}"
        The value "$(declare -p actual)" should eq "declare -a actual=([1]=\" as\" [5]=\"fd \")"
    End

    It 'with file'
        echo "${strDescribe}" > temp_file.txt
        When call eval "array_from_describe actual < temp_file.txt"
        The value "$(declare -p actual)" should eq "declare -a actual=([1]=\" as\" [5]=\"fd \")"
        rm -fr temp_file.txt
    End
End
