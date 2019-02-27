# UpdateServicesDsc

[![Build status](https://ci.appveyor.com/api/projects/status/wncsr23e1fqbv4nt?svg=true)](https://ci.appveyor.com/project/mgreenegit/UpdateServicesDsc)

The **UpdateServicesDsc** module is a part of the Windows PowerShell Desired State Configuration (DSC) Resource Kit, which is a collection of DSC Resources.

This module contains the **UpdateServicesApprovalRule, UpdateServicesCleanup, and UpdateServicesServer** resources.

## Installation

To install **UpdateServicesDsc** module, on a machine with Windows Management Framework version 5 or newer from an elevated PowerShell session run:

```PowerShell
Install-Module UpdateServicesDsc
```

To confirm installation

```PowerShell
Get-DSCResource UpdateServicesDsc
```

## Requirements

This module requires a minimum version of PowerShell v5.0.

## Details

**UpdateServicesApprovalRule** resource has following properties

- **Ensure**: An enumerated value that describes if the ApprovalRule is available
- **Name**: Name of the approval rule.
- **Classifications**: Classifications in the approval rule.
- **Products**: Products in the approval rule.
- **ComputerGroups**: Computer groups the approval rule applies to.
- **Enabled**: Whether the approval rule is enabled.
- **Synchronize**: Synchronize after creating or updating the approval rule.

**UpdateServicesCleanup** resource has following properties:

- **Ensure**: An enumerated value that describes if the WSUS cleanup task exists.
- **DeclineSupersededUpdates**: Decline updates that have not been approved fo 30 days or more, are not currently needed by any clients, and are superseded by an approved update.
- **DeclineExpiredUpdates**: Decline updates that aren't approved and have been expired by Microsoft.
- **CleanupObsoleteUpdates**: Delete updates that are expired and have not been approved for 30 days or more, and delete older update revisions that have not been approved for 30 days or more.
- **CompressUpdates**: Compress updates.
- **CleanupObsoleteComputers**: Delete computers that have not contacted the server in 30 days or more.
- **CleanupUnneededContentFiles**: Delete update files that aren't needed by updates or downstream servers.
- **CleanupLocalPublishedContentFiles**: Cleanup local published content files.
- **TimeOfDay** Time of day to start cleanup.

**UpdateServicesServer** resource has following properties:

- **Ensure**: An enumerated value that describes if WSUS is configured.
- **SetupCredential**: Credential to be used to perform the initial configuration.
- **SQLServer**: SQL Server for the WSUS database, omit for Windows Internal Database.
- **ContentDir**: Folder for WSUS update files.
- **UpdateImprovementProgram**: Join the Microsoft Update Improvement Program.
- **UpstreamServerName**: Upstream WSUS server, omit for Microsoft Update.
- **UpstreamServerPort**: Port of upstream WSUS server.
- **UpstreamServerSSL**: Use SSL with upstream WSUS server.
- **UpstreamServerReplica**: Replica of upstream WSUS server.
- **ProxyServerName**: Proxy server to use when synchronizing, omit for no proxy.
- **ProxyServerPort**: Proxy server port.
- **ProxyServerCredential**: Proxy server credential, omit for anonymous.
- **ProxyServerCredentialUsername**: Proxy server credential username.
- **ProxyServerBasicAuthentication**: Allow proxy server basic authentication.
- **Languages**: Update languages, * for all.
- **Products**: Update products, * for all.
- **Classifications**: Update classifications, * for all.
- **SynchronizeAutomatically**: Synchronize automatically.
- **SynchronizeAutomaticallyTimeOfDay**: First synchronization.
- **SynchronizationsPerDay**: Synchronizations per day.
- **Synchronize**: Begin initial synchronization.
- **RunRuleNow**: Run Approval Rule on existing content.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Versions

### 1.0.76.0

- Fixed PSSA rule override

### 1.0.75.0

- Adjusted PDT to let processes run for up to 3 minutes

### 1.0.74.0

- Test issues
  - A number of PSSA rules evolved since the tests were written. Made all corrections.

### 1.0.73.0

- Resolve issues
  - Get was failing during deployment because ReferenceObject was null

### 1.0.47.0

- High quality DSC module with the following updates:
  - Rename to WSUSDsc
  - Add Integration tests
  - Fix typo in ReadMe
  - Add RunRuleNow param to WSUSApprovalRule resource
  - Fix error in WSUSServer resource causing Get- to fail

### 1.0.0.0

- Initial release of xWSUS module with coverage for the following areas:
  - Managing xWSUS rules for content synchronization.
  - Managing xWSUS rules for content cleanup and compression.
  - Managing xWSUS service configuration

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
