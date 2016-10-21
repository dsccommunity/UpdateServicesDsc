# DSC resource to manage WSUS Cleanup task.

$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\WSUSHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
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
            $Ensure = "Present"
            $Arguments = $Task.Actions.Arguments
            if($Arguments)
                {
                $Arguments = $Arguments.Split("`"")
                if($Arguments.Count -ge 1)
                {
                    $Arguments = $Arguments[1].Split(";")
                    foreach($Var in @("DeclineSupersededUpdates","DeclineExpiredUpdates","CleanupObsoleteUpdates","CompressUpdates","CleanupObsoleteComputers","CleanupUnneededContentFiles","CleanupLocalPublishedContentFiles"))
                    {
                        Set-Variable -Name $Var -Value (Invoke-Expression((($Arguments | Where-Object {$_ -like "`$$Var = *"}) -split " = ")[1]))
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
        Ensure = $Ensure
        DeclineSupersededUpdates = $DeclineSupersededUpdates
        DeclineExpiredUpdates = $DeclineExpiredUpdates
        CleanupObsoleteUpdates = $CleanupObsoleteUpdates
        CompressUpdates = $CompressUpdates
        CleanupObsoleteComputers = $CleanupObsoleteComputers
        CleanupUnneededContentFiles = $CleanupUnneededContentFiles
        CleanupLocalPublishedContentFiles = $CleanupLocalPublishedContentFiles
        TimeOfDay = $TimeOfDay
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.Boolean]
        $DeclineSupersededUpdates,

        [System.Boolean]
        $DeclineExpiredUpdates,

        [System.Boolean]
        $CleanupObsoleteUpdates,

        [System.Boolean]
        $CompressUpdates,

        [System.Boolean]
        $CleanupObsoleteComputers,

        [System.Boolean]
        $CleanupUnneededContentFiles,

        [System.Boolean]
        $CleanupLocalPublishedContentFiles,

        [System.String]
        $TimeOfDay = "04:00:00"
    )

    if(Get-ScheduledTask -TaskName "WSUS Cleanup" -ErrorAction SilentlyContinue)
    {
        Unregister-ScheduledTask -TaskName "WSUS Cleanup" -Confirm:$false
    }

    if($Ensure -eq "Present")
    {
        $Command = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"

        $Argument = "-Command `""
        $Argument += "'Starting WSUS Cleanup...' | Out-File (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WsusCleanup.txt');"
        foreach($Var in @("DeclineSupersededUpdates","DeclineExpiredUpdates","CleanupObsoleteUpdates","CompressUpdates","CleanupObsoleteComputers","CleanupUnneededContentFiles","CleanupLocalPublishedContentFiles"))
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
        $Argument += "`$WsusServer = Get-WsusServer;"
        $Argument += "if(`$WsusServer)"
        $Argument += "{"
        $Argument += "'WSUS Server found...' | Out-File (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WsusCleanup.txt') -Append;"
        $Argument += "`$WsusCleanupManager = `$WsusServer.GetCleanupManager();"
        $Argument += "if(`$WsusCleanupManager)"
        $Argument += "{"
        $Argument += "'WSUS Cleanup Manager found...' | Out-File (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WsusCleanup.txt') -Append;"
        $Argument += "`$WsusCleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope(`$DeclineSupersededUpdates,`$DeclineExpiredUpdates,`$CleanupObsoleteUpdates,`$CompressUpdates,`$CleanupObsoleteComputers,`$CleanupUnneededContentFiles,`$CleanupLocalPublishedContentFiles);"
        $Argument += "`$WsusCleanupResults = `$WsusCleanupManager.PerformCleanup(`$WsusCleanupScope);"
        $Argument += "if(`$WsusCleanupResults)"
        $Argument += "{"
        $Argument += "`$WsusCleanupResults | Out-File (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath 'WsusCleanup.txt') -Append"
        $Argument += "}"
        $Argument += "}"
        $Argument += "}"
        $Argument += "`""

        $Action = New-ScheduledTaskAction -Execute $Command -Argument $Argument
        $Trigger = New-ScheduledTaskTrigger -Daily -At $TimeOfDay
        Register-ScheduledTask -TaskName "WSUS Cleanup" -Action $Action -Trigger $Trigger -RunLevel Highest -User "SYSTEM"
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.Boolean]
        $DeclineSupersededUpdates,

        [System.Boolean]
        $DeclineExpiredUpdates,

        [System.Boolean]
        $CleanupObsoleteUpdates,

        [System.Boolean]
        $CompressUpdates,

        [System.Boolean]
        $CleanupObsoleteComputers,

        [System.Boolean]
        $CleanupUnneededContentFiles,

        [System.Boolean]
        $CleanupLocalPublishedContentFiles,

        [System.String]
        $TimeOfDay = "04:00:00"
    )

    $result = $true

    $CleanupTask = Get-TargetResource -Ensure $Ensure

    if($CleanupTask.Ensure -ne $Ensure)
    {
        Write-Verbose "Ensure test failed"
        $result = $false
    }
    if($result -and ($CleanupTask.Ensure -eq "Present"))
    {
        if($CleanupTask.DeclineSupersededUpdates -ne $DeclineSupersededUpdates)
        {
            Write-Verbose "DeclineSupersededUpdates test failed"
            $result = $false
        }
        if($CleanupTask.DeclineExpiredUpdates -ne $DeclineExpiredUpdates)
        {
            Write-Verbose "DeclineExpiredUpdates test failed"
            $result = $false
        }
        if($CleanupTask.CleanupObsoleteUpdates -ne $CleanupObsoleteUpdates)
        {
            Write-Verbose "CleanupObsoleteUpdates test failed"
            $result = $false
        }
        if($CleanupTask.CompressUpdates -ne $CompressUpdates)
        {
            Write-Verbose "CompressUpdates test failed"
            $result = $false
        }
        if($CleanupTask.CleanupObsoleteComputers -ne $CleanupObsoleteComputers)
        {
            Write-Verbose "CleanupObsoleteComputers test failed"
            $result = $false
        }
        if($CleanupTask.CleanupUnneededContentFiles -ne $CleanupUnneededContentFiles)
        {
            Write-Verbose "CleanupUnneededContentFiles test failed"
            $result = $false
        }
        if($CleanupTask.CleanupLocalPublishedContentFiles -ne $CleanupLocalPublishedContentFiles)
        {
            Write-Verbose "CleanupLocalPublishedContentFiles test failed"
            $result = $false
        }
    }
    
    $result
}


Export-ModuleMember -Function *-TargetResource
