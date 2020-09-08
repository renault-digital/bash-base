#shellcheck shell=bash

Include "src/bash-base.sh"

array_describe_equals() {
    local arrayName="$1"
    local expected="$2"

    actual=$(array_describe "${arrayName}")

    if [[ "${expected}" != "${actual}" ]]; then
        echo -e "# ${COLOR_BOLD_RED}KO${COLOR_END}: actual ${COLOR_BOLD_RED}\"${actual}\"${COLOR_END}, expected ${COLOR_BOLD_RED}\"${expected}\"${COLOR_END}" >&4
    fi

    [[ "${expected}" == "${actual}" ]]
}

preserve() {
    %preserve actual status output error;
}
AfterRun preserve


Describe 'string_split_to_array'
    It 'with variable'
        str="a b c"
        When call string_split_to_array ' ' actual "$str"
        The variable actual should satisfy array_describe_equals actual "([0]='a' [1]='b' [2]='c')"
    End

    It 'with pipe and print to stdout'
        str="a b c"
        When call eval "echo $str | string_split_to_array ' '"
        The output should eq $'a\nb\nc'
    End

    It 'with token string including space'
        str="amy delimiterbmy delimiterc"
        When call string_split_to_array 'my delimiter' actual "$str"
        The variable actual should satisfy array_describe_equals actual "([0]='a' [1]='b' [2]='c')"
    End

    It 'with stdin'
        declare_heredoc lines <<-EOF
					  origin/develop
					  origin/integration
					* origin/feature/52-new-feature
				EOF
        When call string_split_to_array $'\n' actual "${lines}"
        The variable actual should satisfy array_describe_equals actual "([0]='  origin/develop' [1]='  origin/integration' [2]='* origin/feature/52-new-feature')"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					 1. A D
					 2. B
					 3. C
				EOF
        When call eval "string_split_to_array $'\n' actual < temp_file.txt"
        The variable actual should satisfy array_describe_equals actual "([0]=' 1. A D' [1]=' 2. B' [2]=' 3. C')"

        rm -fr temp_file.txt
    End
End


Describe 'string_pick_to_array'
    It 'with variable'
        str="[{age:12},{age:15},{age:16}]"
        When call string_pick_to_array '{age:' '}' actual "$str"
        The variable actual should satisfy array_describe_equals actual "([0]='12' [1]='15' [2]='16')"
    End

    It 'with pipe and print to stdout'
        str="[{age:12},{age:15},{age:16}]"
        When call eval "echo $str | string_pick_to_array '{age:' '}'"
        The output should eq $'12\n15\n16'
    End

    It 'with stdin'
        declare_heredoc lines <<-EOF
					[
					  {
					    age:12
					  },
					  {
					    age:15
					  },
					  {
					    age:16
					  }
					]
				EOF
        When call string_pick_to_array 'age:' $'\n' actual "${lines}"
        The variable actual should satisfy array_describe_equals actual "([0]='12' [1]='15' [2]='16')"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					[
					  {
					    age:12
					  },
					  {
					    age:15
					  },
					  {
					    age:16
					  }
					]
				EOF
        When call eval "string_pick_to_array 'age:' $'\n' actual < temp_file.txt"
        The variable actual should satisfy array_describe_equals actual "([0]='12' [1]='15' [2]='16')"

        rm -fr temp_file.txt
    End
End


Describe 'string_replace'
    Parameters
        "a" "b" "aaa" "bbb"
        "." "b" "a.a" "aba"
        "&" "b" "a&a" "aba"

        "/" "b" "a/a" "aba"
        "^" "b" "a^a" "aba"
        "[" "b" "a[a" "aba"

        '$' 'b' 'a$a' "aba"
        "]" "b" "a]a" "aba"
        "-" "b" "a-a" "aba"

        "+" "b" "a+a" "aba"
        "{" "b" "a{a" "aba"
        "}" "b" "a}a" "aba"

        "%" "b" "a%a" "aba"
        "!" "b" "a!a" "aba"
        "#" "b" "a#a" "aba"

        "#" "" "a#a" "aa"
        '\*\*' 'b' 'a***a' "ab*a"
        'a\*' 'b' 'a***a' "b**a"
    End

    Example "replace $1 to $2 in $3"
        When call string_replace "$1" "$2" "$3"
        The output should eq "$4"
    End
End


Describe 'escape_sed'
    It '-'
        When call escape_sed 'a$'
        The output should eq 'a\$'
    End
End


Describe 'string_replace_regex'
    Parameters
        'ad' 'b' 'aaad' "aab"
        'ac' 'b' 'acacad' "bbad"
        '\*\*' 'b' 'a***a' "ab*a"
        '\*' 'b' 'a*a' "aba"
        '\$' 'b' 'a$a' "aba"

        'a?' 'b' 'aaad' "bbbdb"
        'a+' 'b' 'aaad' "bd"
        'a*' 'b' 'aaad' "bdb"
        'a{2}' 'b' 'aaad' "bad"

        '(ac)+' 'b' 'acacad' "bad"
        '(ac)?' 'b' 'acacad' "bbabdb"
        '(ac)*' 'b' 'acacad' "babdb"
        '(ac){2}' 'b' 'acacad' "bad"

        '(ca)+' 'b' 'acacad' "abd"
        '(ca)?' 'b' 'acacad' "babbdb"
        '(ca)*' 'b' 'acacad' "babdb"
        '(ca){2}' 'b' 'acacad' "abd"

        '[ac]+' 'b' 'acacad' "bd"
        '[ac]?' 'b' 'acacad' "bbbbbdb"
        '[ac]*' 'b' 'acacad' "bdb"
        '[ac]{2}' 'b' 'acacad' "bbad"

        '[ca]+' 'b' 'acacad' "bd"
        '[ca]?' 'b' 'acacad' "bbbbbdb"
        '[ca]*' 'b' 'acacad' "bdb"
        '[ca]{2}' 'b' 'acacad' "bbad"

        '(ac){1,2}' 'b' 'acacacd' "bbd"
        '[ac]{1,2}' 'b' 'acacacd' "bbbd"

        'ac|ae' 'b' 'acaed' "bbd"
        '(ac|ae)' 'b' 'acaed' "bbd"
        '(ac|ae){1}' 'b' 'acaed' "bbd"
        '(ac|ae){1,}' 'b' 'acaed' "bd"
        '(ac|ae)+' 'b' 'acaed' "bd"

        '\s+' '' 'a   b' "ab"
        '^\s+' '' '   a   b' "a   b"
    End

    Example "replace $1 to $2 in $3"
        When call string_replace_regex "$1" "$2" "$3"
        The output should eq "$4"
    End
End


Describe 'string_trim'
    It 'with value'
        When call string_trim " as fd "
        The output should eq "as fd"
    End

    It 'with pipe'
        When call eval "echo ' add ' | string_trim"
        The output should eq "add"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					  A D
					  B
					  C
				EOF
        When call eval "string_trim < temp_file.txt"
        The output should eq "A D
B
C"
        The output should eq $'A D\nB\nC'
        rm -fr temp_file.txt
    End
End


Describe 'string_repeat'
    It 'with value'
        When call string_repeat "ab" 3
        The output should eq "ababab"
    End

    It 'with pipe'
        When call eval "echo 3 | string_repeat 'ab'"
        The output should eq "ababab"
    End
End


Describe 'string_length'
    It 'with value'
        When call string_length " as fd "
        The output should eq "7"
    End

    It 'with pipe'
        When call eval "echo ' add ' | string_length"
        The output should eq "5"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					  A D
					  B
					  C
				EOF
        When call eval "string_length < temp_file.txt"
        The output should eq "13"
        rm -fr temp_file.txt
    End
End


Describe 'string_is_empty'
    It 'with value'
        When call string_is_empty " as fd "
        The status should eq "1"
    End

    It 'with empty'
        When call eval "echo '' | string_is_empty"
        The status should eq "0"
    End

    It 'with pipe'
        When call eval "echo ' add ' | string_is_empty"
        The status should eq "1"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					  A D
					  B
					  C
				EOF
        When call eval "string_is_empty < temp_file.txt"
        The status should eq "1"
        rm -fr temp_file.txt
    End
End


Describe 'string_revert'
    It 'with value'
        When call string_revert " as fd "
        The output should eq " df sa "
    End

    It 'with empty'
        When call eval "echo '' | string_revert"
        The output should eq ""
    End

    It 'with pipe'
        When call eval "echo ' add ' | string_revert"
        The output should eq " dda "
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					  A D
					  B
					  C
				EOF
        When call eval "string_revert < temp_file.txt"
        The output should eq $'D A  \nB  \nC  '
        rm -fr temp_file.txt
    End
End


Describe 'string_upper'
    It 'with value'
        When call string_upper "aBc"
        The output should eq "ABC"
    End

    It 'with empty'
        When call eval "echo '' | string_upper"
        The output should eq ""
    End

    It 'with pipe'
        When call eval "echo 'aBc' | string_upper"
        The output should eq "ABC"
    End
End


Describe 'string_lower'
    It 'with value'
        When call string_lower "aBc"
        The output should eq "abc"
    End

    It 'with empty'
        When call eval "echo '' | string_lower"
        The output should eq ""
    End

    It 'with pipe'
        When call eval "echo 'aBc' | string_lower"
        The output should eq "abc"
    End
End


Describe 'string_upper_first'
    It 'with value'
        When call string_upper_first "aBc"
        The output should eq "Abc"
    End

    It 'with empty'
        When call eval "echo '' | string_upper_first"
        The output should eq ""
    End

    It 'with pipe'
        When call eval "echo 'aBc' | string_upper_first"
        The output should eq "Abc"
    End
End


Describe 'string_sub'
    It 'with value'
        When call string_sub 2 4 " as fd "
        The output should eq "s fd"
    End

    It 'negative start'
        When call string_sub -5 4 " as fd "
        The output should eq "s fd"
    End

    It 'negative length'
        When call string_sub 2 -1 " as fd "
        The output should eq "s fd"
    End

    It 'negative start & length'
        When call string_sub -5 -1 " as fd "
        The output should eq "s fd"
    End

    It 'with pipe'
        When call eval "echo ' as fd ' | string_sub 2 4"
        The output should eq "s fd"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					ABCD
					EFGH
					IJKL
				EOF
        When call eval "string_sub 3 5 < temp_file.txt"
        The output should eq $'D\nEFG'
        rm -fr temp_file.txt
    End
End


Describe 'string_before_first'
    It 'with value'
        When call string_before_first "asd" "111asd222"
        The output should eq "111"
    End

    It 'token not existed'
        When call string_before_first "abd" "111asd222"
        The output should eq "111asd222"
    End

    It 'with pipe'
        When call eval "echo ' as fd ' | string_before_first 's f'"
        The output should eq " a"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					ABCD
					EFGH
					IJKL
				EOF
        func() { actual=$(string_before_first 'FGH' < temp_file.txt); }
        When run func
        The variable actual should eq $'ABCD\nE'
        rm -fr temp_file.txt
    End
End


Describe 'string_after_first'
    It 'with value'
        When call string_after_first "asd" "111asd222"
        The output should eq "222"
    End

    It 'token not existed'
        When call string_after_first "abd" "111asd222"
        The output should eq "111asd222"
    End

    It 'with pipe'
        When call eval "echo ' as fd ' | string_after_first 's f'"
        The output should eq "d "
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					ABCD
					EFGH
					IJKL
				EOF
        func() { actual=$(string_after_first "FGH" < temp_file.txt); }
        When run func
        The variable actual should eq $'\nIJKL'
        rm -fr temp_file.txt
    End
End


Describe 'string_match'
    It 'with value'
        When call string_match 'name;+' "name;name;"
        The status should eq "0"
    End

    It 'not match'
        When call string_match 'name;+' "name2;name2;"
        The status should eq "1"
    End

    It 'with pipe'
        When call eval "echo 'name;name;' | string_match 'name;+'"
        The status should eq "0"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					name;name;
				EOF
        When call eval "string_match 'name;+' < temp_file.txt"
        The status should eq "0"
        rm -fr temp_file.txt
    End
End


Describe 'string_index_first'
    It 'start with token'
        When call string_index_first "111as" "111asd222"
        The output should eq 0
    End

    It 'token existed multi position'
        When call string_index_first "as" "111asd222as333"
        The output should eq 3
    End

    It 'with value'
        When call string_index_first "asd22" "111asd222"
        The output should eq "3"
    End

    It 'token not found'
        When call string_index_first "abd22" "111asd222"
        The output should eq "-1"
    End

    It 'with pipe'
        When call eval "echo 's as fd ' | string_index_first 's f'"
        The output should eq "3"
    End

    It 'find newline'
        When call string_index_first $'\n' $'A D\nB\nC'
        The output should eq 3
    End

    It 'with heredoc'
        declare_heredoc var <<-EOF
					AB
					CD
					EF
				EOF

        When call string_index_first $'\n' "${var}"
        The output should eq "2"
    End

    It 'with file'
        cat > temp_file.txt <<-EOF
					ABCD
					EFGH
					IJKL
				EOF
        func() { actual=$(string_index_first "FGH" < temp_file.txt); }
        When run func
        The variable actual should eq "6"
        rm -fr temp_file.txt
    End
End


Describe array_contains
    arr=("a" "b" "c" "ab" "f" "g")

    It 'found'
        When call array_contains arr "ab"
        The status should be success
    End

    It 'found pipe'
        When call eval 'echo "ab" | array_contains arr'
        The status should be success
    End

    It 'not found'
        When call array_contains arr "abc"
        The status should be failure
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

					source src/bash-base.sh

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
        When call reflect_get_function_definition args_confirm
        The status should eq "0"
        The output should include "args_confirm"
    End

    It 'test function'
        When call reflect_get_function_definition array_describe_equals
        The status should eq "0"
        The output should include "array_describe_equals"
    End
End


Describe 'reflect_function_names_of_file'
    It '-'
        When call reflect_function_names_of_file src/bash-base.sh
        The status should eq "0"
        The output should include "args_confirm"
        The lines of output should eq 53
    End
End


Describe 'reflect_function_definitions_of_file'
    It '-'
        When call reflect_function_definitions_of_file src/bash-base.sh
        The status should eq "0"
        The output should include "args_confirm() {"
    End
End


Describe 'reflect_search_function'
    It 'normal pattern'
        When call reflect_search_function args
        The status should eq "0"
        The output should include "args_confirm"
    End

    It 'regular expression pattern'
        When call reflect_search_function '^args_.*'
        The status should eq "0"
        The output should include "args_confirm"
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


Describe 'doc_lint_script_comment'
    It 'valid script'
        When call doc_lint_script_comment src/bash-base.sh
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

        When call doc_comment_to_markdown src/bash-base.sh docs/references-test.md
        The status should eq "0"
        The contents of file "docs/references.md" should include "Automatically generated by bash-base"

        rm -fr docs/references-test.md
    End
End
