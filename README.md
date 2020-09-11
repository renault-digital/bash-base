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

## Quick start

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

Generated help usage:
![help.gif](docs/help.gif)

Run it:
![run.gif](docs/run.gif)

Available on github, npm and dockerhub, see [other ways of usage](docs/USAGE.md).

## Example
See [example](example) folder

## Reference
See [reference](docs/references.md)

## Specification
See [spec](spec) folder

## Latest Update
See [CHANGELOG.md](CHANGELOG.md)

## Contributing
See [How to contribute](CONTRIBUTING.md)

## License
[MIT](https://opensource.org/licenses/MIT).
