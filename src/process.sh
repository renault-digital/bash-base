#!/usr/bin/env bash

# @NAME
#     prc_filter_by_port -- list the process with port listened, not with sudo
# @SYNOPSIS
#     prc_filter_by_port [port]
# @DESCRIPTION
#     **[port]** optional, the port number, if absent, all process with port listened will be printed
# @EXAMPLES
#     prc_filter_by_port 9090
# @SEE_ALSO
#     prc_kill_by_port
function prc_filter_by_port() {
	if [ $# -eq 0 ]; then
		lsof -iTCP -sTCP:LISTEN -n -P
	elif [ $# -eq 1 ]; then
		lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color "$1"
	fi
}

# @NAME
#     prc_kill_by_port -- kill the process who listening on the specific port, not with sudo
# @SYNOPSIS
#     prc_kill_by_port port
# @DESCRIPTION
#     **port** the port number
# @EXAMPLES
#     prc_kill_by_port 9090
# @SEE_ALSO
#     prc_filter_by_port
function prc_kill_by_port() {
	if [ $# -eq 1 ]; then
		lsof -iTCP:"$1" -sTCP:LISTEN -n -P
		if [[ "$?" -eq 0 ]]; then
			echo "Start to kill port listener..."
			lsof -iTCP:"$1" -sTCP:LISTEN -n -P -t | xargs kill -9
		else
			echo "No port listener to kill."
		fi
	fi
}

# @NAME
#     prc_filter_by_cmd -- print out the proccess with the filter of command and its arguments, not with sudo
# @SYNOPSIS
#     prc_filter_by_cmd [command]
# @DESCRIPTION
#     **[command]** optional, the token of command or arguments, if absent, all process will be printed
# @EXAMPLES
#     prc_filter_by_cmd node
# @SEE_ALSO
#     prc_kill_by_cmd
function prc_filter_by_cmd() {
	if [ $# -eq 0 ]; then
		ps
	elif [ $# -eq 1 ]; then
		ps | awk '{ result=$0; $1=$2=$3=""; if ($4 != "awk" && $0 ~ /'"$1"'/) { print result } }'
	fi
}

# @NAME
#     prc_kill_by_cmd -- search the process by the command and arguments, and kill it, not with sudo
# @SYNOPSIS
#     prc_kill_by_cmd command
# @DESCRIPTION
#     **command** the token
# @EXAMPLES
#     prc_kill_by_cmd my-app
# @SEE_ALSO
#     prc_filter_by_cmd
function prc_kill_by_cmd() {
	if [ $# -eq 1 ]; then
		ps | tail -n +2 | awk '{ result=$0; $1=$2=$3=""; if ($4 != "awk" && $0 ~ /'"$1"'/) { print result; rc = 1 } }; END { exit !rc }'
		if [[ "$?" -eq 0 ]]; then
			echo "Start to kill command..."
			ps | tail -n +2 | awk '{ result=$1; $1=$2=$3=""; if ($4 != "awk" && $0 ~ /'"$1"'/) { print result } }' | sort -u | xargs kill -9
		else
			echo "No command to kill."
		fi
	fi
}
