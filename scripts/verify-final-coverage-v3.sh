#!/usr/bin/env bash
# Strict local Bash 3.2 / Bash 5+ / zsh / TTY line-coverage gate.
# Read-only for src/spec. Generates isolated temporary coverage artifacts.
set -euo pipefail

root="${1:-$PWD}"
cd "$root"
root="$PWD"

for file in \
	src/document.sh src/reflection.sh \
	spec/coverage_edges.spec.sh spec/coverage_zsh_array_map.spec.sh \
	bash_base_coverage_union_v3.py bash_base_tty_probe_v3.py; do
	if [[ ! -f "$file" ]]; then
		printf 'MISSING_REQUIRED_FILE=%s\n' "$file" >&2
		exit 2
	fi
done
for tool in shellspec kcov python3 shasum; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		printf 'MISSING_TOOL=%s\n' "$tool" >&2
		exit 2
	fi
done

bash5="${BASH5:-}"
if [[ -z "$bash5" ]] && command -v brew >/dev/null 2>&1; then
	bash5="$(brew --prefix)/bin/bash"
fi
if [[ ! -x "$bash5" ]]; then
	printf 'BASH5_NOT_EXECUTABLE=%s\n' "$bash5" >&2
	exit 2
fi
if [[ ! -x /bin/zsh ]]; then
	printf 'ZSH_NOT_EXECUTABLE=/bin/zsh\n' >&2
	exit 2
fi

r="$(mktemp -d "${TMPDIR:-/tmp}/bash-base-coverage-v3.XXXXXX")"
printf 'COVERAGE_ROOT=%s\n' "$r"
printf 'BASH5_PATH=%s\n' "$bash5"
shasum -a 256 src/*.sh >"$r/source.before.sha256"

run_shellspec() {
	local label="$1" shell="$2"
	shift 2
	printf 'RUNNING=%s\n' "$label"
	if ! (
		ulimit -Sn 256 || exit 1
		shellspec --shell "$shell" --pattern '*.spec.sh' \
			--kcov --covdir "$r/$label" -f t "$@"
	) >"$r/$label.log" 2>&1; then
		printf 'FAILED=%s\n' "$label" >&2
		tail -n 50 "$r/$label.log" >&2
		exit 1
	fi
	if [[ ! -s "$r/$label/cobertura.xml" ]]; then
		printf 'MISSING_COBERTURA=%s/cobertura.xml\n' "$r/$label" >&2
		exit 1
	fi
	printf 'PASSED=%s\n' "$label"
}

run_shellspec bash32 /bin/bash spec/*.spec.sh
run_shellspec bash5 "$bash5" spec/*.spec.sh
run_shellspec zsh /bin/zsh \
	spec/string.spec.sh spec/reflection.spec.sh \
	spec/coverage_edges.spec.sh spec/coverage_zsh_array_map.spec.sh

printf 'RUNNING=tty\n'
if ! (
	ulimit -Sn 256 || exit 1
	python3 bash_base_tty_probe_v3.py --repo "$root" --shell /bin/bash \
		--preload-input --out "$r/tty"
) >"$r/tty.log" 2>&1; then
	printf 'FAILED=tty\n' >&2
	tail -n 60 "$r/tty.log" >&2
	exit 1
fi
if ! grep -q 'TTY_COVERAGE_PASS 2/2' "$r/tty.log"; then
	printf 'FAILED=tty_missing_required_hits\n' >&2
	tail -n 60 "$r/tty.log" >&2
	exit 1
fi
printf 'PASSED=tty\n'

tty_report="$(find "$r/tty" -type f -name cobertura.xml -print -quit)"
if [[ -z "$tty_report" || ! -s "$tty_report" ]]; then
	printf 'MISSING_COBERTURA=tty\n' >&2
	exit 1
fi

shasum -a 256 src/*.sh >"$r/source.after.sha256"
if ! cmp -s "$r/source.before.sha256" "$r/source.after.sha256"; then
	printf 'ERROR=source_changed_during_coverage\n' >&2
	exit 1
fi
printf 'SOURCE_SHA256_UNCHANGED=yes\n'

printf 'RUNNING=union\n'
# Three exhaustive instrumentation inventories must be identical.
# Independent PTY report may omit whole source files, but no new lines.
# A structurally valid union is exported even when it is below 100%; the command
# still fails. Invalid inputs / source changes never produce an uploadable union.
if ! python3 bash_base_coverage_union_v3.py \
	--strict-line-sets --supplemental-last 1 --require-100 --source-dir src \
	--output-cobertura "$r/union/cobertura.xml" \
	"$r/bash32/cobertura.xml" "$r/bash5/cobertura.xml" \
	"$r/zsh/cobertura.xml" "$tty_report" \
	>"$r/union.log" 2>&1; then
	printf 'FAILED=union_or_coverage_gate\n' >&2
	tail -n 80 "$r/union.log" >&2
	exit 1
fi
cat "$r/union.log"
