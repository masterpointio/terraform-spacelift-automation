# Changelog

## [0.3.1](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.3.0...v0.3.1) (2024-12-19)


### Bug Fixes

* check if tfvars file exists only if when it's expected ([#16](https://github.com/masterpointio/terraform-spacelift-automation/issues/16)) ([72c5a77](https://github.com/masterpointio/terraform-spacelift-automation/commit/72c5a773ba00952359f49b828fe25777f98a2214))
* include stack specific `before_init` even if tfvars disabled + adds initial tests 🎉 ([#13](https://github.com/masterpointio/terraform-spacelift-automation/issues/13)) ([9eb3cd4](https://github.com/masterpointio/terraform-spacelift-automation/commit/9eb3cd42e77e2c41307740142cc7c7b18b2b5b2e))
* pass github_enterprise.id to stacks ([#14](https://github.com/masterpointio/terraform-spacelift-automation/issues/14)) ([f4c6c1b](https://github.com/masterpointio/terraform-spacelift-automation/commit/f4c6c1b2ffca87de178fb8db6a19c552b9a9fbe8))

## [0.3.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.2.1...v0.3.0) (2024-12-18)


### Features

* allow default TF workspace usage ([8ccba9f](https://github.com/masterpointio/terraform-spacelift-automation/commit/8ccba9fb41791f0c8ba31b30fb20e89dd77360e4))

* support more spacelift settings: `enable_well_known_secret_masking` + `github_action_deploy`   ([df259b2](https://github.com/masterpointio/terraform-spacelift-automation/commit/df259b27fb6163e4d2dbc53f70624b6f6e80c2b5))

## Fixes

* Fixes drift detection precondition

## [0.2.1](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.2.0...v0.2.1) (2024-12-13)


### Bug Fixes

* common labels merge with stack labels ([b9e63ae](https://github.com/masterpointio/terraform-spacelift-automation/commit/b9e63ae4bbc020e285be543c1decb953f148a59b))

## [0.2.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.1.0...v0.2.0) (2024-11-14)


### Features

* adds CRabbit custom config ([e9b4889](https://github.com/masterpointio/terraform-spacelift-automation/commit/e9b4889f5d05e390903d01b4485a09c63c0f1af3))

## 0.1.0 (2024-11-11)

### Features

- initial testing ([b831715](https://github.com/masterpointio/terraform-spacelift-automation/commit/b831715cb84960d10e94e23e799eeab6b16656ce))
- support all root modules + add example ([ca711fa](https://github.com/masterpointio/terraform-spacelift-automation/commit/ca711fab4208d79a0870cb2d9e5799e2679f696b))

## [0.1.1](https://github.com/masterpointio/terraform-module-template/compare/0.1.0...v0.1.1) (2024-08-15)

### Bug Fixes

- remove markdown trailing whitespace ([d609646](https://github.com/masterpointio/terraform-module-template/commit/d6096463b916eb536603d4ca3b2f3315e3fec9f2))
- removes redundant editorconfig settings ([bbe0050](https://github.com/masterpointio/terraform-module-template/commit/bbe0050450cece8074f3d9ff5c3bd72ff01d8a1b))
