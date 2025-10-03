<#PSScriptInfo
.VERSION 1.0.0
.GUID 07ae5437-126c-480f-a9ab-af3241614c82
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/UpdateServicesDsc/blob/master/LICENSE
.PROJECTURI https://github.com/dsccommunity/UpdateServicesDsc
.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png
.RELEASENOTES
Updated author, copyright notice, and URLs.
#>

#Requires -Module UpdateServicesDsc

<#
    .SYNOPSIS
        Create WSUS Computer Target Groups.

    .DESCRIPTION
        This configuration will create a WSUS Computer Target Group named 'Web'
        in the 'All Computers/Servers' path using the UpdateServicesDsc module.
#>
Configuration UpdateServicesComputerTargetGroup_AddComputerTargetGroup_Config
{
    param ()

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesComputerTargetGroup 'ComputerTargetGroup_Servers'
        {
            Name        = 'Servers'
            Path        = 'All Computers'
            Ensure      = 'Present'
        }

        UpdateServicesComputerTargetGroup 'ComputerTargetGroup_Web'
        {
            Name        = 'Web'
            Path        = 'All Computers/Servers'
            Ensure      = 'Present'
            DependsOn   = '[UpdateServicesComputerTargetGroup]ComputerTargetGroup_Servers'
        }
    }
}
