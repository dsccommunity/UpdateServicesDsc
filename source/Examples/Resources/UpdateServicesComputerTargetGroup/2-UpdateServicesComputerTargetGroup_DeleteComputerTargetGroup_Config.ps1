<#PSScriptInfo
.VERSION 1.0.0
.GUID 9165945f-cd15-4865-aa3a-1ac6b6f94a8b
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
        Delete a WSUS Computer Target Group.

    .DESCRIPTION
        This configuration will delete a WSUS Computer Target Group named 'Web'
        from the 'All Computers/Servers' path using the UpdateServicesDsc module.
#>
Configuration UpdateServicesComputerTargetGroup_DeleteComputerTargetGroup_Config
{
    param ()

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesComputerTargetGroup 'ComputerTargetGroup_Web'
        {
            Name        = 'Web'
            Path        = 'All Computers/Servers'
            Ensure      = 'Absent'
        }
    }
}
