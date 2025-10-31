# DSC resource to manage WSUS Computer Target Groups.

# Load Common Module
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
Import-Module -Name $script:resourceHelperModulePath
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'


<#
    .SYNOPSIS
        Retrieves the current state of the WSUS Computer Target Group.

    .DESCRIPTION
        This function retrieves the current state of a WSUS Computer Target Group
        by querying the WSUS server and validating the group's path.

    .PARAMETER Name
        The Name of the WSUS Computer Target Group.

    .PARAMETER Path
        The Path to the WSUS Computer Target Group in the format 'Parent/Child'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    try
    {
        $WsusServer = Get-WsusServer
    }
    catch
    {
        New-InvalidOperationException -Message $script:localizedData.WSUSConfigurationFailed -ErrorRecord $_
    }

    $Ensure = 'Absent'
    $Id = $null

    if ($null -ne $WsusServer)
    {
        Write-Verbose -Message ($script:localizedData.GetWsusServerSucceeded -f $WsusServer.Name)
        $ComputerTargetGroup = $WsusServer.GetComputerTargetGroups().Where({ $_.Name -eq $Name }) | Select-Object -First 1

        if ($null -ne $ComputerTargetGroup)
        {
            $ComputerTargetGroupPath = Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup
            if ($Path -eq $ComputerTargetGroupPath)
            {
                $Ensure = 'Present'
                $Id = $ComputerTargetGroup.Id.Guid
                Write-Verbose -Message ($script:localizedData.FoundComputerTargetGroup -f $Name, $Path, $Id)
            }
            else
            {
                # ComputerTargetGroup Names must be unique within the overall hierarchy
                New-InvalidOperationException -Message ($script:localizedData.DuplicateComputerTargetGroup -f $ComputerTargetGroup.Name, $ComputerTargetGroupPath)
            }
        }
    }
    else
    {
        Write-Verbose -Message $script:localizedData.GetWsusServerFailed
    }

    if ($null -eq $Id)
    {
        Write-Verbose -Message ($script:localizedData.NotFoundComputerTargetGroup -f $Name, $Path)
    }

    $returnValue = @{
        Ensure = $Ensure
        Name   = $Name
        Path   = $Path
        Id     = $Id
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the state of the WSUS Computer Target Group.

    .DESCRIPTION
        This function creates or removes a WSUS Computer Target Group based on
        the Ensure parameter. It validates the parent path and performs the
        appropriate action on the WSUS server.

    .PARAMETER Ensure
        Determines if the Computer Target Group should be created or removed.
        Accepts 'Present' (default) or 'Absent'.

    .PARAMETER Name
        Name of the Computer Target Group.

    .PARAMETER Path
        The Path to the Computer Target Group in the format 'Parent/Child'.
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    try
    {
        $WsusServer = Get-WsusServer
    }
    catch
    {
        New-InvalidOperationException -Message $script:localizedData.WSUSConfigurationFailed -ErrorRecord $_
    }

    # break down path to identify the parent computer target group based on name and its own unique path
    $ParentComputerTargetGroupName = (($Path -split '/')[-1])
    $ParentComputerTargetGroupPath = ($Path -replace "[/]$ParentComputerTargetGroupName", '')

    if ($null -ne $WsusServer)
    {
        $ParentComputerTargetGroups = $WsusServer.GetComputerTargetGroups().Where({
                $_.Name -eq $ParentComputerTargetGroupName
            }) | Select-Object -First 1

        if ($null -ne $ParentComputerTargetGroups)
        {
            foreach ($ParentComputerTargetGroup in $ParentComputerTargetGroups)
            {
                $ComputerTargetGroupPath = Get-ComputerTargetGroupPath -ComputerTargetGroup $ParentComputerTargetGroup
                if ($ParentComputerTargetGroupPath -eq $ComputerTargetGroupPath)
                {
                    # parent Computer Target Group Exists
                    Write-Verbose -Message ($script:localizedData.FoundParentComputerTargetGroup -f $ParentComputerTargetGroupName, `
                            $ParentComputerTargetGroupPath, $ParentComputerTargetGroup.Id.Guid)

                    # create the new Computer Target Group if Ensure -eq 'Present'
                    if ($Ensure -eq 'Present')
                    {
                        try
                        {
                            $null = $WsusServer.CreateComputerTargetGroup($Name, $ParentComputerTargetGroup)
                            Write-Verbose -Message ($script:localizedData.CreateComputerTargetGroupSuccess -f $Name, $Path)
                            return
                        }
                        catch
                        {
                            New-InvalidOperationException -Message (
                                $script:localizedData.CreateComputerTargetGroupFailed -f $Name, $Path
                            ) -ErrorRecord $_
                        }
                    }
                    else
                    {
                        # $Ensure -eq 'Absent' - must call the Delete() method on the group itself for removal
                        $ChildComputerTargetGroup = $ParentComputerTargetGroup.GetChildTargetGroups().Where({
                                $_.Name -eq $Name
                            }) | Select-Object -First 1

                        if ($null -eq $ChildComputerTargetGroup)
                        {
                            # Already absent
                            Write-Verbose -Message ($script:localizedData.NotFoundComputerTargetGroup -f $Name, $Path)
                            return
                        }

                        try
                        {
                            $childId = $ChildComputerTargetGroup.Id.Guid
                            $null = $ChildComputerTargetGroup.Delete()
                            Write-Verbose -Message ($script:localizedData.DeleteComputerTargetGroupSuccess -f $Name, $childId, $Path)
                            return
                        }
                        catch
                        {
                            $childId = if ($ChildComputerTargetGroup)
                            {
                                $ChildComputerTargetGroup.Id.Guid 
                            }
                            else
                            {
                                'N/A' 
                            }
                            New-InvalidOperationException -Message (
                                $script:localizedData.DeleteComputerTargetGroupFailed -f $Name, $childId, $Path
                            ) -ErrorRecord $_
                        }
                    }
                }
            }
        }

        New-InvalidOperationException -Message ($script:localizedData.NotFoundParentComputerTargetGroup -f $ParentComputerTargetGroupName, `
                $ParentComputerTargetGroupPath, $Name)
    }
    else
    {
        Write-Verbose -Message $script:localizedData.GetWsusServerFailed
    }
}

<#
    .SYNOPSIS
        Tests the current state of the WSUS Computer Target Group.

    .DESCRIPTION
        This function determines whether the WSUS Computer Target Group is in
        the desired state by comparing the current state to the requested Ensure value.

    .PARAMETER Ensure
        Determines if the Computer Target Group should be created or removed.
        Accepts 'Present' (default) or 'Absent'.

    .PARAMETER Name
        Name of the Computer Target Group

    .PARAMETER Path
        The Path to the Computer Target Group in the format 'Parent/Child'.
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $result = Get-TargetResource -Name $Name -Path $Path

    if ($Ensure -eq $result.Ensure)
    {
        Write-Verbose -Message ($script:localizedData.ResourceInDesiredState -f $Name, $Path, $result.Ensure)
        return $true
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.ResourceNotInDesiredState -f $Name, $Path, $result.Ensure)
        return $false
    }
}


<#
    .SYNOPSIS
        Gets the Computer Target Group Path within WSUS by recursing up through each Parent Computer Target Group

    .DESCRIPTION
        This function recursively traverses the parent hierarchy of a WSUS Computer
        Target Group to construct its full path in the format 'Parent/Child/GrandChild'.

    .PARAMETER ComputerTargetGroup
        The Computer Target Group object for which to retrieve the path.

    .OUTPUTS
        System.String

        Returns the full hierarchical path of the Computer Target Group.
#>
function Get-ComputerTargetGroupPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ComputerTargetGroup
    )

    if ($ComputerTargetGroup.Name -eq 'All Computers')
    {
        return 'All Computers'
    }

    $computerTargetGroupPath = ''
    $computerTargetGroupParents = @()
    $moreParentContainers = $true
    $x = 0

    do
    {
        try
        {
            $ComputerTargetGroup = $ComputerTargetGroup.GetParentTargetGroup()
            $computerTargetGroupParents += $ComputerTargetGroup.Name
        }
        catch
        {
            # 'All Computers' container throws an exception when GetParentTargetGroup() method called
            $moreParentContainers = $false
        }

        $x++
    } while ($moreParentContainers -and ($x -lt 20))

    for ($i = ($computerTargetGroupParents.Count - 1); $i -ge 0; $i--)
    {
        if (-not [string]::IsNullOrEmpty($computerTargetGroupPath))
        {
            $computerTargetGroupPath += ('/' + $computerTargetGroupParents[$i])
        }
        else
        {
            $computerTargetGroupPath += $computerTargetGroupParents[$i]
        }
    }

    return $computerTargetGroupPath
}

Export-ModuleMember -Function *-TargetResource
