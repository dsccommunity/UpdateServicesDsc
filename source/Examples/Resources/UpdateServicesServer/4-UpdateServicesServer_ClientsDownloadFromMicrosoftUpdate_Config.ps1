<#PSScriptInfo
.VERSION 1.0.0
.GUID 6f5a867c-d6b6-4736-ba6b-ebe72970ef5d
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
        Configure a WSUS server whose clients download update files from Microsoft Update.

    .DESCRIPTION
        This configuration sets up a WSUS server that stores update metadata and
        manages approvals, but has its clients download the update files directly
        from Microsoft Update rather than from the server. Setting ContentDir to
        an empty string is what turns local storage off.

        The remaining settings tune the server itself: metadata is compressed to
        save bandwidth, BITS downloads run at foreground priority to work around
        proxy servers that mishandle HTTP 1.1 range requests, and the number of
        concurrent downloads is capped.

    .PARAMETER SetupCredential
        Credential used to perform the initial WSUS post-installation configuration.

    .EXAMPLE
        UpdateServicesServer_ClientsDownloadFromMicrosoftUpdate_Config -SetupCredential (Get-Credential)

        Compiles a configuration that sets up a WSUS server whose clients
        download update files from Microsoft Update.
#>
Configuration UpdateServicesServer_ClientsDownloadFromMicrosoftUpdate_Config
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
            Ensure                                   = 'Present'
            SetupCredential                          = $SetupCredential

            # An empty content directory means clients download from Microsoft Update.
            ContentDir                               = ''

            UpstreamServerName                       = ''
            UpstreamServerReplica                    = $false

            ProxyServerName                          = ''

            Languages                                = @('*')
            Products                                 = @('Windows*')
            Classifications                          = @('*')

            SynchronizeAutomatically                 = $true
            SynchronizeAutomaticallyTimeOfDay        = '02:30:00'
            SynchronizationsPerDay                   = 1

            # Keep WSUS itself, and approvals, up to date automatically.
            AutoApproveWsusInfrastructureUpdates     = $true
            AutoRefreshUpdateApprovals               = $true
            AutoRefreshUpdateApprovalsDeclineExpired = $true

            IIsDynamicCompression                    = $true
            BitsDownloadPriorityForeground           = $true
            LocalPublishingMaxCabSize                = 100
            MaxSimultaneousFileDownloads             = 20

            ClientTargetingMode                      = 'Client'
        }
    }
}
