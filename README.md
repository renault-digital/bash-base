# Welcome to [bash-base](https://renault-digital.github.io/bash-base)

[![License](https://img.shields.io/github/license/renault-digital/bash-base.svg)](https://github.com/renault-digital/bash-base/blob/master/LICENSE)
[![GitHub top language](https://img.shields.io/github/languages/top/renault-digital/bash-base.svg)](https://github.com/renault-digital/bash-base/search?l=Shell)
[![codecov](https://codecov.io/gh/renault-digital/bash-base/branch/master/graph/badge.svg)](https://codecov.io/gh/renault-digital/bash-base)
[![GitHub Actions Status](https://img.shields.io/github/workflow/status/renault-digital/bash-base/cicd?label=GithubActions)](https://github.com/renault-digital/bash-base/actions)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![GitHub release](https://img.shields.io/github/release/renault-digital/bash-base.svg)](https://github.com/renault-digital/bash-base/releases/latest)
[![npm package](https://img.shields.io/npm/v/@renault-digital/bash-base.svg)](https://www.npmjs.com/package/@renault-digital/bash-base)
[![Docker Cloud Build Status](https://img.shields.io/docker/pulls/renaultdigital/bash-base.svg)](https://hub.docker.com/r/renaultdigital/bash-base)
![GitHub commits since latest release](https://img.shields.io/github/commits-since/renault-digital/bash-base/latest)


## Goal

No more spending time searching the special ways of bash for basic operations like "how to replace a string in bash", then compare, choose, and test among many potential solutions.

Bash-base does this for you, you can just call the function here which is well tested and stable, and only focus you on the high level logic. Writing your script with less time, but more readability.

Available on [github](https://github.com/renault-digital/bash-base), [npm](https://www.npmjs.com/package/@renault-digital/bash-base) and [dockerhub](https://hub.docker.com/r/renaultdigital/bash-base), see [usage](docs/USAGE.md).

## Quick start

Creat a sample script `example_docker.sh` with the following content:
```shell
#!/usr/bin/env bash

source <(docker run renaultdigital/bash-base)

SHORT_DESC='an example shell script to show how to use bash-base '

args_parse $# "$@" firstName age sex country
args_valid_or_read firstName '^[A-Za-z ]{2,}$' "Your first name (only letters)"
args_valid_or_read age '^[0-9]{1,2}$' "Your age (maxim 2 digits))"
args_valid_or_select_pipe sex 'Mr.|Mrs' "Your sex"

response=$(curl -sS 'https://restcountries.eu/rest/v2/regionalbloc/eu' --compressed)
string_pick_to_array '{"name":"' '","topLevelDomain' countryNames "$response"
args_valid_or_select country countryNames "Which country"

print_success "Hello $sex $(string_upper_first "$firstName"), you are in $country, and your age is $age, nice to meet you."
```

Assign the `execute` right to it:
```
chmod +x example_docker.sh
```

Print the generated help usage with the option `-h`:
![help.gif](docs/help.gif)

Run it:
![run.gif](docs/run.gif)


## [Test coverage report](https://codecov.io/gh/renault-digital/bash-base)
![test coverage](https://codecov.io/gh/renault-digital/bash-base/graphs/tree.svg)
![test coverage](https://camo.githubusercontent.com/7070235e235fd6c26427496dd2958704df132b2229631b8bc8bb5af13d0e5ec2/68747470733a2f2f636f6465636f762e696f2f67682f72656e61756c742d6469676974616c2f626173682d626173652f6772617068732f747265652e737667)

----

## Table of Contents <!-- omit in toc -->

- [Goal](#goal)
- [Quick start](#quick-start)
- [Test coverage report](#test-coverage-report)
- [Installation](#installation)
    - [Web installer (for developers)](#web-installer-for-developers)
    - [Package manager](#package-manager)
    - [Manual installation](#manual-installation)
    - [Distribution archive (runtime only)](#distribution-archive-runtime-only)


- [Examples](example)
- [Functions reference](docs/references.md)
- [Specfile (test file)](spec)
- [Latest Update](CHANGELOG.md)
- [How to contribute](CONTRIBUTING.md)

## License
[MIT](https://opensource.org/licenses/MIT).
