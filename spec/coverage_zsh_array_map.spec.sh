#shellcheck shell=bash
# Target the zsh-specific array_map branch (src/array.sh:449).
# Does not change Bash semantics or existing tests.
Include src/array.sh

coverage_not_zsh_array() {
    [[ -z "${ZSH_VERSION:-}" ]]
}

coverage_map_zsh_values() {
    local -a original_values=(alpha beta)
    local -a mapped_values=()
    array_map original_values cat mapped_values || return $?
    printf '<%s>\n' "${mapped_values[@]}"
}

Describe 'zsh array_map portable input branch'
    It 'maps two elements through the zsh-specific pipeline'
        Skip if 'requires zsh' coverage_not_zsh_array
        When call coverage_map_zsh_values
        The status should eq 0
        The output should eq $'<alpha>\n<beta>'
    End
End
