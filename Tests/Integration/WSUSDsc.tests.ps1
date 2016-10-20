$script:DSCModuleName      = 'WSUSDsc'
$script:DSCResourceName    = 'MSFT_WSUSServer'

#region HEADER
# Integration Test Template Version: 1.0.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

#region Integration Tests
$ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCModuleName).config.ps1"
. $ConfigFile -Verbose -ErrorAction Stop

Describe "$($script:DSCResourceName)_Integration" {
    #region DEFAULT TESTS
    It 'Should compile without throwing' {
        {
            & "$($script:DSCModuleName)_Config" -OutputPath $TestEnvironment.WorkingFolder
            Start-DscConfiguration -Path $TestEnvironment.WorkingFolder -ComputerName localhost -Wait -Verbose -Force
        } | Should not throw
    }

    It 'should be able to call Get-DscConfiguration without throwing' {
        { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
    }
    #endregion

    It 'Should have set the resource and all the parameters should match' {
        $current = Get-DscConfiguration | Where-Object {
            $_.ConfigurationName -eq "$($script:DSCModuleName)_Config"
        }
    }
}
#endregion
