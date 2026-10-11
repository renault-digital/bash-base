#!/usr/bin/env bash
set -u

ROOT="${BASH_BASE_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ALLOW_NO_ZSH="${ALLOW_NO_ZSH:-0}"

pass=0
fail=0

ok() {
	printf 'PASS  %s\n' "$1"
	pass=$((pass + 1))
}
bad() {
	printf 'FAIL  %s\n' "$1" >&2
	fail=$((fail + 1))
}

printf 'Bash/zsh bash-base compatibility tests\n'
printf 'Root: %s\n\n' "$ROOT"

src_files=(
	alias.sh argument.sh array.sh constant.sh document.sh
	out.sh process.sh reflection.sh string.sh tool.sh
)

for f in "${src_files[@]}"; do
	if bash -n "$ROOT/src/$f"; then
		ok "bash syntax: $f"
	else
		bad "bash syntax: $f"
	fi
done

if command -v zsh >/dev/null 2>&1; then
	for f in "${src_files[@]}"; do
		if zsh -n "$ROOT/src/$f"; then
			ok "zsh syntax: $f"
		else
			bad "zsh syntax: $f"
		fi
	done
else
	if [[ "$ALLOW_NO_ZSH" == 1 ]]; then
		printf 'SKIP  zsh syntax/runtime checks (zsh unavailable)\n'
	else
		bad "zsh is required for shared-shell verification"
	fi
fi

# Source-level guards for constructs intentionally removed from the shared code.
# Comments are stripped before matching so explanatory text does not trigger.
active="$({
	for f in "${src_files[@]}"; do
		sed -E '/^[[:space:]]*#/d' "$ROOT/src/$f"
	done
} 2>/dev/null)"

static_bad=0
for pattern in \
	'read[[:space:]].*-p' \
	'\$\{[^}]*\^\^\}' \
	'\$\{[^}]*,,\}' \
	'\$\{[^}]*\^\}' \
	'\$\{![^}]+\}' \
	'(^|[[:space:]])declare[[:space:]]+-' \
	'export[[:space:]]+-f' \
	'(^|[[:space:]])shopt([[:space:]]|$)' \
	'(^|[[:space:]])setopt([[:space:]]|$)' \
	'(^|[[:space:]])\[[[:space:]].*[[:space:]]==[[:space:]]'
do
	if printf '%s\n' "$active" | grep -Eq "$pattern"; then
		printf 'Static forbidden pattern matched: %s\n' "$pattern" >&2
		static_bad=1
	fi
done

if ((static_bad == 0)); then
	ok "no known Bash-only/zsh-only constructs in active library code"
else
	bad "shared-syntax static scan"
fi

# Function declarations should use the common name() form.
if grep -RInE '^[[:space:]]*function[[:space:]]+' "$ROOT/src" >/dev/null 2>&1; then
	bad "function keyword remains in active source declarations"
else
	ok "common function declaration syntax"
fi

runtime_payload="$(mktemp "${TMPDIR:-/tmp}/bash-base-runtime.XXXXXX")" || exit 1
trap 'rm -f "$runtime_payload"' EXIT INT TERM HUP
cat >"$runtime_payload" <<'PAYLOAD'
set -u
root="$1"
cd "$root"

source src/constant.sh
source src/out.sh
source src/tool.sh
source src/string.sh
source src/array.sh
source src/reflection.sh
source src/argument.sh
source src/process.sh
source src/document.sh
source src/alias.sh

expected_script_name="${0##*/}"

runtime_failures=0
assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$actual" != "$expected" ]]; then
        printf 'ASSERT FAIL [%s]\nexpected: <%s>\nactual:   <%s>\n' "$name" "$expected" "$actual" >&2
        runtime_failures=$((runtime_failures + 1))
        return 1
    fi
}

assert_status() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$actual" != "$expected" ]]; then
        printf 'ASSERT FAIL [%s] expected status %s got %s\n' "$name" "$expected" "$actual" >&2
        runtime_failures=$((runtime_failures + 1))
        return 1
    fi
}

assert_eq script_name "$expected_script_name" "$THIS_SCRIPT_NAME"
assert_eq upper ABC "$(string_upper aBc)"
assert_eq lower abc "$(string_lower aBc)"
assert_eq upper_first Abc "$(string_upper_first aBc)"
assert_eq substring 's fd' "$(string_sub 2 -1 ' as fd ')"
assert_eq substring_negative_start 'fd' "$(string_sub -3 -1 ' as fd ')"
assert_eq substring_empty '' "$(string_sub 0 0 'abc')"
assert_eq substring_out_of_range '' "$(string_sub -99 -1 'abc')"

# The heredoc may contain shell quotes and command syntax as plain text.
declare_heredoc literal_heredoc <<'LITERAL_HEREDOC'
It's text: $(printf NEVER_EXECUTE); "quoted".
LITERAL_HEREDOC
assert_eq literal_heredoc 'It'"'"'s text: $(printf NEVER_EXECUTE); "quoted".' "$literal_heredoc"

arr=(' a ' ' b c ')
assert_eq array_join ' a | b c ' "$(array_join '|' arr)"
array_contains arr ' b c '
assert_status array_contains 0 "$?"

arr_sort=('bb' 'aa' 'aa')
array_sort arr_sort
assert_eq array_sort 'aa|aa|bb' "$(array_join '|' arr_sort)"

array_equal_a=('bb' 'aa')
array_equal_b=('aa' 'bb')
array_equals array_equal_a array_equal_b true
assert_status array_equals 0 "$?"

left=('aa' 'bb' 'aa' 'cc')
right=('aa' 'aa' 'dd' 'bb')
array_union left right union_result
assert_eq array_union 'aa|bb|cc|dd' "$(array_join '|' union_result)"

remove_arr=('a' ' b' 'c' 'a b' 'f' 'g')
array_remove remove_arr 'a b'
assert_eq array_remove 'a| b|c|f|g' "$(array_join '|' remove_arr)"

map_arr=(' a ' " b '(c ")
array_map map_arr 'string_trim | wc -m | string_trim' mapped
assert_eq array_map '2|6' "$(array_join '|' mapped)"

filter_arr=('NAME' 'NAME B' 'OTHER')
array_filter filter_arr 'NAME' filtered
assert_eq array_filter 'NAME|NAME B' "$(array_join '|' filtered)"

# array_describe/array_from_describe use each shell's own declaration format;
# round-trip behavior, not declaration spelling, is the cross-shell contract.
desc="$(array_describe arr)"
array_from_describe roundtrip "$desc"
assert_eq array_roundtrip ' a | b c ' "$(array_join '|' roundtrip)"

# Bash regression: public array-by-name APIs must not shadow legitimate names.
values=('a' 'b')
assert_eq name_values_join 'a|b' "$(array_join '|' values)"
array_contains values b
assert_status name_values_contains 0 "$?"
array_map values string_upper mapped_values
assert_eq name_values_map 'A|B' "$(array_join '|' mapped_values)"
array_filter values a filtered_values
assert_eq name_values_filter 'a' "$(array_join '|' filtered_values)"
source=('a' 'b')
other=('b')
array_intersection source other inter false
assert_eq name_source_intersection 'b' "$(array_join '|' inter)"
array_subtract source other subtracted false
assert_eq name_source_subtract 'a' "$(array_join '|' subtracted)"
source1=('a')
array_union source1 other combined false
assert_eq name_source1_union 'a|b' "$(array_join '|' combined)"
source2=('b')
left_also=('a')
array_union left_also source2 combined false
assert_eq name_source2_union 'a|b' "$(array_join '|' combined)"
kept=(a b c)
array_remove kept b
assert_eq name_kept_remove 'a|c' "$(array_join '|' kept)"

# Exercise the historical Bash 3.2 `typeset -p` format even on newer
# Bash runners. Only the mocked builtin call is scoped to this subshell.
if [[ -n "${BASH_VERSION:-}" ]]; then
    legacy_roundtrip="$(
        typeset() {
            if [[ "${1-}" == -p && "${2-}" == arr ]]; then
                printf '%s\n' "declare -a arr='([0]=\" a \" [1]=\" b c \")'"
            else
                builtin typeset "$@"
            fi
        }
        legacy_desc="$(array_describe arr)"
        array_from_describe legacy_restored "$legacy_desc" || exit 1
        array_join '|' legacy_restored
    )"
    assert_eq array_legacy_bash32_roundtrip ' a | b c ' "$legacy_roundtrip"
fi

assert_eq reflect_nth_arg 'ha ho' "$(reflect_nth_arg 3 'ab cdv "ha ho"')"
assert_eq reflect_nth_arg_complex 'SIA (lowercase, 3 chars)' "$(reflect_nth_arg 4 'args_valid_or_read myVar '\''^[0-9a-z]{3,3}$'\'' "SIA (lowercase, 3 chars)"')"
reflect_get_function_definition reflect_nth_arg >/dev/null
reflect_search_function '^reflect_nth_arg$' | grep -qx 'reflect_nth_arg'
reflect_search_variable '^COLOR_BLUE$' | grep -qx 'COLOR_BLUE'

set -- "param 1" "param 2"
args_parse $# "$@" var1 var2
assert_eq args_parse_var1 'param 1' "$var1"
assert_eq args_parse_var2 'param 2' "$var2"

positionalValue='OLD'
args_parse 1 X positionalValue
assert_eq args_parse_shadow_positionalValue X "$positionalValue"
prompt='OLD'
args_parse 1 Y prompt
assert_eq args_parse_shadow_prompt Y "$prompt"

if [[ -n "${BASH_VERSION:-}" ]]; then
    # Legacy Bash output and implicit shell-state behavior; zsh uses its own semantics.
    assert_eq reflect_zero 0 "$(reflect_nth_arg 0 'a b c')"
    assert_eq reflect_oob '' "$(set +u; reflect_nth_arg 99 'a b c')"
    mapped_input=('-n' 'b')
    array_map mapped_input cat mapped_output
    assert_eq map_legacy_echo '|'"b" "$(array_join '|' mapped_output)"
    display_name='  abc  '
    expected_display="$(printf '%-30.30s%s' 'display_name:' "${COLOR_BLUE}abc${COLOR_END}")"
    assert_eq print_args_legacy_spaces "$expected_display" "$(print_args display_name)"
    default_name='  abc  '
    args_valid_or_default default_name '^.*abc.*$' desc >/dev/null
    assert_eq args_default_legacy_spaces abc "$default_name"
    read_out="$(printf '  abc  \n' | args_valid_or_read read_name '^.+$' 'enter')"
    assert_eq args_read_legacy_spaces "Inputted value: ${COLOR_BLUE}'abc'${COLOR_END}" "$read_out"
    proposed_out="$(args_valid_or_read proposed_name '^.+$' 'enter' '  foo  ' <<<'')"
    assert_eq args_read_legacy_proposed "Inputted value: ${COLOR_BLUE}'foo'${COLOR_END}" "$proposed_out"
    default_name=''
    fallback_out="$(args_valid_or_default default_name '^.+$' desc 'a   b')"
    if [[ "$fallback_out" != *"Inputted value: ${COLOR_BLUE}'a b'${COLOR_END}"* ]]; then
        printf 'ASSERT FAIL [args_default_legacy_fallback] %s\n' "$fallback_out" >&2
        runtime_failures=$((runtime_failures + 1))
    fi
    # Bash 4+/5+ case conversion must use native locale-sensitive rules.
    if ((BASH_VERSINFO[0] >= 4)); then
        utf8_locale="$(locale -a 2>/dev/null | grep -Ei -m1 '^(en_US\.UTF-8|C\.utf-?8|fr_FR\.UTF-8)$' || :)"
        if [[ -n "$utf8_locale" ]]; then
            original_upper="$(LC_ALL="$utf8_locale" bash -c 'v=école; echo "${v^^}"')"
            if [[ "$original_upper" == 'ÉCOLE' ]]; then
                assert_eq upper_legacy_unicode ÉCOLE "$(LC_ALL="$utf8_locale" string_upper école)"
                assert_eq lower_legacy_unicode école "$(LC_ALL="$utf8_locale" string_lower ÉCOLE)"
                assert_eq first_legacy_unicode École "$(LC_ALL="$utf8_locale" string_upper_first éCOLE)"
            fi
        fi
    fi
fi

# read -r must use default IFS so Bash continues to accept spaced confirmations.
modeQuiet=false
spaced_yes="$(printf '  y  \n' | confirm_to_continue)"
assert_eq confirm_spaced_yes 'Continue...' "$spaced_yes"

sel='abc'
select_out="$(printf '%s\n' 2 | args_valid_or_select_args sel 'which value' a ab d | grep 'Selected value')"
assert_eq args_select "Selected value: ${COLOR_BLUE}'ab'${COLOR_END}" "$select_out"

modeQuiet=false
read_out="$(printf '%s\n' 70022 | args_valid_or_read irn '^[0-9]{5,5}$' 'IRN')"
assert_eq args_valid_or_read "Inputted value: ${COLOR_BLUE}'70022'${COLOR_END}" "$read_out"

irn=70033
default_out="$(args_valid_or_default irn '^[0-9]{5,5}$' 'IRN' 70088)"
assert_eq args_valid_or_default "Inputted value: ${COLOR_BLUE}'70033'${COLOR_END}" "$default_out"
assert_eq args_valid_or_default_value 70033 "$irn"

modeQuiet=true
quiet_out="$(confirm_to_continue)"
assert_eq confirm_quiet '' "$quiet_out"

modeQuiet=false
yes_out="$(printf '%s\n' y | confirm_to_continue)"
assert_eq confirm_yes 'Continue...' "$yes_out"

# Legacy names intentionally remain callable, but are wrapper functions rather
# than shell aliases so non-interactive Bash/zsh behavior is deterministic.
modeQuiet=true
assert_eq args_confirm '' "$(args_confirm)"
var1='value 1'
assert_eq args_print "var1:                         ${COLOR_BLUE}value 1${COLOR_END}" "$(args_print var1)"

# Both old and new function declaration styles must remain discoverable.
cat > "${TMPDIR:-/tmp}/bash-base-reflect-test.$$" <<'EOS'
old_style() { :; }
function legacy_style() { :; }
EOS
names="$(reflect_function_names_of_file "${TMPDIR:-/tmp}/bash-base-reflect-test.$$")"
rm -f "${TMPDIR:-/tmp}/bash-base-reflect-test.$$"
printf '%s\n' "$names" | grep -qx old_style
printf '%s\n' "$names" | grep -qx legacy_style

if ((runtime_failures > 0)); then
    printf 'RUNTIME ASSERTIONS FAILED: %s\n' "$runtime_failures" >&2
    exit 1
fi
printf 'RUNTIME PASS\n'
PAYLOAD

run_runtime() {
	local shell_name="$1" shell_bin="$2"
	local output rc
	output="$($shell_bin "$runtime_payload" "$ROOT" 2>&1)"
	rc=$?
	if [[ $rc -eq 0 && "$output" == *'RUNTIME PASS'* ]]; then
		ok "$shell_name runtime behavior"
	else
		bad "$shell_name runtime behavior"
		printf '%s\n' "$output" >&2
	fi
}

run_runtime Bash bash
if command -v zsh >/dev/null 2>&1; then
	run_runtime zsh zsh
fi

# args_parse scans the caller script for args_valid_* rules. In zsh, function
# execution can change $0, so exercise this through a real script rather than
# only calling args_parse from the smoke-test function body.
metadata_script="$(mktemp "${TMPDIR:-/tmp}/bash-base-args-metadata.XXXXXX")" || exit 1
cat >"$metadata_script" <<'META'
root="$1"
shift
cd "$root" || exit 1
source src/constant.sh
source src/out.sh
source src/tool.sh
source src/string.sh
source src/array.sh
source src/reflection.sh
source src/argument.sh
args_parse $# "$@" destination region
args_valid_or_read destination '^ok$' 'validated destination'
META

run_metadata_test() {
	local shell_name="$1" shell_bin="$2"
	local output rc
	output="$($shell_bin "$metadata_script" "$ROOT" -h 2>&1)"
	rc=$?
	if [[ $rc -eq 0 &&
		"$output" == *'validated destination'* &&
		"$output" == *'"destinationValue" "regionValue"'* &&
		"$output" != *'destinationValue\" \"regionValue'* ]]; then
		ok "$shell_name args_parse caller-script metadata/help rendering"
	else
		bad "$shell_name args_parse caller-script metadata/help rendering"
		printf '%s\n' "$output" >&2
	fi
}

run_metadata_test Bash bash
if command -v zsh >/dev/null 2>&1; then
	run_metadata_test zsh zsh
fi
rm -f "$metadata_script"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
((fail == 0))
