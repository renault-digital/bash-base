#!/usr/bin/env bash

# use this script to check if bash-base is compatible with your bash and environment

docker run -it --rm -v "$(pwd)":/bash-base -w /bash-base shellspec/shellspec:master-kcov "$@" spec/*.spec.sh
