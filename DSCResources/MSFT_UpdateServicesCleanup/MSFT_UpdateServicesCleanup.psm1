# DSC resource to manage WSUS Cleanup task.

$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\UpdateServicesHelper.psm1 -Verbose:$false -ErrorAction Stop

<#
    .SYNOPSIS
    Returns the current CleanUp Task
    .PARAMETER Ensure
    Determinse if the task should be added or removed
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    if($Task = Get-ScheduledTask -TaskName "WSUS Cleanup" -ErrorAction SilentlyContinue)
    {
        if(
            ($Task.State -ne "Disabled") -and
            ($Task.Actions.Execute -eq "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe")
        )
        {
            Write-Verbose "Identified enabled scheduled task for cleanup rule"

            $Ensure = "Present"
            $Arguments = $Task.Actions.Arguments
            if($Arguments)
                {
                $Arguments = $Arguments.Split("`"")
                if($Arguments.Count -ge 1)
                {
                    $Arguments = $Arguments[1].Split(";")
                    foreach($Var in @(
                        "DeclineSupersededUpdates",
                        "DeclineExpiredUpdates",
                        "CleanupObsoleteUpdates",
                        "CompressUpdates",
                        "CleanupObsoleteComputers",
                        "CleanupUnneededContentFiles",
                        "CleanupLocalPublishedContentFiles"
                        ))
                    {
                        Set-Variable -Name $Var -Value (Invoke-Expression((($Arguments `
                            | Where-Object -FilterScript {$_ -like "`$$Var = *"}) -split " = ")[1]))
                    }
                }
            }
            $TimeOfDay = $Task.Triggers.StartBoundary.Split('T')[1]
        }
        else
        {
            $Ensure = "Absent"
        }
    }
    else
    {
        $Ensure = "Absent"
    }

    $returnValue = @{
        Ensure                            = $Ensure
        DeclineSupersededUpdates          = $DeclineSupersededUpdates
        DeclineExpiredUpdates             = $DeclineExpiredUpdates
        CleanupObsoleteUpdates            = $CleanupObsoleteUpdates
        CompressUpdates                   = $CompressUpdates
        CleanupObsoleteComputers          = $CleanupObsoleteComputers
        CleanupUnneededContentFiles       = $CleanupUnneededContentFiles
        CleanupLocalPublishedContentFiles = $CleanupLocalPublishedContentFiles
        TimeOfDay                         = $TimeOfDay
    }

    $returnValue
}

<#
    .SYNOPSIS
    Creates and configures cleanup tasks
    .PARAMETER Ensure
    Determines if the task should be created or removed.
    Accepts 'Present'(default) or 'Absent'.
    .PARAMETER DeclineSupersededUpdates
    Decline superseded updates
    .PARAMETER DeclineExpiredUpdates
    Decline expired updates
    .PARAMETER CleanupObsoleteUpdates
    Cleanup obsolete updates
    .PARAMETER CompressUpdates
    The name of the computer group to apply the rule to or All Computers
    .PARAMETER CleanupObsoleteComputers
    Clean up obsolete computers
    .PARAMETER CleanupUnneededContentFiles
    Clean up unneeded content files
    .PARAMETER CleanupLocalPublishedContentFiles
    Clean up local published content files
    .PARAMETER TimeOfDay
    The time of day when the task should run
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $DeclineSupersededUpdates,

        [Parameter()]
        [System.Boolean]
        $DeclineExpiredUpdates,

        [Parameter()]
        [System.Boolean]
        $CleanupObsoleteUpdates,

        [Parameter()]
        [System.Boolean]
        $CompressUpdates,

        [Parameter()]
        [System.Boolean]
        $CleanupObsoleteComputers,

        [Parameter()]
        [System.Boolean]
        $CleanupUnneededContentFiles,

        [Parameter()]
        [System.Boolean]
        $CleanupLocalPublishedContentFiles,

        [Parameter()]
        [System.String]
        $TimeOfDay = "04:00:00"
    )

    if(Get-ScheduledTask -TaskName "WSUS Cleanup" -ErrorAction SilentlyContinue)
    {
        Write-Verbose "Removing existing schedued task for WSUS cleanup"
        Unregister-ScheduledTask -TaskName "WSUS Cleanup" -Confirm:$false
    }

    if($Ensure -eq "Present")
    {
        $Command = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"

        $Argument = "-Command `""
        $Argument += "'Starting WSUS Cleanup...' | Out-File `
            (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WsusCleanup.txt');"
        foreach($Var in @(
            "DeclineSupersededUpdates",
            "DeclineExpiredUpdates",
            "CleanupObsoleteUpdates",
            "CompressUpdates",
            "CleanupObsoleteComputers",
            "CleanupUnneededContentFiles",
            "CleanupLocalPublishedContentFiles"
            ))
        {
            if((Get-Variable -Name $Var).Value)
            {
                $Argument += "`$$Var = `$true;"
            }
            else
            {
                $Argument += "`$$Var = `$false;"
            }
        }
        $Argument += @"
`$WsusServer = Get-WsusServer
if(`$WsusServer)
{
    'WSUS Server found...' | Out-File (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WsusCleanup.txt') -Append
    `$WsusCleanupManager = `$WsusServer.GetCleanupManager()
    if(`$WsusCleanupManager)
    {
        'WSUS Cleanup Manager found...' | Out-File (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WsusCleanup.txt') -Append
        `$WsusCleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope(`$DeclineSupersededUpdates,`$DeclineExpiredUpdates,`$CleanupObsoleteUpdates,`$CompressUpdates,`$CleanupObsoleteComputers,`$CleanupUnneededContentFiles,`$CleanupLocalPublishedContentFiles)
        `$WsusCleanupResults = `$WsusCleanupManager.PerformCleanup(`$WsusCleanupScope)
        if(`$WsusCleanupResults)
        {
        `$WsusCleanupResults | Out-File (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WsusCleanup.txt') -Append
        }
    }
}
"@

        Write-Verbose "Creating new scheduled task for WSUS cleanup rule"
        
        $Action = New-ScheduledTaskAction -Execute $Command -Argument $Argument
        $Trigger = New-ScheduledTaskTrigger -Daily -At $TimeOfDay
        Register-ScheduledTask -TaskName "WSUS Cleanup" -Action $Action -Trigger $Trigger -RunLevel Highest -User "SYSTEM"
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    Creates and configures cleanup tasks
    .PARAMETER Ensure
    Determines if the task should be created or removed.
    Accepts 'Present'(default) or 'Absent'.
    .PARAMETER DeclineSupersededUpdates
    Decline superseded updates
    .PARAMETER DeclineExpiredUpdates
    Decline expired updates
    .PARAMETER CleanupObsoleteUpdates
    Cleanup obsolete updates
    .PARAMETER CompressUpdates
    The name of the computer group to apply the rule to or All Computers
    .PARAMETER CleanupObsoleteComputers
    Clean up obsolete computers
    .PARAMETER CleanupUnneededContentFiles
    Clean up unneeded content files
    .PARAMETER CleanupLocalPublishedContentFiles
    Clean up local published content files
    .PARAMETER TimeOfDay
    The time of day when the task should run
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $DeclineSupersededUpdates,

        [Parameter()]
        [System.Boolean]
        $DeclineExpiredUpdates,

        [Parameter()]
        [System.Boolean]
        $CleanupObsoleteUpdates,

        [Parameter()]
        [System.Boolean]
        $CompressUpdates,

        [Parameter()]
        [System.Boolean]
        $CleanupObsoleteComputers,

        [Parameter()]
        [System.Boolean]
        $CleanupUnneededContentFiles,

        [Parameter()]
        [System.Boolean]
        $CleanupLocalPublishedContentFiles,

        [Parameter()]
        [System.String]
        $TimeOfDay = "04:00:00"
    )

    $result = $true

    $CleanupTask = Get-TargetResource -Ensure $Ensure

    if($CleanupTask.Ensure -ne $Ensure)
    {
        Write-Verbose -Message "Ensure test failed"
        $result = $false
    }
    if($result -and ($CleanupTask.Ensure -eq "Present"))
    {
        if($CleanupTask.DeclineSupersededUpdates -ne $DeclineSupersededUpdates)
        {
            Write-Verbose -Message "DeclineSupersededUpdates test failed"
            $result = $false
        }
        if($CleanupTask.DeclineExpiredUpdates -ne $DeclineExpiredUpdates)
        {
            Write-Verbose -Message "DeclineExpiredUpdates test failed"
            $result = $false
        }
        if($CleanupTask.CleanupObsoleteUpdates -ne $CleanupObsoleteUpdates)
        {
            Write-Verbose -Message "CleanupObsoleteUpdates test failed"
            $result = $false
        }
        if($CleanupTask.CompressUpdates -ne $CompressUpdates)
        {
            Write-Verbose -Message "CompressUpdates test failed"
            $result = $false
        }
        if($CleanupTask.CleanupObsoleteComputers -ne $CleanupObsoleteComputers)
        {
            Write-Verbose -Message "CleanupObsoleteComputers test failed"
            $result = $false
        }
        if($CleanupTask.CleanupUnneededContentFiles -ne $CleanupUnneededContentFiles)
        {
            Write-Verbose -Message "CleanupUnneededContentFiles test failed"
            $result = $false
        }
        if($CleanupTask.CleanupLocalPublishedContentFiles -ne $CleanupLocalPublishedContentFiles)
        {
            Write-Verbose -Message "CleanupLocalPublishedContentFiles test failed"
            $result = $false
        }
    }
    
    $result
}


Export-ModuleMember -Function *-TargetResource
