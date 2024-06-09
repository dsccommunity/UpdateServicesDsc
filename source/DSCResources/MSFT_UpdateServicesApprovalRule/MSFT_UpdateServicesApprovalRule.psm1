# DSC resource to manage WSUS Approval Rule.

# Classifications ID reference...
#
# Applications       = 5C9376AB-8CE6-464A-B136-22113DD69801
# Connectors         = 434DE588-ED14-48F5-8EED-A15E09A991F6
# Critical Updates   = E6CF1350-C01B-414D-A61F-263D14D133B4
# Definition Updates = E0789628-CE08-4437-BE74-2495B842F43B
# Developer Kits     = E140075D-8433-45C3-AD87-E72345B36078
# Feature Packs      = B54E7D24-7ADD-428F-8B75-90A396FA584F
# Guidance           = 9511D615-35B2-47BB-927F-F73D8E9260BB
# Security Updates   = 0FA1201D-4330-4FA8-8AE9-B877473B6441
# Service Packs      = 68C5B0A3-D1A6-4553-AE49-01D3A7827828
# Tools              = B4832BD8-E735-4761-8DAF-37F882276DAB
# Update Rollups     = 28BC880E-0592-4CBF-8F95-C79B17911D5F
# Updates            = CD5FFD1E-E932-4E3A-BF74-18BF0B1BBD83


# Load Common Module
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current Approval Rules

    .PARAMETER Name
        If provided, returns details of a specific rule

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    try
    {
        $WsusServer = Get-WsusServer
        $Ensure = 'Absent'
        $Classifications = $null
        $Products = $null
        $ComputerGroups = $null
        $Enabled = $null

        if ($null -ne $WsusServer)
        {
            Write-Verbose -Message ('Identified WSUS server information: {0}' -f $WsusServer.Name)

            $ApprovalRule = $WsusServer.GetInstallApprovalRules() | Where-Object -FilterScript { $_.Name -eq $Name }

            if ($null -ne $ApprovalRule)
            {
                $Ensure = 'Present'

                if ( -Not ($Classifications = @($ApprovalRule.GetUpdateClassifications().ID.Guid)))
                {
                    $Classifications = @('All Classifications')
                }

                if ( -Not ($Products = @($ApprovalRule.GetCategories().Title)))
                {
                    $Products = @('All Products')
                }

                if ( -Not ($ComputerGroups = @($ApprovalRule.GetComputerTargetGroups().Name)))
                {
                    $ComputerGroups = @('All Computers')
                }

                $Enabled = $ApprovalRule.Enabled
            }
        }
        else
        {
            Write-Verbose -Message 'Did not identify an instance of WSUS'
        }
    }
    catch
    {
        New-InvalidOperationException -Message $script:localizedData.WSUSConfigurationFailed -ErrorRecord $_
    }

    $returnValue = @{
        Ensure          = $Ensure
        Name            = $Name
        Classifications = $Classifications
        Products        = $Products
        ComputerGroups  = $ComputerGroups
        Enabled         = $Enabled
    }

    $returnValue
}

<#
    .SYNOPSIS
        Sets approval rules

    .PARAMETER Ensure
        Determines if the rule should be created or removed.
        Accepts 'Present'(default) or 'Absent'.

    .PARAMETER Name
        Name of the rule to create

    .PARAMETER Classifications
        Classification for the rule or All Classifications

    .PARAMETER Products
        The name of the product for the rule or All Products

    .PARAMETER ComputerGroups
        The name of the computer group to apply the rule to or All Computers

    .PARAMETER Enabled
        Boolean to set rule enabled or disabled

    .PARAMETER Synchronize
        Boolean, when enabled the rule will synchronize with Windows Update
        This applies because the rule will approve updates as they are sync'd

    .PARAMETER RunRuleNow
        Boolean that has the same effect as clicking 'Run Rule Now' when Set occurs
        The impact is updates already sync'd will also be approved
        Otherwise, the rule is not applied to existing content

#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $Classifications = @('All Classifications'),

        [Parameter()]
        [System.String[]]
        $Products = @('All Products'),

        [Parameter()]
        [System.String[]]
        $ComputerGroups = @('All Computers'),

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $Synchronize,

        [Parameter()]
        [System.Boolean]
        $RunRuleNow
    )

    try
    {
        if ($WsusServer = Get-WsusServer)
        {
            switch ($Ensure)
            {
                'Present'
                {
                    if ($ApprovalRule = $WsusServer.GetInstallApprovalRules() | Where-Object -FilterScript { $_.Name -eq $Name })
                    {
                        Write-Verbose -Message $script:localizedData.UseExistingApprovalRule
                    }
                    else
                    {
                        Write-Verbose -Message $script:localizedData.CreateApprovalRule
                        $ApprovalRule = $WsusServer.CreateInstallApprovalRule($Name)
                    }

                    if ($ApprovalRule)
                    {
                        $ApprovalRule.Enabled = $Enabled
                        $ApprovalRule.Save()

                        $ClassificationCollection = New-Object `
                            -TypeName Microsoft.UpdateServices.Administration.UpdateClassificationCollection

                        foreach ($Classification in $Classifications)
                        {
                            if ($WsusClassification = Get-WsusClassification | Where-Object -FilterScript { $_.Classification.ID.Guid -eq $Classification })
                            {
                                $ClassificationCollection.Add($WsusServer.GetUpdateClassification(`
                                            $WsusClassification.Classification.Id))
                            }
                            else
                            {
                                Write-Verbose -Message ($script:localizedData.ClassificationNotFound -f $Classification)
                            }
                        }

                        $ApprovalRule.SetUpdateClassifications($ClassificationCollection)
                        $ApprovalRule.Save()

                        $ProductCollection = New-Object -TypeName Microsoft.UpdateServices.Administration.UpdateCategoryCollection
                        foreach ($Product in $Products)
                        {
                            if ($WsusProduct = Get-WsusProduct | Where-Object -FilterScript { $_.Product.Title -eq $Product })
                            {
                                $ProductCollection.Add($WsusServer.GetUpdateCategory($WsusProduct.Product.Id))
                            }
                        }

                        $ApprovalRule.SetCategories($ProductCollection)
                        $ApprovalRule.Save()

                        $ComputerGroupCollection = New-Object -TypeName Microsoft.UpdateServices.Administration.ComputerTargetGroupCollection
                        foreach ($ComputerGroup in $ComputerGroups)
                        {
                            if ($WsusComputerGroup = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq $ComputerGroup })
                            {
                                $ComputerGroupCollection.Add($WsusComputerGroup)
                            }
                        }

                        $ApprovalRule.SetComputerTargetGroups($ComputerGroupCollection)
                        $ApprovalRule.Save()
                        if ($RunRuleNow)
                        {
                            Write-Verbose -Message ($script:localizedData.RunApprovalRule -f $Name)

                            try
                            {
                                $ApprovalRule.ApplyRule()
                            }
                            catch
                            {
                                New-InvalidOperationException -Message (
                                    $script:localizedData.RuleFailedToApply -f $Name
                                ) -ErrorRecord $_
                            }
                        }
                    }
                    else
                    {
                        New-InvalidOperationException -Message (
                            $script:localizedData.RuleFailedToCreate -f $Name
                        ) -ErrorRecord $_
                    }
                }
                'Absent'
                {
                    if ($ApprovalRule = $WsusServer.GetInstallApprovalRules() | Where-Object -FilterScript { $_.Name -eq $Name })
                    {
                        $WsusServer.DeleteInstallApprovalRule($ApprovalRule.Id)
                    }
                    else
                    {
                        Write-Verbose -Message ($script:localizedData.RuleDoNotExist -f $ApprovalRule.Name)
                    }
                }
            }
        }
        else
        {
            Write-Verbose -Message $script:localizedData.GetWsusServerFailed
        }
    }
    catch
    {
        $errorMessage = $script:localizedData.RuleFailedToCreate -f $Name
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    if ( -Not (Test-TargetResource @PSBoundParameters))
    {
        $errorMessage = $script:localizedData.TestFailedAfterSet
        New-InvalidResultException -Message $errorMessage -ErrorRecord $_
    }
    else
    {
        if ($Synchronize)
        {
            Write-Verbose -Message $script:localizedData.SyncWsus

            try
            {
                $WsusServer.GetSubscription().StartSynchronization()
            }
            catch
            {
                $errorMessage = $script:localizedData.FailedSyncStart
                New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
            }
        }
    }
}

<#
    .SYNOPSIS
        Tests approval rules

    .PARAMETER Ensure
        Determines if the rule should be created or removed.
        Accepts 'Present'(default) or 'Absent'.

    .PARAMETER Name
        Name of the rule to create

    .PARAMETER Classifications
        Classification for the rule or All Classifications

    .PARAMETER Products
        THe name of the product for the rule or All Products

    .PARAMETER ComputerGroups
        The name of the computer group to apply the rule to or All Computers

    .PARAMETER Enabled
        Boolean to set rule enabled or disabled

    .PARAMETER Synchronize
        Boolean, when enabled the rule will synchronize with Windows Update
        This applies because the rule will approve updates as they are sync'd

    .PARAMETER RunRuleNow
        Boolean that has the same effect as clicking 'Run Rule Now' when Set occurs
        The impact is updates already sync'd will also be approved
        Otherwise, the rule is not applied to existing content

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String[]]
        $Classifications = @('All Classifications'),

        [Parameter()]
        [System.String[]]
        $Products = @('All Products'),

        [Parameter()]
        [System.String[]]
        $ComputerGroups = @('All Computers'),

        [Parameter()]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $Synchronize,

        [Parameter()]
        [System.Boolean]
        $RunRuleNow
    )

    $result = $true

    $ApprovalRule = Get-TargetResource -Name $Name

    if ($ApprovalRule.Ensure -ne $Ensure)
    {
        Write-Verbose -Message $script:localizedData.EnsureTestFailed
        $result = $false
    }

    if ($result -and ($ApprovalRule.Ensure -eq 'Present'))
    {
        if ($null -ne (Compare-Object -ReferenceObject ($ApprovalRule.Classifications | Sort-Object -Unique) -DifferenceObject ($Classifications | Sort-Object -Unique) -SyncWindow 0))
        {
            Write-Verbose -Message $script:localizedData.ClassificationTestFailed
            $result = $false
        }

        if ($null -ne (Compare-Object -ReferenceObject ($ApprovalRule.Products | Sort-Object -Unique) -DifferenceObject ($Products | Sort-Object -Unique) -SyncWindow 0))
        {
            Write-Verbose -Message $script:localizedData.ProductsTestFailed
            $result = $false
        }

        if ($null -ne (Compare-Object -ReferenceObject ($ApprovalRule.ComputerGroups | Sort-Object -Unique) -DifferenceObject ($ComputerGroups | Sort-Object -Unique) -SyncWindow 0))
        {
            Write-Verbose -Message $script:localizedData.ComputerGrpTestFailed
            $result = $false
        }

        if ($ApprovalRule.Enabled -ne $Enabled)
        {
            Write-Verbose -Message $script:localizedData.EnabledTestFailed
            $result = $false
        }
    }

    $result
}

Export-ModuleMember -Function *-TargetResource
