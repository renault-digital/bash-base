# Bash and zsh compatibility

`bash-base` can be sourced by both Bash and zsh.

The project name and most executable examples remain Bash-oriented for backward
compatibility, but the reusable functions in `src/` are maintained within a
shared Bash/zsh contract.

## Why this matters

A sourced file is interpreted by the **current shell**. Its shebang does not
start another shell.

For example, on current macOS systems the interactive shell is normally zsh:

```text
zsh
  ↓
source ~/.bash_profile
  ↓
source bash-base
  ↓
bash-base functions execute inside zsh
```

Therefore a file named `bash-base`, or a source file beginning with
`#!/usr/bin/env bash`, can still fail when it is sourced by zsh if its function
bodies contain Bash-only constructs.

The compatibility work removes that accidental dependency while preserving the
existing Bash behavior and Bash ShellSpec regression suite.

## Supported model

The production modules covered by the shared-shell contract are:

```text
src/
  alias.sh
  argument.sh
  array.sh
  constant.sh
  document.sh
  out.sh
  process.sh
  reflection.sh
  string.sh
  tool.sh
```

Executable scripts may still deliberately use:

```bash
#!/usr/bin/env bash
```

That is separate from the requirement that the reusable `src/` library can be
**sourced** by either Bash or zsh.

## Compatibility rules

Production source should prefer the common Bash/zsh subset.

In particular:

- function declarations use `name() { ...; }`;
- prompts use `printf` plus `IFS= read -r`, not Bash `read -p` or zsh
  `read "name?prompt"`;
- output that depends on escape interpretation uses `printf` instead of
  implementation-dependent `echo -e`;
- Bash-only case conversion such as `${value^^}`, `${value,,}` and `${value^}`
  is not used;
- Bash-only indirect array expansion such as `${!array}` is not used;
- library code does not require global `shopt` or `setopt` changes;
- shell-specific introspection is isolated behind an explicit
  `BASH_VERSION`/`ZSH_VERSION` branch;
- data values are kept out of `eval` program text where practical.

## Array portability boundary

Bash and zsh do not use the same native indexed-array model. Bash normally
starts indexed arrays at 0; zsh normally starts them at 1, and sparse-array
behavior also differs.

Logical operations therefore work on ordered values rather than assuming a
particular numeric index base. This applies to operations such as:

```text
join
contains
sort
intersection
subtract
union
remove
map
filter
```

`array_describe` / `array_from_describe` intentionally use each shell's native
`typeset -p` representation. Their supported contract is:

> serialize and restore in the same shell.

The serialized Bash sparse-array text is not promised to be a portable zsh
serialization, or vice versa.

## Reflection boundary

Function and variable reflection is implemented explicitly per shell where
necessary:

```text
Bash → compgen / typeset
zsh  → functions / parameters tables
```

The shell-specific zsh parameter-expansion syntax is kept inside the zsh branch
so that the complete source still parses in Bash.

## Argument parsing and `$0`

zsh can expose a function-local value through `$0` while a shell function runs.
Where bash-base needs the original script identity, it uses `ZSH_ARGZERO` under
zsh and `$0` under Bash.

The compatibility test suite includes an actual script-level `args_parse -h`
case so rule discovery is tested in both shells, not only syntax-checked.

## Test architecture

The existing ShellSpec suite remains the authoritative **Bash regression suite**.
It protects the historical Bash behavior and coverage.

A separate compatibility gate is implemented in:

```text
scripts/test-shell-compat.sh
```

The harness itself uses Bash but launches both Bash and zsh as test targets.
That avoids requiring the test runner itself to live in the common subset.

It verifies:

- `bash -n` for every shared source module;
- `zsh -n` for every shared source module;
- absence of known shell-specific constructs that the migration removed;
- common function declaration syntax;
- runtime behavior in Bash and zsh for strings, arrays, reflection, argument
  parsing/validation, confirmations, and legacy compatibility names;
- script-level argument-rule discovery in both shells.

Run the shared-shell gate directly with:

```bash
bash scripts/test-shell-compat.sh
```

The normal local gate remains:

```bash
npm test
```

which runs:

```text
scripts/test.sh
    ↓
scripts/test-shell-compat.sh
    ├── Bash compatibility/runtime
    └── zsh compatibility/runtime
    ↓
ShellSpec
    └── existing Bash regression suite
```

## CI acceptance rule

GitHub Actions installs both Bash and zsh. A change is accepted only when both
of these layers pass:

```text
Bash/zsh compatibility gate: PASS
Bash ShellSpec regression + coverage gate: PASS
```

A syntax-only pass is not sufficient: several historical incompatibilities are
runtime differences, especially prompt handling, array indirection, case
conversion, reflection and `$0` semantics.

## Contributing

When adding or changing a public helper:

1. keep production syntax in the Bash/zsh common subset when possible;
2. if behavior genuinely differs by shell, use a small explicit shell branch;
3. add or update ShellSpec for Bash regression behavior;
4. extend `scripts/test-shell-compat.sh` when the change depends on shell
   semantics;
5. run `npm test` before committing.
