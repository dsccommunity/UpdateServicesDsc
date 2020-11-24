# DSC resource to manage WSUS Computer Target Groups.

# Load Common Module
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
Import-Module -Name $script:resourceHelperModulePath
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US' -FileName 'MSFT_UpdateServicesComputerTargetGroup.strings.psd1'


<#
    .SYNOPSIS
        Retrieves the current state of the WSUS Computer Target Group.

        The returned object provides the following properties:
            Name: The Name of the WSUS Computer Target Group.
            Path: The Path to the Parent of the Computer Target Group.
            Id: The Id / GUID of the WSUS Computer Target Group.
    .PARAMETER Name
        The Name of the WSUS Computer Target Group.

    .PARAMETER Path
        The Path to the WSUS Compter Target Group in the format 'Parent/Child'.
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
        $Ensure = 'Absent'
        $Id = $null

        if ($null -ne $WsusServer)
        {
            Write-Verbose -Message ($script:localizedData.GetWsusServerSucceeded -f $WsusServer.Name)
            $ComputerTargetGroup = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq $Name }

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
    }
    catch
    {
        New-InvalidOperationException -Message $script:localizedData.WSUSConfigurationFailed -ErrorRecord $_
    }

    if ($null -eq $Id)
    {
        Write-Verbose -Message ($script:localizedData.NotFoundComputerTargetGroup -f $Name, $Path)
    }

    $returnValue = @{
        Ensure          = $Ensure
        Name            = $Name
        Path            = $Path
        Id              = $Id
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the state of the WSUS Computer Target Group.

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

        # break down path to identify the parent computer target group based on name and its own unique path
        $ParentComputerTargetGroupName = (($Path -split "/")[-1])
        $ParentComputerTargetGroupPath = ($Path -replace "[/]$ParentComputerTargetGroupName", "")

        if ($null -ne $WsusServer)
        {
            $ParentComputerTargetGroups = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript {
                $_.Name -eq $ParentComputerTargetGroupName
            }

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
                                $WsusServer.CreateComputerTargetGroup($Name, $ParentComputerTargetGroup) | Out-Null
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
                            try
                            {
                                $ChildComputerTargetGroup = $ParentComputerTargetGroup.GetChildTargetGroups() | Where-Object -FilterScript {
                                    $_.Name -eq $Name
                                }
                                $ChildComputerTargetGroup.Delete() | Out-Null
                                Write-Verbose -Message ($script:localizedData.DeleteComputerTargetGroupSuccess -f $Name, `
                                $ChildComputerTargetGroup.Id.Guid, $Path)
                                return
                            }
                            catch
                            {
                                New-InvalidOperationException -Message (
                                    $script:localizedData.DeleteComputerTargetGroupFailed -f $Name, `
                                    $ChildComputerTargetGroup.Id.Guid, $Path
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
    catch
    {
        New-InvalidOperationException -Message $script:localizedData.WSUSConfigurationFailed -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Tests the current state of the WSUS Computer Target Group.

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

    .PARAMETER ComputerTargetGroup
        The Computer TargetGroup
#>
function Get-ComputerTargetGroupPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [object]
        $ComputerTargetGroup
    )

    if ($ComputerTargetGroup.Name -eq 'All Computers')
    {
        return "All Computers"
    }

    $computerTargetGroupPath = ""
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

    for ($i=($computerTargetGroupParents.Count - 1); $i -ge 0; $i--)
    {
        if ("" -ne $computerTargetGroupPath)
        {
            $computerTargetGroupPath += ("/" +  $computerTargetGroupParents[$i])
        }
        else
        {
            $computerTargetGroupPath += $computerTargetGroupParents[$i]
        }
    }

    return $computerTargetGroupPath
}

Export-ModuleMember -Function *-TargetResource
