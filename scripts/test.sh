#!/usr/bin/env bash

# use this script to check if bash-base is compatible with your bash and environment

docker run --rm -v "$(pwd)":/bash-base -w /bash-base shellspec/shellspec:0.27-kcov "$@" spec/*.spec.sh
