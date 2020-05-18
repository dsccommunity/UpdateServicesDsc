# Change log for UpdateServicesDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2020-05-18

### Changed

- Update for HQRM standard
- Changing to new CI pipeline
- Updated inital offline package sync WSUS.cab

## [1.1.0.0] - 2019-06-20

### Changed

- Resolve feedback for HQRM
- Accept PR for client side targeting

### Fixed

- Fixed PSSA rule override

## [1.0.75.0] - 2018-03-31

### Changed

- Adjusted PDT to let processes run for up to 3 minutes

## [1.0.74.0] - 2018-03-31

### Fixed

- Test issues
  - A number of PSSA rules evolved since the tests were written. Made all corrections.

## [1.0.73.0] - 2018-03-07

### Fixed

- Resolve issues
  -* Get was failing during deployment because ReferenceObject was null

## [1.0.72.0] - 2018-03-06

### Added

- High quality DSC module with the following updates:
  - Rename to UpdateServicesDsc
  - Fix typo in ReadMe
  - Add RunRuleNow param to WSUSApprovalRule resource
  - Fix error in WSUSServer resource causing Get- to fail

- Initial release of xWSUS module with coverage for the following areas:
  - Managing xWSUS rules for content synchronization.
  - Managing xWSUS rules for content cleanup and compression.
  - Managing xWSUS service configuration
