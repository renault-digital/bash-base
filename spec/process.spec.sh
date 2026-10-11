#shellcheck shell=bash

Include src/process.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe 'prc_filter_by_port'
    It 'with port number'
        nc -lk 127.0.0.1 9999 &
        listener_pid=$!
        sleep 1
        echo "=== Debug: check listener ==="
        lsof -iTCP:9999 -sTCP:LISTEN -n -P
        When call prc_filter_by_port 9999
        The status should be success
        The output should include ":9999"
        kill "$listener_pid" 2>/dev/null || true
        wait "$listener_pid" 2>/dev/null || true
    End

    It 'without port number'
        nc -l 9999 &
        listener_pid=$!
        sleep 1
        When call prc_filter_by_port
        The status should be success
        The output should include ":9999"
        kill "$listener_pid" 2>/dev/null || true
        wait "$listener_pid" 2>/dev/null || true
    End
End


# Use an owned listener and wait until it is actually listening before
# exercising the public API. Redirect all background descriptors so an
# unsuccessful kill cannot hold the command-substitution output pipe open.
prc_test_kill_listener() {
    local port="$1" signal="$2"
    local listener_pid="" supervisor_pid attempt ready=0 rc=1 pid_file

    pid_file="$(mktemp "${TMPDIR:-/tmp}/bash-base-listener.XXXXXX")" || return 1

    # A SIGKILL-ed direct background job causes Bash to write "Killed: 9"
    # on ShellSpec's stderr, even if nc itself redirects stderr. Instead,
    # the direct child is a POSIX sh supervisor that exits normally after
    # waiting for nc. Keep nc's PID to verify we are testing our listener.
    sh -c '
        nc -l "$1" </dev/null >/dev/null 2>&1 &
        child=$!
        trap "kill $child 2>/dev/null || :" 0 1 2 15
        printf "%s\n" "$child" > "$2"
        wait "$child" 2>/dev/null || :
    ' sh "$port" "$pid_file" </dev/null >/dev/null 2>&1 &
    supervisor_pid=$!

    for ((attempt = 0; attempt < 50; attempt++)); do
        if [[ -s "$pid_file" ]]; then
            IFS= read -r listener_pid < "$pid_file" || :
        fi
        if [[ -n "$listener_pid" ]] &&
           lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null | grep -qx "$listener_pid"; then
            ready=1
            break
        fi
        if ! kill -0 "$supervisor_pid" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done

    if ((ready)); then
        actual="$(prc_kill_by_port "$port" "$signal")"
        rc=$?
    else
        printf 'Test listener failed to bind on port %s\n' "$port" >&2
    fi

    # Cleanup only the processes owned by this test. Reap the normal-exiting
    # supervisor, not the signal-terminated nc child it manages.
    if [[ -n "$listener_pid" ]]; then
        kill "$listener_pid" 2>/dev/null || :
    fi
    wait "$supervisor_pid" 2>/dev/null || :
    rm -f "$pid_file"
    return "$rc"
}

Describe 'prc_kill_by_port'
    It 'signal term'
        test_port=$((22000 + RANDOM % 20000))
        func() { prc_test_kill_listener "$test_port" 15; }
        When run func
        The status should be success
        The value "${actual}" should include ":${test_port}"
        The value "${actual}" should include "Start to kill port listener by signal 15..."
    End

    It 'signal kill'
        test_port=$((22000 + RANDOM % 20000))
        func() { prc_test_kill_listener "$test_port" 9; }
        When run func
        The status should be success
        The value "${actual}" should include ":${test_port}"
        The value "${actual}" should include "Start to kill port listener by signal 9..."
    End

    It 'port not listened'
        func() {  actual=$( nc -l 9999 &  9999 ); }
        When call prc_kill_by_port 0000
        The status should be success
        The output should include "No port listener to kill"
    End
End


# The default macOS "ps" output depends on the controlling terminal.
# GitHub Actions has no such terminal, so these unit tests provide an explicit
# process table. Do not change the public functions' existing `ps` behavior.
Describe 'prc_filter_by_cmd'
    ps() {
        printf '%s\n' \
            '  PID TTY           TIME CMD' \
            '999999997 ttys001    0:00.00 /bin/bash -c fixture' \
            '999999998 ttys001    0:00.00 sleep 10'
    }

    It 'with command'
        When call prc_filter_by_cmd bash
        The status should be success
        The output should include '/bin/bash -c fixture'
        The output should not include 'sleep 10'
    End

    It 'without command'
        When call prc_filter_by_cmd
        The status should be success
        The output should include '/bin/bash -c fixture'
        The output should include 'sleep 10'
    End
End


Describe 'prc_kill_by_cmd'
    # ps emits a deterministic table; fake PIDs cannot refer to real processes.
    ps() {
        printf '%s\n' \
            '  PID TTY           TIME CMD' \
            '999999997 ttys001    0:00.00 /bin/bash -c fixture' \
            '999999998 ttys001    0:00.00 sleep 10'
    }

    # xargs invokes an external `kill`, not a shell function. Use ShellSpec's
    # command-based Mock so signals are checked without terminating processes.
    Mock kill
        printf 'MOCK_KILL:'
        printf ' <%s>' "$@"
        printf '\n'
    End

    It 'signal term'
        When call prc_kill_by_cmd sleep
        The status should be success
        The output should include 'Start to kill command by signal 15...'
        The output should include 'MOCK_KILL: <-15> <999999998>'
        The output should not include 'MOCK_KILL: <-15> <999999997>'
    End

    It 'signal kill'
        When call prc_kill_by_cmd sleep 9
        The status should be success
        The output should include 'Start to kill command by signal 9...'
        The output should include 'MOCK_KILL: <-9> <999999998>'
        The output should not include 'MOCK_KILL: <-9> <999999997>'
    End

    It 'not found command'
        When call prc_kill_by_cmd xxxx
        The status should be success
        The output should include 'No command to kill'
        The output should not include 'MOCK_KILL:'
    End
End
