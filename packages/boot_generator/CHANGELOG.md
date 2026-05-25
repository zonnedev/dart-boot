## 0.2.0+3

 - **FIX**(generator): suppress unused_element warning in generated app context. ([425c2d85](https://github.com/zonnedev/dart-boot/commit/425c2d854d64de66fecac21a785edd9bc02217a6))

## 0.2.0+2

 - **FIX**(generator): support named constructor parameters in bean definitions. ([7b3c0d6a](https://github.com/zonnedev/dart-boot/commit/7b3c0d6a0c5bc25ace9f878a58560596b1894bb5))

## 0.2.0+1

 - **REFACTOR**(core): move RouteRegistry interface to boot_core, decouple module from boot_http. ([bb34c6fe](https://github.com/zonnedev/dart-boot/commit/bb34c6fe02ef3aa83ec050d90c72bce1e3a01fc4))

## 0.2.0

> Note: This release has breaking changes.

 - **REFACTOR**(generator): remove boot_http dependency from bean_generator. ([ac51f274](https://github.com/zonnedev/dart-boot/commit/ac51f2749358f47d836db81e6eb77b412b63d921))
 - **FIX**(generator): stop generating boot_context.g.dart for @BootLibrary packages. ([90a436ea](https://github.com/zonnedev/dart-boot/commit/90a436ea8f50bfd5e2c9587d1f71c41c607bedfb))
 - **FIX**(generator): library mode scans direct deps only, app mode scans transitive. ([892f959e](https://github.com/zonnedev/dart-boot/commit/892f959e03b93ee325d2a6bc797262b1916ab9f3))
 - **FIX**(generator): avoid Type name conflicts in generated beanType getter. ([098d7596](https://github.com/zonnedev/dart-boot/commit/098d759677581ae6a70010ae35f764e8c659de7c))
 - **FEAT**(core): @ConfigurationProperties, lazy routes, self-contained boot_http_client. ([1d148204](https://github.com/zonnedev/dart-boot/commit/1d148204a6866779c455ace6f16cd84d17e08b19))
 - **BREAKING** **REFACTOR**(generator): metadata-driven architecture with modular generators. ([4930ecb6](https://github.com/zonnedev/dart-boot/commit/4930ecb6fb5966fdce3a9bfadcd7c9b6b26db3a2))

## 0.1.3

 - **FEAT**: decouple @Client generator via @BeanSource plugin architecture. ([304a2097](https://github.com/zonnedev/dart-boot/commit/304a20973c508e7c298cb9ee8de2825fb8aa5ea9))

## 0.1.2+1

 - **FIX**: resolve publish warnings and unused declaration. ([15ed3f00](https://github.com/zonnedev/dart-boot/commit/15ed3f000b086a094cb2b224cf7c5f24e6f1b808))

## 0.1.2

 - **FEAT**(boot_security): create security module with pluggable token interfaces. ([1dd84d00](https://github.com/zonnedev/dart-boot/commit/1dd84d003f1be3d8bb9570cf6e8ba2160d4b5a4a))

## 0.1.1+4

 - **FIX**: correct repository branch from main to master. ([e67007d9](https://github.com/zonnedev/dart-boot/commit/e67007d909db6ed245e3ee40d809e135a5db061b))

## 0.1.1+3

 - **FIX**: use hosted version constraints for all inter-package dependencies. ([9f80a8f8](https://github.com/zonnedev/dart-boot/commit/9f80a8f8a0d37cc79a7b19dfeb06c3daf3be5762))

## 0.1.1+2

 - **FIX**: correct repository URLs to zonnedev/dart-boot. ([ee6ed62f](https://github.com/zonnedev/dart-boot/commit/ee6ed62fdce023117cdf24aad927cf4b8b6e40ea))

## 0.1.1+1

 - Update a dependency to the latest release.

## 0.1.1

 - **FEAT**: initial Boot Framework implementation. ([3e58c7fb](https://github.com/zonnedev/dart-boot/commit/3e58c7fb82f42d3debe8df0dedf85315da68c36a))

## 0.1.0
- Initial release
