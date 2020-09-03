#!/usr/bin/env bash

# use this script to check if bash-base is compatible with your version of bash and your environment

docker run -it --rm -v "$(pwd)":/bash-base -w /bash-base shellspec/shellspec:master-kcov --shell bash spec/*.sh
