Describe 'login-shell invocation metadata'
  login_shell_script_name() {
    login_name="$1"
    shell_path="$2"

    /bin/bash -c '
      login_name="$1"
      shell_path="$2"
      exec -a "$login_name" "$shell_path" -c '"'"'
        source src/argument.sh
        printf "%s\n" "$THIS_SCRIPT_NAME"
      '"'"'
    ' _ "$login_name" "$shell_path"
  }

  It 'normalizes Bash login argv[0]'
    When call login_shell_script_name -bash /bin/bash
    The status should be success
    The output should equal 'bash'
    The error should equal ''
  End

  It 'normalizes zsh login argv[0]'
    zsh_path="$(command -v zsh)"
    When call login_shell_script_name -zsh "$zsh_path"
    The status should be success
    The output should equal 'zsh'
    The error should equal ''
  End
End
