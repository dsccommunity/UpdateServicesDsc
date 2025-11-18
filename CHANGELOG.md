# Change log for UpdateServicesDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- UpdateServicesServer
  - BREAKING CHANGE: All parameters will now only be set when specifically applied
    rather than defaulting to hardcoded values if left undefined.
    In particular set ContentDir, Languages, Products, Classifications as needed.
    Fixes [issue #55](https://github.com/dsccommunity/UpdateServicesDsc/issues/55)
- Updated initial offline package sync WSUS.cab.
- Changed azure pipeline to use latest version of ubuntu and change the management
  of pipeline artifact
- Updated build.ps1 script and build.yaml.
- Changed default timeout in Wait-Win32ProcessStart function for cab installation.
- Updated pester test to support pester v5
- Updated ReadMe.md to removed `RunRuleNow` parameter.
- UpdateServicesApprovalRule
  - Updated to load localization strings correctly.
- UpdateServicesCleanup
  - Updated to load localization strings correctly.
- UpdateServicesServer
  - Updated to load localization strings correctly.
- Internal PDT helper module
  - Updated to load localization strings correctly.
- General code cleanup
- Updated Classifications ID reference with additional potential classification GUIDs
- Updated module to use latest Sampler files and modules.
- Generated stubs for `UpdateServices` module.
- Updated scriptanalyzer settings to latest.
- Rename `Tests` directory to `tests`.
- Updated Unit tests to Pester 5 DscCommunity format.
- Update references of `master` branch to `main`.
- Fix Doc Generation.
- Update `azure-pipelines` to use latest pattern.
- Rename resources from MSFT_ to DSC_. Fixes [#87](https://github.com/dsccommunity/UpdateServicesDsc/issues/87).

### Added

- UpdateServicesServer
  - Added support for the following settings:
    - ContentDir can be set to empty string for clients to download from Microsoft Update.
    - Updates are downloaded only when they are approved.
    - Express installation packages should be downloaded.
    - Update binaries are downloaded from Microsoft Update instead of from the
      upstream server.
      Fixes [issue #39](https://github.com/dsccommunity/UpdateServicesDsc/issues/39)
    - WSUS infrastructure updates are approved automatically.
    - The latest revision of an update should be approved automatically.
    - An update should be automatically declined when it is revised to be expired
      and AutoRefreshUpdateApprovals is enabled.
    - The downstream server should roll up detailed computer and update status information.
    - Email status notifications and SMTP settings, including status notifications DST fix.
      Fixes [issue #15](https://github.com/dsccommunity/UpdateServicesDsc/issues/15)
    - Use Xpress Encoding to compress update metadata.
    - Use foreground priority for BITS downloads
    - The maximum .cab file size (in megabytes) that Local Publishing will create.
    - The maximum number of concurrent update downloads.
- Added UpdateServicesComputerTargetGroup Resource to manage computer target
  groups ([issue #44](https://github.com/dsccommunity/UpdateServicesDsc/issues/44))
- Added TestKitchen files for integration tests
- Added required modules, Sampler.GitHubTasks, powershell-yaml
- Added wildcard support in Products parameter of UpdatesServicesServer resource.
  ([issue #13](https://github.com/dsccommunity/UpdateServicesDsc/issues/13))

### Fixed

- UpdateServicesApprovalRule
  - Before running, ensure that UpdateServices PowerShell module is installed.
  - Updated error handling to specifically catch errors if WSUS Server is unavailable.
  - Added check to make sure Post Install was successful before trying to get resource.
  - Fix issue [#64](https://github.com/dsccommunity/UpdateServicesDsc/issues/61)
    Allow multiple product categories with same name (e.g. "Windows Admin Center")
  - Removed ErrorRecord from New-InvalidOperationException outside of try / catch.
- UpdateServicesCleanup
  - Fix issue [#93](https://github.com/dsccommunity/UpdateServicesDsc/issues/93)
    Allow UpdateServicesCleanup resource to test and update TimeOfDay as needed.
- UpdateServicesComputerTargetGroup
  - Before running, ensure that UpdateServices PowerShell module is installed.
  - Updated error handling to specifically catch errors if WSUS Server is unavailable.
  - Added check to make sure Post Install was successful before trying to get resource.
- UpdateServicesServer
  - Before running, ensure that UpdateServices PowerShell module is installed.
  - Updated error handling to specifically catch errors if WSUS Server is unavailable.
  - Added check to make sure Post Install was successful before trying to get resource.
  - Update setting dependency logic to stop incompatible settings being set / returned.
  - Get Languages as a string array instead of comma separated values.
    Fix issue [#76](https://github.com/dsccommunity/UpdateServicesDsc/issues/76)
- Stopped PDT.psm1 returning boolean 'true' alongside normal output as creating process.    
- Fix deploy job in AzurePipeline, Added Sampler.GithubTasks in build.yaml
- Fix issue #61 and #67, with add a foreach loop when `Set-TargetResource` found
multiple products for the same `Title`.
- Fix issue #58 and #66, with removed `-ErrorRecord` parameter on `New-InvalidResultException`
 because `$_` not contain an exception.
- Fix issue [#62](https://github.com/dsccommunity/UpdateServicesDsc/issues/62),
 Fixed verbose output of Languages in UpdateServiceServer
- Fix issue [#63](https://github.com/dsccommunity/UpdateServicesDsc/issues/63),
 Fixed verbose output of WSUS server in UpdateServicesApprovalRule
- Fixed the `azure-pipelines.yml` to trigger on main not master.

## [1.2.0] - 2020-05-18

### Changed

- Update for HQRM standard
- Changing to new CI pipeline

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
