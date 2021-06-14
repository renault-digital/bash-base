#shellcheck shell=bash

Include src/array.sh
Include src/tool.sh
Include src/string.sh
Include src/reflection.sh
Include src/argument.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe integ_test

    It 'run script'
        cat <<-EOF > my_script.sh
					#!/usr/bin/env bash

					source src/array.sh
					source src/tool.sh
					source src/string.sh
					source src/reflection.sh
					source src/argument.sh

					# customize the short description of default help usage
					SHORT_DESC='an example shell script to show how to use bash-base '

					print_header "collect information"
					args_parse \$# "\$@" firstName lastName age sex country nationality

					args_valid_or_read firstName '^[A-Za-z ]{2,}$' "Your first name (only letters)"
					args_valid_or_read lastName '^[A-Za-z ]{2,}$' "Your last name (only letters)"
					args_valid_or_read age '^[0-9]{1,2}$' "Your age (maxim 2 digits))"
					args_valid_or_select_pipe sex 'man|woman' "Your sex"
					args_valid_or_select_args country "Which country" France USA
					args_valid_or_default nationality '^[A-Za-z ]{1,}$' "Your nationality" French

					confirm_to_continue firstName lastName age sex country nationality

					print_header "say hello"
					cat <<-EOF2
					  Hello \$(string_upper_first "\${firstName}") \$(string_upper "\${lastName}"),
					  nice to meet you, you are really \${nationality}
					EOF2
				EOF
        chmod +x my_script.sh

        expected=$(cat <<-EOF
					${COLOR_BOLD_MAGENTA}
					### collect information ${COLOR_END}
					Inputted value: ${COLOR_BLUE}'First'${COLOR_END}
					Inputted value: ${COLOR_BLUE}'LAST'${COLOR_END}
					Inputted value: ${COLOR_BLUE}'22'${COLOR_END}
					Selected value: ${COLOR_BLUE}'woman'${COLOR_END}
					Selected value: ${COLOR_BLUE}'USA'${COLOR_END}
					Inputted value: ${COLOR_BLUE}'American'${COLOR_END}
					firstName:                    ${COLOR_BLUE}First${COLOR_END}
					lastName:                     ${COLOR_BLUE}LAST${COLOR_END}
					age:                          ${COLOR_BLUE}22${COLOR_END}
					sex:                          ${COLOR_BLUE}woman${COLOR_END}
					country:                      ${COLOR_BLUE}USA${COLOR_END}
					nationality:                  ${COLOR_BLUE}American${COLOR_END}
					${COLOR_BOLD_MAGENTA}
					### say hello ${COLOR_END}
					  Hello First LAST,
					  nice to meet you, you are really American
				EOF
				)

        export nationality=American
        When run script my_script.sh -q First LAST 22 woman USA
        The status should be success
        The output should eq "$expected"

        rm -fr my_script.sh
    End

End
