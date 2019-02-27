# UpdateServicesDsc

The **UpdateServicesDsc** module contains DSC resources
for deployment and configuration of Windows Server Update Services.

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/wncsr23e1fqbv4nt?svg=true)](https://ci.appveyor.com/project/mgreenegit/UpdateServicesDsc)
[![codecov](https://codecov.io/gh/mgreenegit/UpdateServicesDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/mgreenegit/UpdateServicesDsc/branch/master)

This is the branch containing the latest release -
no contributions should be made directly to this branch.

### dev
[![Build status](https://ci.appveyor.com/api/projects/status/wncsr23e1fqbv4nt/branch/dev??svg=true)](https://ci.appveyor.com/project/mgreenegit/UpdateServicesDsc/branch/dev)
[![codecov](https://codecov.io/gh/mgreenegit/UpdateServicesDsc/branch/dev/graph/badge.svg)](https://codecov.io/gh/mgreenegit/UpdateServicesDsc/branch/dev)

This is the development branch
to which contributions should be proposed by contributors as pull requests.
This development branch will periodically be merged to the master branch,
and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Regardless of the way you want to contribute
we are tremendously happy to have you here.

There are several ways you can contribute.
You can submit an issue to report a bug.
You can submit an issue to request an improvement.
You can take part in discussions for issues.
You can review pull requests and comment on other contributors changes.
You can also improve the resources and tests,
or even create new resources,
by sending in pull requests yourself.

* If you want to submit an issue or take part in discussions,
  please browse the list of [issues](https://github.com/mgreenegit/UpdateServicesDsc/issues).
  Please check out [Contributing to the DSC Resource Kit](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md)
  on how to work with issues.
* If you want to review pull requests,
  please first check out the [Review Pull Request guidelines](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md#reviewing-pull-requests),
  and the browse the list of [pull requests](https://github.com/mgreenegit/UpdateServicesDsc/pulls)
  and look for those pull requests with label 'needs review'.
* If you want to improve this resource module,
  then please check out the following guidelines.
  * The specific [Contributing to SqlServerDsc](https://github.com/mgreenegit/UpdateServicesDsc/blob/dev/CONTRIBUTING.md)
    guidelines.
  * The common [Style Guidelines & Best Practices](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md).
  * The common [Testing Guidelines](https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md).
  * If you are new to GitHub (and git),
    then please check out [Getting Started with GitHub](https://github.com/PowerShell/DscResources/blob/master/GettingStartedWithGitHub.md).
  * If you are new to Pester and writing test, then please check out
    [Getting started with Pester](https://github.com/PowerShell/DscResources/blob/master/GettingStartedWithPester.md).

If you need any help along the way,
don't be afraid to ask.
We are here for each other.

## Installation

### From GitHub source code

To manually install the module, download the source code from GitHub and unzip
the contents to the '$env:ProgramFiles\WindowsPowerShell\Modules' folder.

### From PowerShell Gallery

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

```powershell
Find-Module -Name SqlServerDsc | Install-Module
```

To confirm installation, run the below command and ensure you see the SQL Server
DSC resources available:

```powershell
Get-DscResource -Module SqlServerDsc
```

## Requirements

The minimum Windows Management Framework (PowerShell) version required is 5.0
or higher, which ships with Windows 10 or Windows Server 2016,
but can also be installed on Windows 7 SP1, Windows 8.1,
Windows Server 2008 R2 SP1, Windows Server 2012 and Windows Server 2012 R2.

## Details

**UpdateServicesApprovalRule** resource has following properties

* **Ensure**: An enumerated value that describes if the ApprovalRule is available
* **Name**: Name of the approval rule.
* **Classifications**: Classifications in the approval rule.
* **Products**: Products in the approval rule.
* **ComputerGroups**: Computer groups the approval rule applies to.
* **Enabled**: Whether the approval rule is enabled.
* **Synchronize**: Synchronize after creating or updating the approval rule.

**UpdateServicesCleanup** resource has following properties:

* **Ensure**: An enumerated value that describes if the WSUS cleanup task exists.
* **DeclineSupersededUpdates**: Decline updates that have not been approved fo 30 days or more, are not currently needed by any clients, and are superseded by an approved update.
* **DeclineExpiredUpdates**: Decline updates that aren't approved and have been expired by Microsoft.
* **CleanupObsoleteUpdates**: Delete updates that are expired and have not been approved for 30 days or more, and delete older update revisions that have not been approved for 30 days or more.
* **CompressUpdates**: Compress updates.
* **CleanupObsoleteComputers**: Delete computers that have not contacted the server in 30 days or more.
* **CleanupUnneededContentFiles**: Delete update files that aren't needed by updates or downstream servers.
* **CleanupLocalPublishedContentFiles**: Cleanup local published content files.
* **TimeOfDay** Time of day to start cleanup.

**UpdateServicesServer** resource has following properties:

* **Ensure**: An enumerated value that describes if WSUS is configured.
* **SetupCredential**: Credential to be used to perform the initial configuration.
* **SQLServer**: SQL Server for the WSUS database, omit for Windows Internal Database.
* **ContentDir**: Folder for WSUS update files.
* **UpdateImprovementProgram**: Join the Microsoft Update Improvement Program.
* **UpstreamServerName**: Upstream WSUS server, omit for Microsoft Update.
* **UpstreamServerPort**: Port of upstream WSUS server.
* **UpstreamServerSSL**: Use SSL with upstream WSUS server.
* **UpstreamServerReplica**: Replica of upstream WSUS server.
* **ProxyServerName**: Proxy server to use when synchronizing, omit for no proxy.
* **ProxyServerPort**: Proxy server port.
* **ProxyServerCredential**: Proxy server credential, omit for anonymous.
* **ProxyServerCredentialUsername**: Proxy server credential username.
* **ProxyServerBasicAuthentication**: Allow proxy server basic authentication.
* **Languages**: Update languages, * for all.
* **Products**: Update products, * for all.
* **Classifications**: Update classifications, * for all.
* **SynchronizeAutomatically**: Synchronize automatically.
* **SynchronizeAutomaticallyTimeOfDay**: First synchronization.
* **SynchronizationsPerDay**: Synchronizations per day.
* **Synchronize**: Begin initial synchronization.
* **RunRuleNow**: Run Approval Rule on existing content.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Versions

### 1.1.0

* Resolve feedback for HQRM
* Accept PR for client side targeting

### 1.0.76.0

* Fixed PSSA rule override

### 1.0.75.0

* Adjusted PDT to let processes run for up to 3 minutes

### 1.0.74.0

* Test issues
  * A number of PSSA rules evolved since the tests were written. Made all corrections.

### 1.0.73.0

* Resolve issues
  * Get was failing during deployment because ReferenceObject was null

### 1.0.47.0

* High quality DSC module with the following updates:
  * Rename to WSUSDsc
  * Add Integration tests
  * Fix typo in ReadMe
  * Add RunRuleNow param to WSUSApprovalRule resource
  * Fix error in WSUSServer resource causing Get- to fail

### 1.0.0.0

* Initial release of xWSUS module with coverage for the following areas:
  * Managing xWSUS rules for content synchronization.
  * Managing xWSUS rules for content cleanup and compression.
  * Managing xWSUS service configuration

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

Thank you
[SqlServerDsc](https://github.com/PowerShell/SqlServerDsc/blob/dev/README.md)
maintainers for your awesome work on style and structure for DSC README files,
which is copied here.
