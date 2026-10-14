# Welcome to [bash-base](https://renault-digital.github.io/bash-base)

[![License](https://img.shields.io/github/license/renault-digital/bash-base.svg)](https://github.com/renault-digital/bash-base/blob/master/LICENSE)
[![GitHub top language](https://img.shields.io/github/languages/top/renault-digital/bash-base.svg)](https://github.com/renault-digital/bash-base/search?l=Shell)
[![codecov](https://codecov.io/gh/renault-digital/bash-base/branch/master/graph/badge.svg)](https://codecov.io/gh/renault-digital/bash-base)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/renault-digital/bash-base/cicd.yml?branch=master&event=push&label=GitHub%20Actions)](https://github.com/renault-digital/bash-base/actions/workflows/cicd.yml)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![GitHub release](https://img.shields.io/github/release/renault-digital/bash-base.svg)](https://github.com/renault-digital/bash-base/releases/latest)
[![npm package](https://img.shields.io/npm/v/@renault-digital/bash-base.svg)](https://www.npmjs.com/package/@renault-digital/bash-base)
[![Docker Cloud Build Status](https://img.shields.io/docker/pulls/renaultdigital/bash-base.svg)](https://hub.docker.com/r/renaultdigital/bash-base)
![GitHub commits since latest release](https://img.shields.io/github/commits-since/renault-digital/bash-base/latest)


## Goal

**Reusable Bash/zsh utilities for reliable command composition and automation.**

Bash-base helps developers focus on what their shell scripts do, rather than
repeatedly researching how every low-level operation should work.

Its starting point is a recurring cost: searching for a Shell implementation,
comparing alternatives, experimenting with edge cases, and testing the result
across supported environments. Saving a few lines is useful; avoiding that
repeated implementation and verification work is the more important goal.

Bash-base provides reusable, tested functions for expressing command-oriented
logic through higher-level APIs. String and array operations support this goal:
organizing command arguments, transforming outputs, and expressing automation
logic. They are means to compose commands, not an attempt to build a complete
general-purpose application framework in Shell.

### Design priorities

- **Pain-driven:** address recurring scripting problems, not a target number of
  functions.
- **Contract-driven:** make inputs, outputs, exit statuses and side effects
  explicit, with interfaces that are understandable and work well together.
- **Evidence-driven:** use regression and cross-shell tests to support
  reliability claims within the documented compatibility boundary.
- **Predictable reuse:** preserve existing behavior and favor fixed-version,
  local loading where reproducible or offline execution matters.

These priorities guide maintenance and new API design; they do not assert that
every existing helper is side-effect-free or safe for arbitrary input. Read the
[design principles](docs/design-principles.md),
[API reference](docs/references.md), and
[Bash/zsh compatibility contract](docs/bash-zsh-compatibility.md) for scope and
boundaries. Proposed data types or helpers are not available APIs until they
have been implemented, tested and documented.

Available on [GitHub](https://github.com/renault-digital/bash-base),
[NPM](https://www.npmjs.com/package/@renault-digital/bash-base), and
[Docker Hub](https://hub.docker.com/r/renaultdigital/bash-base).


## Bash and zsh compatibility

The reusable functions in `src/` can be sourced by both **Bash** and **zsh**.
This matters on macOS, where zsh is the default interactive shell: `source
bash-base` is interpreted by the current shell, so the library itself must not
rely on hidden Bash-only syntax.

Existing Bash scripts and the Bash ShellSpec regression suite remain supported.
A separate dual-shell compatibility gate runs the same core behavior under Bash
and zsh.

See [Bash and zsh compatibility](docs/bash-zsh-compatibility.md) for the exact
contract, array portability boundary and test model.


## Test coverage report

The `coverage-macos` CI job requires **100% of the measurable `src/*.sh` lines**
to be covered by the validated union of Bash 3.2, Bash 5+, zsh and TTY runs on
one source revision. This is **union line coverage**, not 100% coverage in each
shell or a claim of complete branch/input coverage.

Only that validated union is uploaded to Codecov. Invalid reports are rejected;
a valid result below 100% is still reported, while the strict CI gate fails.
The badge shows Codecov's latest processed result for `master`, not a hard-coded
percentage. Click the tree below for file and line details, and check the commit
SHA when comparing it with CI. Processing delays or a missing upload may leave
an older result visible.

[![test coverage](https://codecov.io/gh/renault-digital/bash-base/graphs/tree.svg)](https://app.codecov.io/gh/renault-digital/bash-base/tree/master/src)

See the [CI test matrix](docs/coverage.md#ci-test-matrix) for runner, interpreter,
test scope and report destinations.

See [coverage collection, validation and reporting](docs/coverage.md) for the
report contract, authentication setup and troubleshooting. CI also retains the
raw reports, source hashes and logs in the `strict-macos-coverage` artifact.


## Quick start

Creat a sample script `example_docker.sh` with the following content:
```bash
#!/usr/bin/env bash

source <(docker run renaultdigital/bash-base)
SHORT_DESC='an example shell script to show how to use bash-base '

args_parse $# "$@" firstName sex
args_valid_or_read firstName '^[A-Za-z ]{2,}$' "Your first name (only letters)"
args_valid_or_select_pipe sex 'Mr.|Mrs' "Your sex"

confirm_to_continue firstName sex
print_success "Hello $sex $(string_upper_first "$firstName"), nice to meet you."
```

Assign the `execute` right to it:
```bash
chmod +x example_docker.sh
```

Run it:
![example-docker.gif](docs/example-docker.gif)


## Installation

For reproducible or offline workflows, prefer a reviewed, fixed-version local
copy. The methods below have different network and update behavior; read the
Web installer and direct GitHub import notes before choosing a loading method.
A remote-loading example is not an offline configuration.

#### 1. Import from [docker hub](https://hub.docker.com/r/renaultdigital/bash-base)

```bash
# One line to import & download if not yet:
source <(docker run --rm renaultdigital/bash-base)
```
<details>
<summary>Others</summary>

```bash
# To specify a version
source <(docker run --rm renaultdigital/bash-base:1.0.2)
# Update or uninstall
docker rmi -f renaultdigital/bash-base
```
</details>


#### 2. Install from [NPM](https://www.npmjs.com/package/@renault-digital/bash-base)

```bash
# Install the latest
npm i -g @renault-digital/bash-base
```
<details>
<summary>Others</summary>

```bash
# To specify a version
npm i @renault-digital/bash-base@1.6.0
# One line to import & install if not yet:
source bash-base 2>/dev/null || npm i -g @renault-digital/bash-base && source bash-base
# Verify the installation
man bash-base
# Uninstall
npm uninstall -g @renault-digital/bash-base
```
</details>


#### 3. Install with [basher](https://github.com/basherpm/basher)

```bash
# Install from master branch
basher install renault-digital/bash-base
```
<details>
<summary>Others</summary>

- The officially supported version is bash-base **v2.0.0** and later.
```bash
# To specify a version
basher install renault-digital/bash-base@v1.0.2
# Verify the installation
man bash-base
# Uninstall
basher uninstall renault-digital/bash-base
```
</details>


#### 4. Web installer

```bash
# Install the latest
curl -fsSL https://git.io/bashbase-i | bash
```
<details>
<summary>Others</summary>

- The directory installed is `~/.bash-base`.
- `https://git.io/bashbase-i` is redirected to [install.sh](https://github.com/renault-digital/bash-base/raw/master/scripts/install.sh)
- this way, your script will access github to check whether a newer version published each time it launched.
  For CI, it is recommended to use a specific version to avoid unexpected failures.
```bash
# or with wget
wget -O- https://git.io/bashbase-i | bash
# Verify the installation
man bash-base
# Uninstall all versions
curl -fsSL https://git.io/bashbase-i | bash -s uninstall
```

To specify a version:
```bash
curl -fsSL https://git.io/bashbase-i | bash -s v1.0.2
# Verify the installation
man bash-base.v1.0.2
```

Check if all functions of bash-base is compatible with current environment when install:
```bash
curl -fsSL https://git.io/bashbase-i | bash -s latest verify
curl -fsSL https://git.io/bashbase-i | bash -s v1.0.2 verify
```

One line to import & install if not yet:
```bash
source bash-base 2>/dev/null || curl -fsSL https://git.io/bashbase-i | bash
source bash-base 2>/dev/null || curl -fsSL https://git.io/bashbase-i | bash -s latest verify

source bash-base.v1.0.2 2>/dev/null || curl -fsSL https://git.io/bashbase-i | bash -s v1.0.2
source bash-base.v1.0.2 2>/dev/null || curl -fsSL https://git.io/bashbase-i | bash -s v1.0.2 verify
```

</details>


#### 5. Import from GitHub, no install

```bash
# Import latest version:
source <(curl -fsSL https://git.io/bashbase)
```
<details>
<summary>Others</summary>

- This way, your script need to access GitHub each time it launched.
```bash
# or with eval
eval "$(curl -fsSL https://git.io/bashbase)"
# To specify a version
source <(curl -fsSL https://raw.githubusercontent.com/renault-digital/bash-base/v1.0.2/bin/bash-base)
# Verify the import
string_trim ' hello '
```
</details>


#### 6. Download archive

See [GitHub releases](https://github.com/renault-digital/bash-base/releases) or [NPM tarball URLs](https://registry.npmjs.org/@renault-digital/bash-base)
  

## How to config

#### 1. LOG_LEVEL

The possible values are:
- **$LOG_LEVEL_ERROR or 4**: enable the output of `print_error`/`print_header`
- **$LOG_LEVEL_WARN or 3**: enable the output of `print_warn`/`print_args`/`print_success` and those by level **ERROR**
- **$LOG_LEVEL_INFO or 2**: enable `print_info` and those by level **ERROR**, **WARN**
- **$LOG_LEVEL_DEBUG or 1**: enable `print_debug` and those by level **ERROR**, **WARN**, **INFO**

```
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}
```
The default value `$LOG_LEVEL_INFO` will be used if no config existed. you can override this default value in `shell script`, `OS environment` or `ci/cd pipeline variables`:
```
export LOG_LEVEL=$LOG_LEVEL_DEBUG 
or
export LOG_LEVEL=1
```

#### 2. SHORT_DESC
```
SHORT_DESC='a bash script using bash-base'
```
redefine it to show your script short description in the 'NAME' field of generated response for <mark>**-h**</mark> argument.


#### 3. USAGE
```
USAGE=''
```
redefine it in your script only if the generated response for <mark>**-h**</mark> argument is not good for you.


## All Functions
See [reference](docs/references.md)

## Usage Examples
See [example](example) folder, including the use case of <mark>**[Makefile](example/Makefile)**</mark>

## Specfile (test file)
See [spec](spec) folder. Run `npm test` to execute the Bash/zsh compatibility gate followed by the existing Bash ShellSpec regression suite.

## Latest Update
See [change log](CHANGELOG.md)

## Contributing
See [How to contribute](CONTRIBUTING.md)

## License
[MIT](https://opensource.org/licenses/MIT).
