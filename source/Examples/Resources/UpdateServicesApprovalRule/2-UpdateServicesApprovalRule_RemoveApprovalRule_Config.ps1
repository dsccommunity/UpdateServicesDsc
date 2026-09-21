<#PSScriptInfo
.VERSION 1.0.0
.GUID 091cf051-ced5-41ee-ad2f-d4af7335e29c
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
        Remove a WSUS approval rule.

    .DESCRIPTION
        This configuration removes the WSUS approval rule named
        'Critical and Security Updates'.

        Only the rule name is needed to remove a rule. Removing a rule does not
        revoke approvals that the rule has already applied.

    .EXAMPLE
        UpdateServicesApprovalRule_RemoveApprovalRule_Config

        Compiles a configuration that removes the approval rule.
#>
Configuration UpdateServicesApprovalRule_RemoveApprovalRule_Config
{
    param ()

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesApprovalRule 'SecurityUpdates'
        {
            Ensure = 'Absent'
            Name   = 'Critical and Security Updates'
        }
    }
}
