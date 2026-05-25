# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2026-05-25

### Changes

---

Packages with breaking changes:

 - [`boot` - `v0.2.0`](#boot---v020)
 - [`boot_aop` - `v0.2.0`](#boot_aop---v020)
 - [`boot_aop_generator` - `v0.2.0`](#boot_aop_generator---v020)
 - [`boot_core` - `v0.2.0`](#boot_core---v020)
 - [`boot_events` - `v0.2.0`](#boot_events---v020)
 - [`boot_generator` - `v0.2.0`](#boot_generator---v020)
 - [`boot_http` - `v0.2.0`](#boot_http---v020)
 - [`boot_http_client_generator` - `v0.2.0`](#boot_http_client_generator---v020)
 - [`boot_http_common` - `v0.2.0`](#boot_http_common---v020)
 - [`boot_http_generator` - `v0.2.0`](#boot_http_generator---v020)
 - [`boot_scheduling` - `v0.2.0`](#boot_scheduling---v020)
 - [`boot_security` - `v0.2.0`](#boot_security---v020)
 - [`boot_security_jwt` - `v0.2.0`](#boot_security_jwt---v020)
 - [`boot_serialization_generator` - `v0.2.0`](#boot_serialization_generator---v020)
 - [`boot_test` - `v0.2.0`](#boot_test---v020)

Packages with other changes:

 - [`boot_cli` - `v0.1.6`](#boot_cli---v016)
 - [`boot_http_client` - `v0.1.3`](#boot_http_client---v013)
 - [`boot_serialization` - `v0.1.1+6`](#boot_serialization---v0116)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `boot_serialization` - `v0.1.1+6`

---

#### `boot` - `v0.2.0`

 - **REFACTOR**(core): consolidate parseDuration into boot_core. ([96b5bcc7](https://github.com/zonnedev/dart-boot/commit/96b5bcc74b1ec3144a7cfc934f96a7baafdc95db))
 - **FEAT**(core): @ConfigurationProperties, lazy routes, self-contained boot_http_client. ([1d148204](https://github.com/zonnedev/dart-boot/commit/1d148204a6866779c455ace6f16cd84d17e08b19))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_aop` - `v0.2.0`

 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_aop_generator` - `v0.2.0`

 - **FIX**(generator): library mode scans direct deps only, app mode scans transitive. ([892f959e](https://github.com/zonnedev/dart-boot/commit/892f959e03b93ee325d2a6bc797262b1916ab9f3))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_core` - `v0.2.0`

 - **REFACTOR**(core): consolidate parseDuration into boot_core. ([96b5bcc7](https://github.com/zonnedev/dart-boot/commit/96b5bcc74b1ec3144a7cfc934f96a7baafdc95db))
 - **FIX**(generator): avoid Type name conflicts in generated beanType getter. ([098d7596](https://github.com/zonnedev/dart-boot/commit/098d759677581ae6a70010ae35f764e8c659de7c))
 - **FEAT**(core): @ConfigurationProperties, lazy routes, self-contained boot_http_client. ([1d148204](https://github.com/zonnedev/dart-boot/commit/1d148204a6866779c455ace6f16cd84d17e08b19))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_events` - `v0.2.0`

 - **FIX**(generator): avoid Type name conflicts in generated beanType getter. ([098d7596](https://github.com/zonnedev/dart-boot/commit/098d759677581ae6a70010ae35f764e8c659de7c))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_generator` - `v0.2.0`

 - **REFACTOR**(generator): remove boot_http dependency from bean_generator. ([ac51f274](https://github.com/zonnedev/dart-boot/commit/ac51f2749358f47d836db81e6eb77b412b63d921))
 - **FIX**(generator): stop generating boot_context.g.dart for @BootLibrary packages. ([90a436ea](https://github.com/zonnedev/dart-boot/commit/90a436ea8f50bfd5e2c9587d1f71c41c607bedfb))
 - **FIX**(generator): library mode scans direct deps only, app mode scans transitive. ([892f959e](https://github.com/zonnedev/dart-boot/commit/892f959e03b93ee325d2a6bc797262b1916ab9f3))
 - **FIX**(generator): avoid Type name conflicts in generated beanType getter. ([098d7596](https://github.com/zonnedev/dart-boot/commit/098d759677581ae6a70010ae35f764e8c659de7c))
 - **FEAT**(core): @ConfigurationProperties, lazy routes, self-contained boot_http_client. ([1d148204](https://github.com/zonnedev/dart-boot/commit/1d148204a6866779c455ace6f16cd84d17e08b19))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_http` - `v0.2.0`

 - **REFACTOR**(core): consolidate parseDuration into boot_core. ([96b5bcc7](https://github.com/zonnedev/dart-boot/commit/96b5bcc74b1ec3144a7cfc934f96a7baafdc95db))
 - **FIX**(generator): library mode scans direct deps only, app mode scans transitive. ([892f959e](https://github.com/zonnedev/dart-boot/commit/892f959e03b93ee325d2a6bc797262b1916ab9f3))
 - **FIX**(generator): avoid Type name conflicts in generated beanType getter. ([098d7596](https://github.com/zonnedev/dart-boot/commit/098d759677581ae6a70010ae35f764e8c659de7c))
 - **FEAT**(core): @ConfigurationProperties, lazy routes, self-contained boot_http_client. ([1d148204](https://github.com/zonnedev/dart-boot/commit/1d148204a6866779c455ace6f16cd84d17e08b19))
 - **FEAT**(test): WebSocket testing and integration test support. ([22df3878](https://github.com/zonnedev/dart-boot/commit/22df387820597139dfa21af867b7539a81570096))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_http_client_generator` - `v0.2.0`

 - **FIX**(generator): library mode scans direct deps only, app mode scans transitive. ([892f959e](https://github.com/zonnedev/dart-boot/commit/892f959e03b93ee325d2a6bc797262b1916ab9f3))
 - **FEAT**(core): @ConfigurationProperties, lazy routes, self-contained boot_http_client. ([1d148204](https://github.com/zonnedev/dart-boot/commit/1d148204a6866779c455ace6f16cd84d17e08b19))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_http_common` - `v0.2.0`

 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_http_generator` - `v0.2.0`

 - **FIX**(generator): library mode scans direct deps only, app mode scans transitive. ([892f959e](https://github.com/zonnedev/dart-boot/commit/892f959e03b93ee325d2a6bc797262b1916ab9f3))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_scheduling` - `v0.2.0`

 - **REFACTOR**(core): consolidate parseDuration into boot_core. ([96b5bcc7](https://github.com/zonnedev/dart-boot/commit/96b5bcc74b1ec3144a7cfc934f96a7baafdc95db))
 - **FIX**(generator): avoid Type name conflicts in generated beanType getter. ([098d7596](https://github.com/zonnedev/dart-boot/commit/098d759677581ae6a70010ae35f764e8c659de7c))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_security` - `v0.2.0`

 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_security_jwt` - `v0.2.0`

 - **FIX**(generator): library mode scans direct deps only, app mode scans transitive. ([892f959e](https://github.com/zonnedev/dart-boot/commit/892f959e03b93ee325d2a6bc797262b1916ab9f3))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_serialization_generator` - `v0.2.0`

 - **FIX**(generator): library mode scans direct deps only, app mode scans transitive. ([892f959e](https://github.com/zonnedev/dart-boot/commit/892f959e03b93ee325d2a6bc797262b1916ab9f3))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_test` - `v0.2.0`

 - **REFACTOR**(core): consolidate parseDuration into boot_core. ([96b5bcc7](https://github.com/zonnedev/dart-boot/commit/96b5bcc74b1ec3144a7cfc934f96a7baafdc95db))
 - **FEAT**(core): @ConfigurationProperties, lazy routes, self-contained boot_http_client. ([1d148204](https://github.com/zonnedev/dart-boot/commit/1d148204a6866779c455ace6f16cd84d17e08b19))
 - **FEAT**(test): WebSocket testing and integration test support. ([110553b2](https://github.com/zonnedev/dart-boot/commit/110553b273ab6bf25ff5b371f403bda02af38800))
 - **FEAT**(test): WebSocket testing and integration test support. ([22df3878](https://github.com/zonnedev/dart-boot/commit/22df387820597139dfa21af867b7539a81570096))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

#### `boot_cli` - `v0.1.6`

 - **FEAT**(cli): generate integration test in boot create app. ([2b53cfbe](https://github.com/zonnedev/dart-boot/commit/2b53cfbe41fd9b6c464a0bffcfa80ad933e268e5))

#### `boot_http_client` - `v0.1.3`

 - **REFACTOR**(core): consolidate parseDuration into boot_core. ([96b5bcc7](https://github.com/zonnedev/dart-boot/commit/96b5bcc74b1ec3144a7cfc934f96a7baafdc95db))
 - **FEAT**(core): @ConfigurationProperties, lazy routes, self-contained boot_http_client. ([1d148204](https://github.com/zonnedev/dart-boot/commit/1d148204a6866779c455ace6f16cd84d17e08b19))


## 2026-05-25

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_core` - `v0.1.3`](#boot_core---v013)
 - [`boot_generator` - `v0.1.3`](#boot_generator---v013)
 - [`boot_http_client` - `v0.1.2`](#boot_http_client---v012)
 - [`boot_http_client_generator` - `v0.1.1`](#boot_http_client_generator---v011)
 - [`boot_aop` - `v0.1.1+4`](#boot_aop---v0114)
 - [`boot_events` - `v0.1.1+4`](#boot_events---v0114)
 - [`boot_scheduling` - `v0.1.1+4`](#boot_scheduling---v0114)
 - [`boot_serialization` - `v0.1.1+5`](#boot_serialization---v0115)
 - [`boot_http_common` - `v0.1.2+1`](#boot_http_common---v0121)
 - [`boot_http` - `v0.1.2+2`](#boot_http---v0122)
 - [`boot` - `v0.1.1+7`](#boot---v0117)
 - [`boot_security` - `v0.1.1+2`](#boot_security---v0112)
 - [`boot_security_jwt` - `v0.1.1+2`](#boot_security_jwt---v0112)
 - [`boot_test` - `v0.1.1+7`](#boot_test---v0117)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `boot_aop` - `v0.1.1+4`
 - `boot_events` - `v0.1.1+4`
 - `boot_scheduling` - `v0.1.1+4`
 - `boot_serialization` - `v0.1.1+5`
 - `boot_http_common` - `v0.1.2+1`
 - `boot_http` - `v0.1.2+2`
 - `boot` - `v0.1.1+7`
 - `boot_security` - `v0.1.1+2`
 - `boot_security_jwt` - `v0.1.1+2`
 - `boot_test` - `v0.1.1+7`

---

#### `boot_core` - `v0.1.3`

 - **FEAT**: decouple @Client generator via @BeanSource plugin architecture. ([304a2097](https://github.com/zonnedev/dart-boot/commit/304a20973c508e7c298cb9ee8de2825fb8aa5ea9))

#### `boot_generator` - `v0.1.3`

 - **FEAT**: decouple @Client generator via @BeanSource plugin architecture. ([304a2097](https://github.com/zonnedev/dart-boot/commit/304a20973c508e7c298cb9ee8de2825fb8aa5ea9))

#### `boot_http_client` - `v0.1.2`

 - **FEAT**: decouple @Client generator via @BeanSource plugin architecture. ([304a2097](https://github.com/zonnedev/dart-boot/commit/304a20973c508e7c298cb9ee8de2825fb8aa5ea9))

#### `boot_http_client_generator` - `v0.1.1`

 - **FEAT**: decouple @Client generator via @BeanSource plugin architecture. ([304a2097](https://github.com/zonnedev/dart-boot/commit/304a20973c508e7c298cb9ee8de2825fb8aa5ea9))


## 2026-05-25

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_generator` - `v0.1.2+1`](#boot_generator---v0121)
 - [`boot_security` - `v0.1.1+1`](#boot_security---v0111)
 - [`boot_security_jwt` - `v0.1.1+1`](#boot_security_jwt---v0111)
 - [`boot_http` - `v0.1.2+1`](#boot_http---v0121)
 - [`boot` - `v0.1.1+6`](#boot---v0116)
 - [`boot_test` - `v0.1.1+6`](#boot_test---v0116)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `boot_http` - `v0.1.2+1`
 - `boot` - `v0.1.1+6`
 - `boot_test` - `v0.1.1+6`

---

#### `boot_generator` - `v0.1.2+1`

 - **FIX**: resolve publish warnings and unused declaration. ([15ed3f00](https://github.com/zonnedev/dart-boot/commit/15ed3f000b086a094cb2b224cf7c5f24e6f1b808))

#### `boot_security` - `v0.1.1+1`

 - **FIX**: resolve publish warnings and unused declaration. ([15ed3f00](https://github.com/zonnedev/dart-boot/commit/15ed3f000b086a094cb2b224cf7c5f24e6f1b808))

#### `boot_security_jwt` - `v0.1.1+1`

 - **FIX**: resolve publish warnings and unused declaration. ([15ed3f00](https://github.com/zonnedev/dart-boot/commit/15ed3f000b086a094cb2b224cf7c5f24e6f1b808))


## 2026-05-25

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_generator` - `v0.1.2`](#boot_generator---v012)
 - [`boot_http` - `v0.1.2`](#boot_http---v012)
 - [`boot_http_common` - `v0.1.2`](#boot_http_common---v012)
 - [`boot_security` - `v0.1.1`](#boot_security---v011)
 - [`boot_security_jwt` - `v0.1.1`](#boot_security_jwt---v011)
 - [`boot` - `v0.1.1+5`](#boot---v0115)
 - [`boot_http_client` - `v0.1.1+5`](#boot_http_client---v0115)
 - [`boot_test` - `v0.1.1+5`](#boot_test---v0115)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `boot` - `v0.1.1+5`
 - `boot_http_client` - `v0.1.1+5`
 - `boot_test` - `v0.1.1+5`

---

#### `boot_generator` - `v0.1.2`

 - **FEAT**(boot_security): create security module with pluggable token interfaces. ([1dd84d00](https://github.com/zonnedev/dart-boot/commit/1dd84d003f1be3d8bb9570cf6e8ba2160d4b5a4a))

#### `boot_http` - `v0.1.2`

 - **FEAT**(boot_security): create security module with pluggable token interfaces. ([1dd84d00](https://github.com/zonnedev/dart-boot/commit/1dd84d003f1be3d8bb9570cf6e8ba2160d4b5a4a))

#### `boot_http_common` - `v0.1.2`

 - **FEAT**(boot_security): create security module with pluggable token interfaces. ([1dd84d00](https://github.com/zonnedev/dart-boot/commit/1dd84d003f1be3d8bb9570cf6e8ba2160d4b5a4a))

#### `boot_security` - `v0.1.1`

 - **FEAT**(boot_security): create security module with pluggable token interfaces. ([1dd84d00](https://github.com/zonnedev/dart-boot/commit/1dd84d003f1be3d8bb9570cf6e8ba2160d4b5a4a))

#### `boot_security_jwt` - `v0.1.1`

 - **FEAT**(boot_security): create security module with pluggable token interfaces. ([1dd84d00](https://github.com/zonnedev/dart-boot/commit/1dd84d003f1be3d8bb9570cf6e8ba2160d4b5a4a))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot` - `v0.1.1+4`](#boot---v0114)
 - [`boot_aop` - `v0.1.1+3`](#boot_aop---v0113)
 - [`boot_cli` - `v0.1.5+2`](#boot_cli---v0152)
 - [`boot_core` - `v0.1.2+2`](#boot_core---v0122)
 - [`boot_events` - `v0.1.1+3`](#boot_events---v0113)
 - [`boot_generator` - `v0.1.1+4`](#boot_generator---v0114)
 - [`boot_http` - `v0.1.1+4`](#boot_http---v0114)
 - [`boot_http_client` - `v0.1.1+4`](#boot_http_client---v0114)
 - [`boot_http_common` - `v0.1.1+4`](#boot_http_common---v0114)
 - [`boot_scheduling` - `v0.1.1+3`](#boot_scheduling---v0113)
 - [`boot_serialization` - `v0.1.1+4`](#boot_serialization---v0114)
 - [`boot_test` - `v0.1.1+4`](#boot_test---v0114)

---

#### `boot` - `v0.1.1+4`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_aop` - `v0.1.1+3`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_cli` - `v0.1.5+2`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_core` - `v0.1.2+2`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_events` - `v0.1.1+3`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_generator` - `v0.1.1+4`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_http` - `v0.1.1+4`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_http_client` - `v0.1.1+4`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_http_common` - `v0.1.1+4`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_scheduling` - `v0.1.1+3`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_serialization` - `v0.1.1+4`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

#### `boot_test` - `v0.1.1+4`

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot` - `v0.1.1+3`](#boot---v0113)
 - [`boot_aop` - `v0.1.1+2`](#boot_aop---v0112)
 - [`boot_events` - `v0.1.1+2`](#boot_events---v0112)
 - [`boot_generator` - `v0.1.1+3`](#boot_generator---v0113)
 - [`boot_http` - `v0.1.1+3`](#boot_http---v0113)
 - [`boot_http_client` - `v0.1.1+3`](#boot_http_client---v0113)
 - [`boot_http_common` - `v0.1.1+3`](#boot_http_common---v0113)
 - [`boot_scheduling` - `v0.1.1+2`](#boot_scheduling---v0112)
 - [`boot_serialization` - `v0.1.1+3`](#boot_serialization---v0113)
 - [`boot_test` - `v0.1.1+3`](#boot_test---v0113)

---

#### `boot` - `v0.1.1+3`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_aop` - `v0.1.1+2`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_events` - `v0.1.1+2`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_generator` - `v0.1.1+3`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_http` - `v0.1.1+3`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_http_client` - `v0.1.1+3`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_http_common` - `v0.1.1+3`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_scheduling` - `v0.1.1+2`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_serialization` - `v0.1.1+3`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

#### `boot_test` - `v0.1.1+3`

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot` - `v0.1.1+2`](#boot---v0112)
 - [`boot_aop` - `v0.1.1+1`](#boot_aop---v0111)
 - [`boot_cli` - `v0.1.5+1`](#boot_cli---v0151)
 - [`boot_core` - `v0.1.2+1`](#boot_core---v0121)
 - [`boot_events` - `v0.1.1+1`](#boot_events---v0111)
 - [`boot_generator` - `v0.1.1+2`](#boot_generator---v0112)
 - [`boot_http` - `v0.1.1+2`](#boot_http---v0112)
 - [`boot_http_client` - `v0.1.1+2`](#boot_http_client---v0112)
 - [`boot_http_common` - `v0.1.1+2`](#boot_http_common---v0112)
 - [`boot_scheduling` - `v0.1.1+1`](#boot_scheduling---v0111)
 - [`boot_serialization` - `v0.1.1+2`](#boot_serialization---v0112)
 - [`boot_test` - `v0.1.1+2`](#boot_test---v0112)

---

#### `boot` - `v0.1.1+2`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_aop` - `v0.1.1+1`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_cli` - `v0.1.5+1`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_core` - `v0.1.2+1`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_events` - `v0.1.1+1`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_generator` - `v0.1.1+2`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_http` - `v0.1.1+2`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_http_client` - `v0.1.1+2`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_http_common` - `v0.1.1+2`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_scheduling` - `v0.1.1+1`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_serialization` - `v0.1.1+2`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

#### `boot_test` - `v0.1.1+2`

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_http` - `v0.1.1+1`](#boot_http---v0111)
 - [`boot_http_client` - `v0.1.1+1`](#boot_http_client---v0111)
 - [`boot_http_common` - `v0.1.1+1`](#boot_http_common---v0111)
 - [`boot_serialization` - `v0.1.1+1`](#boot_serialization---v0111)
 - [`boot` - `v0.1.1+1`](#boot---v0111)
 - [`boot_generator` - `v0.1.1+1`](#boot_generator---v0111)
 - [`boot_test` - `v0.1.1+1`](#boot_test---v0111)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `boot` - `v0.1.1+1`
 - `boot_generator` - `v0.1.1+1`
 - `boot_test` - `v0.1.1+1`

---

#### `boot_http` - `v0.1.1+1`

 - **FIX**(boot_http_common): add ClientFilterChain for type-safe client filter chaining. ([4d2af9a6](https://github.com/zonnedev/dart-boot/commit/4d2af9a6a486f03aaf38dc8b6969273aafe11344))

#### `boot_http_client` - `v0.1.1+1`

 - **FIX**(boot_http_common): add ClientFilterChain for type-safe client filter chaining. ([4d2af9a6](https://github.com/zonnedev/dart-boot/commit/4d2af9a6a486f03aaf38dc8b6969273aafe11344))

#### `boot_http_common` - `v0.1.1+1`

 - **FIX**(boot_http_common): add ClientFilterChain for type-safe client filter chaining. ([4d2af9a6](https://github.com/zonnedev/dart-boot/commit/4d2af9a6a486f03aaf38dc8b6969273aafe11344))

#### `boot_serialization` - `v0.1.1+1`

 - **FIX**(boot_http_common): add ClientFilterChain for type-safe client filter chaining. ([4d2af9a6](https://github.com/zonnedev/dart-boot/commit/4d2af9a6a486f03aaf38dc8b6969273aafe11344))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_cli` - `v0.1.5`](#boot_cli---v015)

---

#### `boot_cli` - `v0.1.5`

 - **FEAT**(boot_cli): derive SDK constraint from framework's pubspec via version hook. ([aff7e080](https://github.com/zonnedev/dart-boot/commit/aff7e080b4b679e7523a7bc5d323d58bd0097097))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_cli` - `v0.1.4`](#boot_cli---v014)

---

#### `boot_cli` - `v0.1.4`

 - **FEAT**(boot_cli): track framework version independently from CLI version. ([bdfb08c1](https://github.com/zonnedev/dart-boot/commit/bdfb08c1b732413724fe392813f8c12ba07f2254))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_cli` - `v0.1.3+1`](#boot_cli---v0131)

---

#### `boot_cli` - `v0.1.3+1`

 - **FIX**(workspace): use preCommit hook for version.dart sync. ([46309947](https://github.com/zonnedev/dart-boot/commit/46309947b80724eddb1277b36dbc9b400488958f))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_cli` - `v0.1.3`](#boot_cli---v013)

---

#### `boot_cli` - `v0.1.3`

 - **FEAT**(boot_cli): add --version flag. ([bc583971](https://github.com/zonnedev/dart-boot/commit/bc583971f94e068987ae41e24166a8f4b78605f6))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot_cli` - `v0.1.2`](#boot_cli---v012)

---

#### `boot_cli` - `v0.1.2`

 - **FEAT**(boot_cli): add --git and --ref flags to boot create app/library. ([a14eef39](https://github.com/zonnedev/dart-boot/commit/a14eef39049f2de100a94b00407f9411f7cea53d))


## 2026-05-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`boot` - `v0.1.1`](#boot---v011)
 - [`boot_aop` - `v0.1.1`](#boot_aop---v011)
 - [`boot_cli` - `v0.1.1`](#boot_cli---v011)
 - [`boot_core` - `v0.1.1`](#boot_core---v011)
 - [`boot_events` - `v0.1.1`](#boot_events---v011)
 - [`boot_generator` - `v0.1.1`](#boot_generator---v011)
 - [`boot_http` - `v0.1.1`](#boot_http---v011)
 - [`boot_http_client` - `v0.1.1`](#boot_http_client---v011)
 - [`boot_http_common` - `v0.1.1`](#boot_http_common---v011)
 - [`boot_scheduling` - `v0.1.1`](#boot_scheduling---v011)
 - [`boot_serialization` - `v0.1.1`](#boot_serialization---v011)
 - [`boot_test` - `v0.1.1`](#boot_test---v011)

---

#### `boot` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_aop` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_cli` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_core` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_events` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_generator` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_http` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_http_client` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_http_common` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_scheduling` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_serialization` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

#### `boot_test` - `v0.1.1`

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

