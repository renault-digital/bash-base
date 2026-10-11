#!/usr/bin/env bash

# Verify Bash/zsh compatibility first, then run the historical Bash ShellSpec
# suite. Pin the test framework version across macOS and GitHub Actions.

set -u
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

bash scripts/test-shell-compat.sh || exit $?

shellspec_version=0.28.1
shellspec_dir="$HOME/.local/lib/shellspec"
shellspec_bin="$shellspec_dir/shellspec"

installed_version=''
if [[ -f "$shellspec_bin" ]]; then
	installed_version="$(bash "$shellspec_bin" --version 2>/dev/null || true)"
fi

if [[ "$installed_version" != "$shellspec_version" ]]; then
	# Existing git installations can switch versions without deleting the
	# installation directory or breaking the ~/.local/bin/shellspec link.
	if [[ -d "$shellspec_dir/.git" ]]; then
		curl -fsSL https://git.io/shellspec |
			sh -s "$shellspec_version" --switch --yes || exit $?
	elif [[ ! -e "$shellspec_dir" ]]; then
		curl -fsSL https://git.io/shellspec |
			sh -s "$shellspec_version" --yes || exit $?
	else
		printf '%s\n' \
			"ERROR: $shellspec_dir exists but is not a ShellSpec git installation." \
			'Cannot safely switch its version automatically.' >&2
		exit 1
	fi
fi

# Fail closed if installation/switching did not select the pinned version.
installed_version="$(bash "$shellspec_bin" --version 2>/dev/null || true)"
if [[ "$installed_version" != "$shellspec_version" ]]; then
	printf 'ERROR: expected ShellSpec %s, got %s\n' \
		"$shellspec_version" "${installed_version:-<not installed>}" >&2
	exit 1
fi

# Preserve the original optional Homebrew kcov setup for local macOS coverage.
# Normal `npm test` does not require kcov.
for arg in "$@"; do
	if [[ "$arg" == --kcov ]] && ! command -v kcov >/dev/null 2>&1; then
		if [[ "$(uname -s)" == Darwin ]]; then
			if ! command -v brew >/dev/null 2>&1; then
				printf '%s\n' 'ERROR: Homebrew is required to install kcov on macOS.' >&2
				exit 1
			fi
			brew install kcov || exit $?
		else
			printf '%s\n' 'ERROR: kcov is required for --kcov.' >&2
			exit 1
		fi
	fi
done

# On macOS, kcov 43 can fail to attach to ShellSpec's test executor when
# RLIMIT_NOFILE is exceptionally high (observed soft limit: 1048576). A
# temporary 256-descriptor soft limit allowed ShellSpec --kcov to complete.
# This script is executed as a child process, so the caller's limit is intact.
# Apply only when coverage is explicitly requested; normal tests are unchanged.
if [[ "$(uname -s)" == Darwin ]]; then
	for arg in "$@"; do
		if [[ "$arg" == --kcov ]]; then
			if ! ulimit -Sn 256; then
				printf '%s\n' 'ERROR: unable to set macOS kcov soft FD limit to 256.' >&2
				exit 1
			fi
			printf 'macOS kcov soft FD limit: %s\n' "$(ulimit -Sn)"
			break
		fi
	done
fi

printf 'ShellSpec version: %s\n' "$installed_version"
printf 'BASH_VERSION: %s\n' "$BASH_VERSION"

# Since ShellSpec 0.28.0, explicitly named specfiles are still filtered by
# --pattern. Our historical files are named *.spec.sh (not *_spec.sh).
# --fail-no-examples prevents an empty test run from reporting success.
bash "$shellspec_bin" --pattern '*.spec.sh' --fail-no-examples "$@" spec/*.spec.sh
