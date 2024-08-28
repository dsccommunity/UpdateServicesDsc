# UpdateServicesDsc

[![Build Status](https://dev.azure.com/dsccommunity/UpdateServicesDsc/_apis/build/status/dsccommunity.UpdateServicesDsc?branchName=master)](https://dev.azure.com/dsccommunity/UpdateServicesDsc/_build/latest?definitionId=21&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/UpdateServicesDsc/21/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/UpdateServicesDsc/21/master)](https://dsccommunity.visualstudio.com/UpdateServicesDsc/_test/analytics?definitionId=21&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/UpdateServicesDsc?label=UpdateServicesDsc%20Preview)](https://www.powershellgallery.com/packages/UpdateServicesDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/UpdateServicesDsc?label=UpdateServicesDsc)](https://www.powershellgallery.com/packages/UpdateServicesDsc/)

The **UpdateServicesDsc** module contains DSC resources
for deployment and configuration of Windows Server Update Services.

## Code of Conduct

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Support

This module is community maintained as a best-effort open source project
and has no expressed support from any individual or organization.

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Installation

### From GitHub source code

To manually install the module, download the source code from GitHub and unzip
the contents to the '$env:ProgramFiles\WindowsPowerShell\Modules' folder.

### From PowerShell Gallery

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

```powershell
Find-Module -Name UpdateServicesDsc | Install-Module
```

To confirm installation, run the below command and ensure you see the SQL Server
DSC resources available:

```powershell
Get-DscResource -Module UpdateServicesDsc
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
* **DeclineSupersededUpdates**: Decline updates that have not been approved for
 30 days or more, are not currently needed by any clients, and are superseded by an approved update.
* **DeclineExpiredUpdates**: Decline updates that aren't approved and have been expired by Microsoft.
* **CleanupObsoleteUpdates**: Delete updates that are expired and have not been
 approved for 30 days or more, and delete older update revisions that have not
 been approved for 30 days or more.
* **CompressUpdates**: Compress updates.
* **CleanupObsoleteComputers**: Delete computers that have not contacted the server in 30 days or more.
* **CleanupUnneededContentFiles**: Delete update files that aren't needed by updates or downstream servers.
* **CleanupLocalPublishedContentFiles**: Cleanup local published content files.
* **TimeOfDay** Time of day to start cleanup.

**UpdateServicesComputerTargetGroup** resource has following properties:

* **Ensure**: An enumerated value that describes if the Computer Target Group exists.
* **Name**: Name of the Computer Target Group.
* **Path**: Path to the Computer Target Group in the format 'Parent/Child'.

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
* **ClientTargetingMode**: An enumerated value that describes if how the Target Groups are populated.

## Versions

Please refer to the [Changelog](CHANGELOG.md)
