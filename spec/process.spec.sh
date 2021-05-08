#shellcheck shell=bash

Include src/process.sh

preserve() { %preserve actual status output error; }
AfterRun preserve


Describe 'prc_filter_by_port'
    It 'with port number'
        nc -l 9999 &
        When call prc_filter_by_port 9999
        The status should be success
        The output should include ":9999"
        kill $(lsof -iTCP:9999 -sTCP:LISTEN -n -P -t)
    End

    It 'without port number'
        nc -l 9999 &
        When call prc_filter_by_port
        The status should be success
        The output should include ":9999"
        kill $(lsof -iTCP:9999 -sTCP:LISTEN -n -P -t)
    End
End


Describe 'prc_kill_by_port'
    It '-'
        func() {  actual=$( nc -l 9999 & prc_kill_by_port 9999 ); }
        When run func
        The status should be success
        The value "${actual}" should include ":9999"
    End

    It 'port not listened'
        func() {  actual=$( nc -l 9999 &  9999 ); }
        When call prc_kill_by_port 0000
        The status should be success
        The output should include "No port listener to kill"
    End
End


Describe 'prc_filter_by_cmd'
    It 'with command'
        When call prc_filter_by_cmd bash
        The status should be success
        The output should include "bash"
    End

    It 'without command'
        When call prc_filter_by_cmd
        The status should be success
        The output should include "bash"
    End
End


Describe 'prc_kill_by_cmd'
    It '-'
        func() {  actual=$( sleep 10 & prc_kill_by_cmd sleep); }
        When run func
        The status should be success
        The value "${actual}" should include "sleep"
    End

    It 'not found command'
        When call prc_kill_by_cmd xxxx
        The status should be success
        The output should include "No command to kill"
    End
End
