#shellcheck shell=bash

Include src/string.sh
Include src/array.sh

preserve() { %preserve actual status output error; }
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

        '[ ]+' '' 'a   b' "ab"
        '^[ ]+' '' '   a   b' "a   b"
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
