$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
Import-Module -Name $script:resourceHelperModulePath -ErrorAction Stop
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Tests whether the WSUS Services role has completed installation and is
        ready to be used.

    .DESCRIPTION
        Checks the registry to determine whether the WSUS Services role has
        finished installing on the server. This is distinct from WSUS simply
        being reachable - the WSUS Services role can be present but still
        mid-installation, before the post-install configuration wizard has
        completed.

        This function never throws. A missing registry key or property, or
        any other read failure, is treated as "not yet configured" so that
        Get-TargetResource and Test-TargetResource can complete normally on a
        server where WSUS has not finished installing.

        Callers are still responsible for checking whether a WSUS server was
        retrieved at all, for example: ($null -ne $WsusServer) -and
        (Test-WsusConfigured)
#>
function Test-WsusConfigured
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    try
    {
        $wsusConfigured = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup\Installed Role Services' `
                -Name 'UpdateServices-Services' -ErrorAction Stop).'UpdateServices-Services' -eq '2'
    }
    catch
    {
        $wsusConfigured = $false
    }

    if ($wsusConfigured)
    {
        Write-Verbose -Message $script:localizedData.WsusConfigured
    }
    else
    {
        Write-Verbose -Message $script:localizedData.WsusNotConfigured
    }

    return $wsusConfigured
}

Export-ModuleMember -Function Test-WsusConfigured
