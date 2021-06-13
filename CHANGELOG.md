# [2.2.0](https://github.com/renault-digital/bash-base/compare/v2.1.0...v2.2.0) (2021-06-13)


### Features

* add args_valid_or_default for the optional params ([db5b8c2](https://github.com/renault-digital/bash-base/commit/db5b8c2099b501ce1eac04580c524d9cb1dc9bb2))

# [2.1.0](https://github.com/renault-digital/bash-base/compare/v2.0.2...v2.1.0) (2021-06-13)


### Features

* use default value INFO only if absent for LOG_LEVEL ([9eb6ae1](https://github.com/renault-digital/bash-base/commit/9eb6ae1a35c3bf37d109e9bf581da4d28d34c7d3))

## [2.0.2](https://github.com/renault-digital/bash-base/compare/v2.0.1...v2.0.2) (2021-06-13)

## [2.0.1](https://github.com/renault-digital/bash-base/compare/v2.0.0...v2.0.1) (2021-05-17)

# [2.0.0](https://github.com/renault-digital/bash-base/compare/v1.7.0...v2.0.0) (2021-05-17)


### Documentation

* add basher install ([f4772f3](https://github.com/renault-digital/bash-base/commit/f4772f3f476d93207550c4f6ff5cacbeffa202c8))


### BREAKING CHANGES

* rename bin/bash-base.sh to bin/bash-base for basher

# [1.7.0](https://github.com/renault-digital/bash-base/compare/v1.6.0...v1.7.0) (2021-05-15)


### Features

* add param to specific the kill signal ([28c4fd4](https://github.com/renault-digital/bash-base/commit/28c4fd4d7516891682f323a97488ab3e63b5c712))

# [1.6.0](https://github.com/renault-digital/bash-base/compare/v1.5.1...v1.6.0) (2021-05-09)


### Bug Fixes

* fix the generated help usage for args_valid_or_read ([e32f621](https://github.com/renault-digital/bash-base/commit/e32f6216680b40dea46816943454a5b7b2dbb43f))


### Features

* add wait_for and process functions ([f86f6a2](https://github.com/renault-digital/bash-base/commit/f86f6a24ac6ceef74f694d6932ba0adbb4a95d90)), closes [#42](https://github.com/renault-digital/bash-base/issues/42)

## [1.5.1](https://github.com/renault-digital/bash-base/compare/v1.5.0...v1.5.1) (2021-05-08)

# [1.5.0](https://github.com/renault-digital/bash-base/compare/v1.4.7...v1.5.0) (2021-05-07)


### Features

* add args_valid_or_select_args ([ce5cc4a](https://github.com/renault-digital/bash-base/commit/ce5cc4aca59dbe4d5edc53d18f29ceef88566bb6)), closes [#38](https://github.com/renault-digital/bash-base/issues/38)
* add array_in ([8a98de2](https://github.com/renault-digital/bash-base/commit/8a98de2d770ed67c413826ec00110c6031f06e74))

## [1.4.7](https://github.com/renault-digital/bash-base/compare/v1.4.6...v1.4.7) (2021-05-07)

## [1.4.6](https://github.com/renault-digital/bash-base/compare/v1.4.5...v1.4.6) (2021-01-31)

## [1.4.5](https://github.com/renault-digital/bash-base/compare/v1.4.4...v1.4.5) (2020-10-06)


### Bug Fixes

* can not extract argument valid rule if multiple rules existed ([a5fd06e](https://github.com/renault-digital/bash-base/commit/a5fd06e0058022ca592476bf01f8ecff6c9b7e02)), closes [#34](https://github.com/renault-digital/bash-base/issues/34)

## [1.4.4](https://github.com/renault-digital/bash-base/compare/v1.4.3...v1.4.4) (2020-10-04)


### Bug Fixes

* print help usage if parameter not valid ([c98a654](https://github.com/renault-digital/bash-base/commit/c98a654d4fd6eef1a082cd8d3ed5580fe7d5ccad))

## [1.4.3](https://github.com/renault-digital/bash-base/compare/v1.4.2...v1.4.3) (2020-09-16)


### Bug Fixes

* ignore the error of `shopt command not found` ([e790eb4](https://github.com/renault-digital/bash-base/commit/e790eb417b6de11b5358badd4178dce6a987dc18)), closes [#30](https://github.com/renault-digital/bash-base/issues/30)

## [1.4.2](https://github.com/renault-digital/bash-base/compare/v1.4.1...v1.4.2) (2020-09-15)

## [1.4.1](https://github.com/renault-digital/bash-base/compare/v1.4.0...v1.4.1) (2020-09-15)

# [1.4.0](https://github.com/renault-digital/bash-base/compare/v1.3.0...v1.4.0) (2020-09-15)

# [1.3.0](https://github.com/renault-digital/bash-base/compare/v1.2.3...v1.3.0) (2020-09-15)


### Features

* add function print_info and alias print_args-> args_print ([656cfdd](https://github.com/renault-digital/bash-base/commit/656cfdd3c5b7692539ae1e4303f9775cb9f1b066)), closes [#25](https://github.com/renault-digital/bash-base/issues/25)

## [1.2.3](https://github.com/renault-digital/bash-base/compare/v1.2.2...v1.2.3) (2020-09-13)

## [1.2.2](https://github.com/renault-digital/bash-base/compare/v1.2.1...v1.2.2) (2020-09-13)

## [1.2.1](https://github.com/renault-digital/bash-base/compare/v1.2.0...v1.2.1) (2020-09-11)

# [1.2.0](https://github.com/renault-digital/bash-base/compare/v1.1.1...v1.2.0) (2020-09-10)


### Features

* add function print_warn and print_success ([b827d06](https://github.com/renault-digital/bash-base/commit/b827d061907005c5cbac1b66696976dd484a219e)), closes [#20](https://github.com/renault-digital/bash-base/issues/20)

## [1.1.1](https://github.com/renault-digital/bash-base/compare/v1.1.0...v1.1.1) (2020-09-10)


### Bug Fixes

* correct the markdown generator ([31af0a7](https://github.com/renault-digital/bash-base/commit/31af0a777815406216757eae6e05f7865b26db81)), closes [#18](https://github.com/renault-digital/bash-base/issues/18)

# [1.1.0](https://github.com/renault-digital/bash-base/compare/v1.0.4...v1.1.0) (2020-09-09)

### [1.0.4](https://github.com/renault-digital/bash-base/compare/v1.0.3...v1.0.4) (2020-09-09)

## [1.0.3](https://github.com/renault-digital/bash-base/compare/v1.0.2...v1.0.3) (2020-09-08)

## [1.0.2](https://github.com/renault-digital/bash-base/compare/v1.0.1...v1.0.2) (2020-09-06)


### Bug Fixes

* the script install.sh ([a85deb8](https://github.com/renault-digital/bash-base/commit/a85deb80a107a61966597a42658703da304d3122)), closes [#4](https://github.com/renault-digital/bash-base/issues/4)

# 1.0.0 (2020-09-05)


### Features

* a scratch of bash-base and cicd config ([84c3bf8](https://github.com/renault-digital/bash-base/commit/84c3bf84e3ec73842efd06061349c62008e27fa5))
* initial commit ([41a9e51](https://github.com/renault-digital/bash-base/commit/41a9e51c15d9a328f9ae301070f5003326c0cd3b))
