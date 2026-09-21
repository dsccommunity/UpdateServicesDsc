<#PSScriptInfo
.VERSION 1.0.0
.GUID e5abff4b-89cf-4a6f-974e-f3801dcd39d0
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
        Schedule the daily WSUS cleanup.

    .DESCRIPTION
        This configuration registers a scheduled task named 'WSUS Cleanup' that
        runs daily as SYSTEM and performs the selected cleanup operations.

        TimeOfDay is the local time the task starts, and defaults to 04:00:00
        when it is not specified.

    .EXAMPLE
        UpdateServicesCleanup_ScheduleDailyCleanup_Config

        Compiles a configuration that schedules the daily WSUS cleanup.
#>
Configuration UpdateServicesCleanup_ScheduleDailyCleanup_Config
{
    param ()

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesCleanup 'WsusCleanup'
        {
            Ensure                            = 'Present'

            DeclineSupersededUpdates          = $true
            DeclineExpiredUpdates             = $true
            CleanupObsoleteUpdates            = $true
            CleanupObsoleteComputers          = $true
            CleanupUnneededContentFiles       = $true

            # Compressing updates is slow, so it is left to a manual run.
            CompressUpdates                   = $false
            CleanupLocalPublishedContentFiles = $false

            TimeOfDay                         = '02:00:00'
        }
    }
}
