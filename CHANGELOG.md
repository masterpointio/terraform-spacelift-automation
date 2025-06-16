# Changelog

## [1.4.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v1.3.1...v1.4.0) (2025-06-16)


### Features

* set default `terraform_version = null` ([#73](https://github.com/masterpointio/terraform-spacelift-automation/issues/73)) ([b19e782](https://github.com/masterpointio/terraform-spacelift-automation/commit/b19e782461ff8d5dbf37888885e97712068fe538))


### Bug Fixes

* **gha:** trigger test workflow on pull_request_target ([#74](https://github.com/masterpointio/terraform-spacelift-automation/issues/74)) ([0320c70](https://github.com/masterpointio/terraform-spacelift-automation/commit/0320c70da3b2553c0f8376241cc5d1fa638c11f4))

## [1.3.1](https://github.com/masterpointio/terraform-spacelift-automation/compare/v1.3.0...v1.3.1) (2025-06-09)


### Bug Fixes

* **gha:** wait for checks and merge with admin ([#71](https://github.com/masterpointio/terraform-spacelift-automation/issues/71)) ([bfc8f23](https://github.com/masterpointio/terraform-spacelift-automation/commit/bfc8f23960d874bb209e9f18b23e33c750d4cf4f))

## [1.3.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v1.2.0...v1.3.0) (2025-05-12)


### Features

* manage destructor creation and activation separately ([#66](https://github.com/masterpointio/terraform-spacelift-automation/issues/66)) ([af2a2de](https://github.com/masterpointio/terraform-spacelift-automation/commit/af2a2dea6209d00416059ee4c9a38aa41d961445))

## [1.2.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v1.1.1...v1.2.0) (2025-04-28)


### Features

* **spaces:** adds spaces + consolidates with the template ([#62](https://github.com/masterpointio/terraform-spacelift-automation/issues/62)) ([dd9162f](https://github.com/masterpointio/terraform-spacelift-automation/commit/dd9162fde23bbd596c4d5e687a395f338411e2e5))

## [1.1.1](https://github.com/masterpointio/terraform-spacelift-automation/compare/v1.1.0...v1.1.1) (2025-02-12)


### Bug Fixes

* pin tofu 1.8 due to usage of .tofu extension ([#54](https://github.com/masterpointio/terraform-spacelift-automation/issues/54)) ([814d64b](https://github.com/masterpointio/terraform-spacelift-automation/commit/814d64b98ac4e43d8cf677e356d68f78b6ab9254))

## [1.1.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v1.0.0...v1.1.0) (2025-02-11)


### Features

* add spacelift stack's `after_run` config, FINALLY hook ([#52](https://github.com/masterpointio/terraform-spacelift-automation/issues/52)) ([5ad3902](https://github.com/masterpointio/terraform-spacelift-automation/commit/5ad3902cd884648d9ef98c727fd36b707c692b26))

## [1.0.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.7.0...v1.0.0) (2025-02-04)


### ⚠ BREAKING CHANGES

* TF Version pinning has been updated to require terraform v1.9+ and OpenTofu v1.7+. Please update the consuming root module accordingly. (#43)
* Scopes `tfvars` + `default_tf_workspace_enabled` settings under `automation_settings` object in StackConfig schema. [See README](https://github.com/masterpointio/terraform-spacelift-automation?tab=readme-ov-file#what-goes-in-a-stack-config-file-eg-stacksdevyaml-stackscommonyaml-stackyaml-and-similar) for example of StackConfig schema. (#42)

### Features

* adds support for description as a templatestring ([#43](https://github.com/masterpointio/terraform-spacelift-automation/issues/43)) ([1bbb74f](https://github.com/masterpointio/terraform-spacelift-automation/commit/1bbb74f46ef92d643ec560a6aea2aaf3b7a62e02))
* adds the runtime_overrides variable + tests ([#44](https://github.com/masterpointio/terraform-spacelift-automation/issues/44)) ([6030f94](https://github.com/masterpointio/terraform-spacelift-automation/commit/6030f94436a703b2d6a53851f95f9c4d74a00ddf))
* feat: allow specifying `space_name` that maps to space_id #46
* **schema:** adds initial JSON schema + StackConfig changes ([#42](https://github.com/masterpointio/terraform-spacelift-automation/issues/42)) ([f247b5e](https://github.com/masterpointio/terraform-spacelift-automation/commit/f247b5ee371f0c436f97b6a9f5a90bb83c802fec))


### Bug Fixes

* cron validator regex escape characters ([#45](https://github.com/masterpointio/terraform-spacelift-automation/issues/45)) ([81a386b](https://github.com/masterpointio/terraform-spacelift-automation/commit/81a386bf5eb20be7e28ee0fcd24d51d21113de55))
* dont clobber static config with overrides ([#50](https://github.com/masterpointio/terraform-spacelift-automation/issues/50)) ([b352674](https://github.com/masterpointio/terraform-spacelift-automation/commit/b352674bbd53f03be798d256eb5ba541e4940709))
* external space changed so update test data ([#51](https://github.com/masterpointio/terraform-spacelift-automation/issues/51)) ([569d8d4](https://github.com/masterpointio/terraform-spacelift-automation/commit/569d8d4ff438954cc546cbe5221d94fc19445037))
## [0.7.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.6.0...v0.7.0) (2025-01-09)


### Features

* adds a variable to support labels on a root module level ([#39](https://github.com/masterpointio/terraform-spacelift-automation/issues/39)) ([f84d9ac](https://github.com/masterpointio/terraform-spacelift-automation/commit/f84d9ac639664ded004d00796dea3c14c07cc9b2))

## [0.6.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.5.0...v0.6.0) (2024-12-31)


### Features

* runner image and globs paths for stacks ([#34](https://github.com/masterpointio/terraform-spacelift-automation/issues/34)) ([074dae8](https://github.com/masterpointio/terraform-spacelift-automation/commit/074dae8b5ee4f8e07ff7ec484a79f5c2156dac19))

## [0.5.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.4.0...v0.5.0) (2024-12-30)


### Features

* allow project root to be customized for stack ([#32](https://github.com/masterpointio/terraform-spacelift-automation/issues/32)) ([3eb9027](https://github.com/masterpointio/terraform-spacelift-automation/commit/3eb9027dfb0cb6bfeb01153ea56fc3f1126fa9c9))

## [0.4.0](https://github.com/masterpointio/terraform-spacelift-automation/compare/v0.3.1...v0.4.0) (2024-12-26)


### Features

* begins the work to support single vs multi root_module_structure ([#17](https://github.com/masterpointio/terraform-spacelift-automation/issues/17)) ([598f0c7](https://github.com/masterpointio/terraform-spacelift-automation/commit/598f0c7be4fd69de0b598bd83db28ca8960cf715))

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
