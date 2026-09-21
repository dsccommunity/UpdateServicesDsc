<#PSScriptInfo
.VERSION 1.0.0
.GUID ab89b744-fd9a-43b7-8110-3fd03141a996
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
        Configure a downstream WSUS replica server behind a proxy.

    .DESCRIPTION
        This configuration installs and configures a WSUS server as a replica of
        an upstream WSUS server, synchronizing through an authenticating proxy.

        A replica server inherits its languages, products, classifications and
        approvals from its upstream server, so those settings are not specified
        here. Update binaries are fetched from Microsoft Update rather than from
        the upstream server, to keep traffic off the link between the two.

    .PARAMETER SetupCredential
        Credential used to perform the initial WSUS post-installation configuration.

    .PARAMETER ProxyServerCredential
        Credential used to authenticate to the proxy server.

    .EXAMPLE
        UpdateServicesServer_DownstreamReplicaServer_Config -SetupCredential (Get-Credential) -ProxyServerCredential (Get-Credential)

        Compiles a configuration that sets up a WSUS replica server which
        synchronizes through an authenticating proxy.
#>
Configuration UpdateServicesServer_DownstreamReplicaServer_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ProxyServerCredential
    )

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesServer 'WsusReplicaServer'
        {
            Ensure                         = 'Present'
            SetupCredential                = $SetupCredential

            UpstreamServerName             = 'wsus.contoso.com'
            UpstreamServerPort             = 8531
            UpstreamServerSSL              = $true
            UpstreamServerReplica          = $true

            ProxyServerName                = 'proxy.contoso.com'
            ProxyServerPort                = 8080
            ProxyServerCredential          = $ProxyServerCredential
            ProxyServerBasicAuthentication = $false

            ContentDir                     = 'C:\WSUS'
            DownloadUpdateBinariesAsNeeded = $true

            # Fetch update binaries from Microsoft Update, not from the upstream server.
            GetContentFromMU               = $true

            SynchronizeAutomatically       = $true
            SynchronizationsPerDay         = 3

            # Report detailed computer and update status up to the upstream server.
            DoDetailedRollup               = $true

            ClientTargetingMode            = 'Client'
        }
    }
}
