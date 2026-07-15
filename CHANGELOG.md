# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-07-15

### Added

- support for OTP 24 through 29
- an explicit minimum OTP version: `minimum_otp_vsn` is now declared as `22`
  (previously unspecified), with OTP 24+ being what is actually supported and
  tested
- a Common Test suite (the library previously had no automated tests)
- `ex_doc`-based documentation with EEP-48 (`-moduledoc`/`-doc`) attributes
- dev tooling: `erlfmt`, `rebar3_hank` and `elvis` (via `rebar3_lint`)

### Changed

- CI to GitHub Actions with an OTP 24-29 matrix
- build system to the current rebar3-based Makefile / `rebar.config`

### Removed

- obsolete `COMPILE_NATIVE_ERLQUAD` HiPE compilation flag (HiPE was removed
  in OTP 24)
- the pandoc/edoc documentation shell scripts and tracked `doc/` output

## [1.1.2] - 2019-01-19

### Changed

- Hex package metadata to link to the GitLab mirror

## [1.1.1] - 2017-04-30

### Changed

- documentation and packaging

## [1.1.0] - 2016-04-23

### Added

- deep-list query variants

## [1.0.0] - 2016-04-01

### Added

- initial release
