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


## What's bash-base?

A common lib for creating bash script easily like other program language.

- Rich functions to operate array/list/set/string/arguments/reflect/..., the functions can be used in console or script
- Just call bash-base function by name in your script, like other programing language, no need anymore to search "how to ... in bash"
- Parse and validation arguments easily & flexible, automatically generate help usage for your script, focus your script only on the business logical
- Make your script more compact & readability
- Available on github/npm/dockerhub

![bash-base.gif](bash-base.gif)

## Latest Update
See [CHANGELOG.md](CHANGELOG.md)


## How to use

#### 1. Install from docker

See [docker hub](https://hub.docker.com/r/renaultdigital/bash-base)

```
source <(docker run --rm renaultdigital/bash-base)
``` 

Or specific a fixed version

```
source <(docker run --rm renaultdigital/bash-base:1.0.2)
```


#### 2. Install from NPM

See [npm repackage](https://www.npmjs.com/package/@renault-digital/bash-base)
```
npm i -g @renault-digital/bash-base
```

verify the installation
```
man bash-base
```

or one line in your script:
```
# import, and install bash-base from npmjs only if not installed:
source bash-base 2>/dev/null || npm i -g @renault-digital/bash-base && source bash-base
```

To uninstall:
```
npm uninstall -g @renault-digital/bash-base
```


#### 3. Install from GitHub

The directory installed is `~/.bash-base`.

##### install if not existed the specific version in console / shell script:

- the man page of version v1.0.2:  `man bash-base.v1.0.2`, 
- you can import this version in one line in your script:
```
source bash-base.v1.0.2 2>/dev/null || curl -o- -L https://raw.githubusercontent.com/renault-digital/bash-base/master/scripts/install.sh | bash -s -- v1.0.2"
```


##### If you always prefer to use the latest version, install if not existed the latest version in console / shell script:
- the man page is: `man bash-base`,
- and import like this:
```
source bash-base 2>/dev/null || curl -o- -L https://raw.githubusercontent.com/renault-digital/bash-base/master/scripts/install.sh | bash
```
or
```
source bash-base 2>/dev/null || curl -o- -L https://raw.githubusercontent.com/renault-digital/bash-base/master/scripts/install.sh | bash -s -- latest
```

###### Notes:
this way, your script will access github to check whether a newer version published during every time it launched.
if you don't like this behavior, you need to specify a fixed version to use in your script.


##### If you want to check all functions of bash-base is compatible with your environment when install, using param `verify` :
```
source bash-base 2>/dev/null || curl -o- -L https://raw.githubusercontent.com/renault-digital/bash-base/master/scripts/install.sh | bash -s -- latest verify
```
or
```
source bash-base 2>/dev/null || curl -o- -L https://raw.githubusercontent.com/renault-digital/bash-base/master/scripts/install.sh | bash -s -- v1.0.2 verify
```

##### To uninstall all versions of bash-base from your system:
```
curl -o- -L https://raw.githubusercontent.com/renault-digital/bash-base/master/scripts/install.sh | bash -s -- uninstall
```


#### 4. Import bash-base from GitHub when execute

Simply write in console or script:

If to import latest version:
```
source <(curl -fsSL https://raw.githubusercontent.com/renault-digital/bash-base/master/bin/bash-base.sh)
```
or
```
eval "$(curl -fsSL https://raw.githubusercontent.com/renault-digital/bash-base/master/bin/bash-base.sh)"
```

If to import specific version:
```
source <(curl -fsSL https://raw.githubusercontent.com/renault-digital/bash-base/v1.0.2/bin/bash-base.sh)
```
or
```
eval "$(curl -fsSL https://raw.githubusercontent.com/renault-digital/bash-base/v1.0.2/bin/bash-base.sh)
```

Verify the import in console:
```
string_trim ' hello '
```

###### Notes
this way, your script need to access github when each time it launched.


#### 5. Download only

download a specific version:

- from NPM: https://registry.npmjs.org/@renault-digital/bash-base/-/bash-base-1.0.2.tgz
- from github: https://github.com/renault-digital/bash-base/archive/v1.0.2.tar.gz

## Example
See [example](example) folder

## Reference
See [reference](docs/references.md)

## Specification
See [spec](spec) folder

## Contributing
See [How to contribute](CONTRIBUTING.md)

## License
[MIT](https://opensource.org/licenses/MIT).
