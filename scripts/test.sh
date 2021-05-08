#!/usr/bin/env bash

# use this script to check if bash-base is compatible with your bash and environment

# Mac OSX
if ! [ -f "$HOME"/.local/lib/shellspec/shellspec ]; then
	brew install kcov
	curl -fsSL https://git.io/shellspec | sh -s 0.27.2 --yes
fi
bash -c 'echo BASH_VERSION: $BASH_VERSION'
bash "$HOME"/.local/lib/shellspec/shellspec "$@" spec/*.spec.sh

# Uninstall shellspec:
# rm -fr $HOME/.local/bin/shellspec
# rm -fr $HOME/.local/lib/shellspec

# Debian
#docker run --rm -v "$(pwd)":/bash-base -w /bash-base shellspec/shellspec-debian:0.27-kcov "$@" spec/*.spec.sh

# Alpine
#docker run --rm -v "$(pwd)":/bash-base -w /bash-base shellspec/shellspec:0.27-kcov "$@" spec/*.spec.sh
