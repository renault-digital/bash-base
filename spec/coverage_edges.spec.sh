#shellcheck shell=bash
# Targeted coverage/regression tests for reachable Bash/zsh edge cases.
# Keep the Bash legacy behavior for reflect_nth_arg unchanged.

Include src/string.sh
Include src/reflection.sh
Include src/argument.sh

coverage_not_zsh() {
    [[ -z "${ZSH_VERSION:-}" ]]
}

coverage_bash_4_or_later() {
    [[ -n "${BASH_VERSION:-}" ]] && (( BASH_VERSINFO[0] >= 4 ))
}

coverage_source_argument() {
    . src/argument.sh
    [[ -n "${THIS_SCRIPT_PATH:-}" && -n "${THIS_SCRIPT_NAME:-}" ]]
}

Describe 'coverage edge branches with observable behavior'
    It 'zsh rejects a nonnumeric reflect_nth_arg index'
        Skip if 'zsh-specific return status' coverage_not_zsh
        When call reflect_nth_arg invalid alpha beta
        The status should eq 1
        The output should eq ''
    End

    It 'zsh rejects an out-of-range reflect_nth_arg index'
        Skip if 'zsh-specific return status' coverage_not_zsh
        When call reflect_nth_arg 99 alpha beta
        The status should eq 1
        The output should eq ''
    End

    It 'returns empty output for an out-of-range substring start'
        When call string_sub 99 1 abc
        The status should eq 0
        The output should eq ''
    End

    It 'rejects an invalid negative substring length on the portable path'
        # Bash 4+ follows native substring expansion semantics and can abort
        # the calling shell on an invalid negative length. This test targets
        # only the Bash 3.2 / zsh portable fallback, and must not change Bash 4+.
        Skip if 'Bash 4+ uses native substring expansion' coverage_bash_4_or_later
        When call string_sub 2 -20 abc
        The status should eq 1
        The output should eq ''
    End

    It 'reports a valid value without an eval or pipe test wrapper'
        coverage_read_value='12345'
        When call args_valid_or_read coverage_read_value '^12345$' 'IRN'
        The status should eq 0
        The variable coverage_read_value should eq '12345'
        The output should include 'Inputted value:'
    End

    It 'reports a defaulted value without an eval or pipe test wrapper'
        coverage_default_value=''
        When call args_valid_or_default coverage_default_value '^valid$' 'Value' valid
        The status should eq 0
        The variable coverage_default_value should eq 'valid'
        The output should include 'Inputted value:'
    End

    It 'prints an explicit placeholder for an empty variable'
        LOG_LEVEL=$LOG_LEVEL_WARN
        empty_for_coverage=''
        When call print_args empty_for_coverage
        The status should eq 0
        The output should include '<EMPTY>'
    End

    It 'rejects a heredoc target that is not a shell identifier'
        When call declare_heredoc 'invalid-name'
        The status should eq 2
        The output should eq ''
    End

    It 'uses the zsh-specific entry path when argument.sh is sourced'
        Skip if 'zsh-only source branch' coverage_not_zsh
        When call coverage_source_argument
        The status should eq 0
    End
End
