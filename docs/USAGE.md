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
To update or uninstall
```
docker rmi -f renaultdigital/bash-base
```

#### 2. Install from NPM

See [npm package](https://www.npmjs.com/package/@renault-digital/bash-base)
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
