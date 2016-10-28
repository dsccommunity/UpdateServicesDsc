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

$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\UpdateServicesHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    try
    {
        $WsusServer = Get-WsusServer
        $Ensure = "Absent"
        $Classifications = $null
        $Products = $null
        $ComputerGroups = $null
        $Enabled = $null

        if ($WsusServer -ne $null) {
            
            $ApprovalRule = $WsusServer.GetInstallApprovalRules() | Where-Object {$_.Name -eq $Name}
            
            if($ApprovalRule -ne $null)
            {
                $Ensure = "Present"
                
                if(!($Classifications = @($ApprovalRule.GetUpdateClassifications().ID.Guid)))
                {
                    $Classifications = @("All Classifications")
                }

                if(!($Products = @($ApprovalRule.GetCategories().Title)))
                {
                    $Products = @("All Products")
                }

                if(!($ComputerGroups = @($ApprovalRule.GetComputerTargetGroups().Name)))
                {
                    $ComputerGroups = @("All Computers")
                }

                $Enabled = $ApprovalRule.Enabled
            }
        }
    }
    catch
    {
        throw New-TerminatingError -ErrorType WSUSConfigurationFailed
    }

    $returnValue = @{
        Ensure = $Ensure
        Name = $Name
        Classifications = $Classifications
        Products = $Products
        ComputerGroups = $ComputerGroups
        Enabled = $Enabled
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String[]]
        $Classifications = @("All Classifications"),

        [System.String[]]
        $Products = @("All Products"),

        [System.String[]]
        $ComputerGroups = @("All Computers"),

        [System.Boolean]
        $Enabled,

        [System.Boolean]
        $Synchronize,

        [System.Boolean]
        $RunRuleNow
    )

    try
    {
        if($WsusServer = Get-WsusServer)
        {
            switch($Ensure)
            {
                "Present"
                {
                    if($ApprovalRule = $WsusServer.GetInstallApprovalRules() | Where-Object {$_.Name -eq $Name})
                    {
                        Write-Verbose "Using existing approval rule"
                    }
                    else
                    {
                        Write-Verbose "Creating new approval rule"
                        $ApprovalRule = $WsusServer.CreateInstallApprovalRule($Name)
                    }
                    if($ApprovalRule)
                    {
                        $ApprovalRule.Enabled = $Enabled
                        $ApprovalRule.Save()

                        $ClassificationCollection = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
                        foreach($Classification in $Classifications)
                        {
                            if($WsusClassification = Get-WsusClassification | Where-Object {$_.Classification.ID.Guid -eq $Classification})
                            {
                                $ClassificationCollection.Add($WsusServer.GetUpdateClassification($WsusClassification.Classification.Id))
                            }
                            else
                            {
                                Write-Verbose "Classification $Classification not found"
                            }
                        }
                        $ApprovalRule.SetUpdateClassifications($ClassificationCollection)
                        $ApprovalRule.Save()

                        $ProductCollection = New-Object Microsoft.UpdateServices.Administration.UpdateCategoryCollection
                        foreach($Product in $Products)
                        {
                            if($WsusProduct = Get-WsusProduct | Where-Object {$_.Product.Title -eq $Product})
                            {
                                $ProductCollection.Add($WsusServer.GetUpdateCategory($WsusProduct.Product.Id))
                            }
                        }
                        $ApprovalRule.SetCategories($ProductCollection)
                        $ApprovalRule.Save()

                        $ComputerGroupCollection = New-Object Microsoft.UpdateServices.Administration.ComputerTargetGroupCollection
                        foreach($ComputerGroup in $ComputerGroups)
                        {
                            if($WsusComputerGroup = $WsusServer.GetComputerTargetGroups() | Where-Object {$_.Name -eq $ComputerGroup})
                            {
                                $ComputerGroupCollection.Add($WsusComputerGroup)
                            }
                        }
                        $ApprovalRule.SetComputerTargetGroups($ComputerGroupCollection)
                        $ApprovalRule.Save()
                        if($RunRuleNow)
                        {
                            Write-Verbose "Running Approval Rule"
                                    
                            try
                            {
                                $ApprovalRule.ApplyRule()
                            }
                            catch
                            {
                                throw
                                Write-Verbose "Failed to run Approval Rule"
                            }
                        }
                    }
                    else
                    {
                        throw New-TerminatingError -ErrorType ApprovalRuleFailed -FormatArgs @($Name)
                    }
                }
                "Absent"
                {
                    $WsusServer.DeleteInstallApprovalRule($Name)
                }
            }
        }
        else
        {
            Write-Verbose "Get-WsusServer failed"
        }
    }
    catch
    {
        throw Write-Verbose "Failed during creation of approval rule $Name"
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
    else
    {
        if($Synchronize)
        {
            Write-Verbose "Synchronizing WSUS"
                    
            try
            {
                $WsusServer.GetSubscription().StartSynchronization()
            }
            catch
            {
                throw
                Write-Verbose "Failed to start WSUS synchronization"
            }
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String[]]
        $Classifications = @("All Classifications"),

        [System.String[]]
        $Products = @("All Products"),

        [System.String[]]
        $ComputerGroups = @("All Computers"),

        [System.Boolean]
        $Enabled,

        [System.Boolean]
        $Synchronize,

        [System.Boolean]
        $RunRuleNow
    )

    $result = $true
    
    $ApprovalRule = Get-TargetResource -Name $Name    

    if($ApprovalRule.Ensure -ne $Ensure)
    {
        Write-Verbose "Ensure test failed"
        $result = $false
    }
    if($result -and ($ApprovalRule.Ensure -eq "Present"))
    {
        if((Compare-Object -ReferenceObject ($ApprovalRule.Classifications | Sort-Object -Unique) -DifferenceObject ($Classifications | Sort-Object -Unique) -SyncWindow 0) -ne $null)
        {
            Write-Verbose "Classifications test failed"
            $result = $false
        }
        if((Compare-Object -ReferenceObject ($ApprovalRule.Products | Sort-Object -Unique) -DifferenceObject ($Products | Sort-Object -Unique) -SyncWindow 0) -ne $null)
        {
            Write-Verbose "Products test failed"
            $result = $false
        }
        if((Compare-Object -ReferenceObject ($ApprovalRule.ComputerGroups | Sort-Object -Unique) -DifferenceObject ($ComputerGroups | Sort-Object -Unique) -SyncWindow 0) -ne $null)
        {
            Write-Verbose "ComputerGroups test failed"
            $result = $false
        }
        if($ApprovalRule.Enabled -ne $Enabled)
        {
            Write-Verbose "Enabled test failed"
            $result = $false
        }
    }
    
    $result
}


Export-ModuleMember -Function *-TargetResource
