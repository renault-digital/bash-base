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





# Compare ordered array values across Bash and zsh without assuming native
# indexed-array numbering or typeset/declare output formatting.
array_values_equal() {
    local array_name="$1"
    shift
    local -a __bb_test_values
    local element

    eval "__bb_test_values=( \"\${${array_name}[@]}\" )" || return 1
    [[ ${#__bb_test_values[@]} -eq $# ]] || return 1
    for element in "${__bb_test_values[@]}"; do
        [[ "$element" == "$1" ]] || return 1
        shift
    done
    return 0
}
