<#PSScriptInfo
.VERSION 1.0.0
.GUID 3c3ca9c1-1f7c-4f87-aeff-dce13e489296
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
        Create WSUS approval rules.

    .DESCRIPTION
        This configuration creates two WSUS approval rules: one that approves
        critical and security updates for every computer, and one that approves
        definition updates for a single computer group and runs immediately
        against updates that have already been synchronized.

        Classifications are given as GUIDs. The full list is documented at the
        top of the UpdateServicesApprovalRule resource.

    .EXAMPLE
        UpdateServicesApprovalRule_ApproveSecurityUpdates_Config

        Compiles a configuration that creates the approval rules.
#>
Configuration UpdateServicesApprovalRule_ApproveSecurityUpdates_Config
{
    param ()

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesApprovalRule 'SecurityUpdates'
        {
            Ensure          = 'Present'
            Name            = 'Critical and Security Updates'
            Classifications = @(
                'E6CF1350-C01B-414D-A61F-263D14D133B4' # Critical Updates
                '0FA1201D-4330-4FA8-8AE9-B877473B6441' # Security Updates
            )
            Products        = @(
                'Windows Server 2022'
                'Windows 11'
            )
            ComputerGroups  = @('All Computers')
            Enabled         = $true
        }

        UpdateServicesApprovalRule 'DefinitionUpdates'
        {
            Ensure          = 'Present'
            Name            = 'Definition Updates'
            Classifications = @(
                'E0789628-CE08-4437-BE74-2495B842F43B' # Definition Updates
            )
            Products        = @('Microsoft Defender Antivirus')
            ComputerGroups  = @('Servers')
            Enabled         = $true

            # Apply the rule to updates that have already been synchronized.
            RunRuleNow      = $true
        }
    }
}
