#shellcheck shell=bash

array_describe_equals() {
    local arrayName="$1"
    local expected="$2"

    actual=$(array_describe "${arrayName}")

    if [[ "${expected}" != "${actual}" ]]; then
        echo -e "# ${COLOR_BOLD_RED}KO${COLOR_END}: actual ${COLOR_BOLD_RED}\"${actual}\"${COLOR_END}, expected ${COLOR_BOLD_RED}\"${expected}\"${COLOR_END}" >&4
    fi

    [[ "${expected}" == "${actual}" ]]
}




