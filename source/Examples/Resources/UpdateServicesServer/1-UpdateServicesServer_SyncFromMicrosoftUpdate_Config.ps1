<#PSScriptInfo
.VERSION 1.0.0
.GUID 6ecd5a98-5fef-47ae-a5d5-1be098a61e8a
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/UpdateServicesDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/UpdateServicesDsc
.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png
.RELEASENOTES
First version.
#>

#Requires -Module UpdateServicesDsc

<#
    .SYNOPSIS
        Configure a standalone WSUS server that synchronizes from Microsoft Update.

    .DESCRIPTION
        This configuration installs and configures a standalone WSUS server that
        synchronizes directly from Microsoft Update, storing update files locally.

        Only the settings given below are applied. Any setting that is not
        specified is left as it is currently configured on the server, so list
        every setting that should be managed - including ContentDir, Languages,
        Products and Classifications.

    .PARAMETER SetupCredential
        Credential used to perform the initial WSUS post-installation configuration.

    .EXAMPLE
        UpdateServicesServer_SyncFromMicrosoftUpdate_Config -SetupCredential (Get-Credential)

        Compiles a configuration that sets up a standalone WSUS server which
        synchronizes from Microsoft Update.
#>
Configuration UpdateServicesServer_SyncFromMicrosoftUpdate_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesServer 'WsusServer'
        {
            Ensure                            = 'Present'
            SetupCredential                   = $SetupCredential

            # Store update files on this server, and download them only once approved.
            ContentDir                        = 'C:\WSUS'
            DownloadUpdateBinariesAsNeeded    = $true
            DownloadExpressPackages           = $false

            UpstreamServerName                = ''
            UpstreamServerReplica             = $false

            # No proxy server is used for synchronization.
            ProxyServerName                   = ''

            Languages                         = @('en')
            Products                          = @(
                'Windows Server 2022'
                'Windows 11'
            )
            Classifications                   = @(
                'E6CF1350-C01B-414D-A61F-263D14D133B4' # Critical Updates
                'E0789628-CE08-4437-BE74-2495B842F43B' # Definition Updates
                '0FA1201D-4330-4FA8-8AE9-B877473B6441' # Security Updates
            )

            SynchronizeAutomatically          = $true
            SynchronizeAutomaticallyTimeOfDay = '03:00:00'
            SynchronizationsPerDay            = 1

            ClientTargetingMode               = 'Client'
            UpdateImprovementProgram          = $false
        }
    }
}
