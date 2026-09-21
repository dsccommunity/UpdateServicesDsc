<#PSScriptInfo
.VERSION 1.0.0
.GUID ea62021c-332c-4349-8e8f-0c1f61700a3a
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
        Remove the scheduled WSUS cleanup.

    .DESCRIPTION
        This configuration unregisters the 'WSUS Cleanup' scheduled task, so that
        no cleanup runs on a schedule.

    .EXAMPLE
        UpdateServicesCleanup_RemoveCleanupTask_Config

        Compiles a configuration that removes the scheduled WSUS cleanup.
#>
Configuration UpdateServicesCleanup_RemoveCleanupTask_Config
{
    param ()

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesCleanup 'WsusCleanup'
        {
            Ensure = 'Absent'
        }
    }
}
