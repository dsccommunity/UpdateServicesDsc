[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'UpdateServicesDsc'
    $script:dscResourceName = 'MSFT_UpdateServicesCleanup'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/ImitateUpdateServicesModule.psm1') -Force

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

    $DSCSetValues =
    @{
        DeclineSupersededUpdates = $true
        DeclineExpiredUpdates = $true
        CleanupObsoleteUpdates = $true
        CompressUpdates = $true
        CleanupObsoleteComputers = $true
        CleanupUnneededContentFiles = $true
        CleanupLocalPublishedContentFiles = $true
        TimeOfDay = "04:00:00"
    }

    $DSCTestValues =
    @{
        DeclineSupersededUpdates = $true
        DeclineExpiredUpdates = $true
        CleanupObsoleteUpdates = $true
        CompressUpdates = $true
        CleanupObsoleteComputers = $true
        CleanupUnneededContentFiles = $true
        CleanupLocalPublishedContentFiles = $true
        TimeOfDay = "04:00:00"
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    Remove-Module -Name 'ImitateUpdateServicesModule' -Force -ErrorAction SilentlyContinue
}

#region Function Get-TargetResource expecting Ensure Present
Describe "MSFT_UpdateServicesCleanup\Get-TargetResource" {
    BeforeAll {
        $Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
        $Execute = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
        $StartBoundary = '20160101T04:00:00'
    }

    Context 'server is configured.' {
        BeforeAll {
            Mock -CommandName Get-ScheduledTask -mockwith {
                @{
                    State = 'Enabled'
                    Actions =
                    @{
                        Execute = $Execute
                        Arguments = $Arguments
                    }
                    Triggers =
                    @{
                        StartBoundary = $StartBoundary
                    }
                }
            } -Verifiable
        }

        it 'calling Get should not throw' {
            {$Script:resource = Get-TargetResource -Ensure "Present" -verbose} | Should -Not -Throw

            Should -Invoke Get-ScheduledTask -Exactly 1
        }

        it 'Ensure' {
                $Script:resource.Ensure | should -Be 'Present'
        }

        $settingsList = @(
            'DeclineSupersededUpdates'
            'DeclineExpiredUpdates'
            'CleanupObsoleteUpdates'
            'CompressUpdates'
            'CleanupObsoleteComputers'
            'CleanupUnneededContentFiles'
            'CleanupLocalPublishedContentFiles'
        )

        Context 'When <_> property is valid' -Foreach $settingsList {
            it '<_> should be true' {
                $Script:resource.$_ | Should -BeTrue
            }
        }

        it 'TimeOfDay' {
            $Script:resource.TimeOfDay | Should -Be $StartBoundary.Split('T')[1]
        }
    }

    Context 'server is not configured.' {
        BeforeAll {
            Mock Get-ScheduledTask -mockwith {} -Verifiable
        }

        it 'calling Get should not throw' {
            {$Script:resource = Get-TargetResource -Ensure 'Absent' -verbose} | should -Not -Throw

            Should -Invoke Get-ScheduledTask -Exactly 1
        }

        it 'Ensure' {
            $Script:resource.Ensure | should -Be 'Absent'
        }
    }

    Context 'server is configured in an unexpected way.' {
        BeforeAll {
            Mock Get-ScheduledTask -mockwith {
                @{
                    State = 'Disabled'
                    Actions =
                    @{
                        Execute = $Execute
                        Arguments = $Arguments
                    }
                    Triggers =
                    @{
                        StartBoundary = $StartBoundary
                    }
                }
            }
        }

        it 'calling Get should not throw' {
            {$Script:resource = Get-TargetResource -Ensure 'Present' -verbose} | should -Not -Throw

            Should -Invoke Get-ScheduledTask -Exactly 1
        }

        it 'Ensure' {
            $Script:resource.Ensure | should -Be 'Absent'
        }
    }
}
#endregion


#region Function Test-TargetResource
Describe "MSFT_UpdateServicesCleanup\Test-TargetResource" {
    Context 'server is in correct state (Ensure=Present)' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure','Present')
            Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
            $script:result = $null
        }

        it 'calling test should not throw' {
            {$script:result = Test-TargetResource @DSCTestValues -verbose} | should -Not -Throw

            Should -Invoke Get-TargetResource -Exactly 1
        }

        it "result should be true" {
            $script:result | should -BeTrue
        }
    }

    Context 'server should not be configured (Ensure=Absent)' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure','Absent')
            Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
            $script:result = $null
        }

        it 'calling test should not throw' {
            {$script:result = Test-TargetResource @DSCTestValues -verbose} | should -Not -Throw

            Should -Invoke Get-TargetResource -Exactly 1
        }

        it "result should be true" {
            $script:result | should -BeTrue
        }
    }

    Context 'server should be configured correctly but is not' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
            $script:result = $null
        }

        it 'calling test should not throw' {
            {$script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -verbose} | should -Not -Throw

            Should -Invoke Get-TargetResource -Exactly 1
        }

        it "result should be false" {
            $script:result | should -BeFalse
        }
    }

    Context "setting has drifted" {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure','Present')
        }

        $settingsList = @(
            'DeclineSupersededUpdates'
            'DeclineExpiredUpdates'
            'CleanupObsoleteUpdates'
            'CompressUpdates'
            'CleanupObsoleteComputers'
            'CleanupUnneededContentFiles'
            'CleanupLocalPublishedContentFiles'
        )

        Context 'When <_> property is invalid' -Foreach $settingsList {
            BeforeAll {
                $setting = $_
                Mock -CommandName Get-TargetResource -MockWith {
                    $DSCTestValuesClone = $DSCTestValues.Clone()
                    $DSCTestValuesClone.Remove("$setting")
                    $DSCTestValuesClone
                }

                $script:result = $null
            }

            it 'calling test should not throw' {
                {$script:result = Test-TargetResource @DSCTestValues -verbose} | should -Not -Throw

                Should -Invoke Get-TargetResource -Exactly 1
            }

            it "result should be false when <_> has changed" {
                $script:result | should -BeFalse
            }

            AfterAll {
                #$DSCTestValues.Add("$setting",$true)
            }
        }
    }
}
#endregion

#region Function Set-TargetResource
Describe "MSFT_UpdateServicesCleanup\Set-TargetResource" {
    BeforeAll {
        $Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
        $Execute = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
        $StartBoundary = '20160101T04:00:00'
        Mock -CommandName Unregister-ScheduledTask -MockWith {}
        Mock -CommandName Register-ScheduledTask -MockWith {}
        Mock -CommandName Test-TargetResource -MockWith {$true}
        Mock -CommandName New-InvalidResultException -MockWith {}
    }

    Context 'resource is idempotent (Ensure=Present)' {
        BeforeAll {
            Mock -CommandName Get-ScheduledTask -MockWith {$true}
        }

        it 'should not throw when running on a properly configured server' {
            {Set-targetResource @DSCSetValues -Ensure Present -verbose} | should -Not -Throw

            #mocks were called for commands that gather information
            Should -Invoke Get-ScheduledTask -Exactly 1
            Should -Invoke Unregister-ScheduledTask -Exactly 1
            Should -Invoke Register-ScheduledTask -Exactly 1
            Should -Invoke Test-TargetResource -Exactly 1

            #mocks were called that register a task to run WSUS cleanup
            Should -Invoke Register-ScheduledTask -Exactly 1

            #mocks were not called that remove tasks or log errors
            Should -Invoke New-InvalidResultException -Exactly 0
        }
    }

    Context 'resource processes Set tasks to register Cleanup task (Ensure=Present)' {
        BeforeAll {
            Mock -CommandName Get-ScheduledTask -MockWith {}
        }

        it 'should not throw when running on a properly configured server' {
            {Set-targetResource @DSCSetValues -Ensure Present -verbose} | should -Not -Throw

            #mocks were called for commands that gather information
            Should -Invoke Get-ScheduledTask -Exactly 1
            Should -Invoke Register-ScheduledTask -Exactly 1
            Should -Invoke Test-TargetResource -Exactly 1

            #mocks were called that register a task to run WSUS cleanup
            Should -Invoke Register-ScheduledTask -Exactly 1

            #mocks were not called that remove tasks or log errors
            Should -Invoke Unregister-ScheduledTask -Exactly 0
            Should -Invoke New-InvalidResultException -Exactly 0
        }
    }

    Context 'resource processes Set tasks to remove Cleanup task (Ensure=Absent)' {
        BeforeAll {
            Mock -CommandName Get-ScheduledTask -MockWith {$true}
        }

        it 'should not throw when running on a properly configured server' {
            {Set-targetResource @DSCSetValues -Ensure Absent -verbose} | should -Not -Throw

            #mocks were called for commands that gather information
            Should -Invoke Get-ScheduledTask -Exactly 1
            Should -Invoke Test-TargetResource -Exactly 1

            #mocks were called that register a task to run WSUS cleanup
            Should -Invoke Unregister-ScheduledTask -Exactly 1

            #mocks were not called that remove tasks or log errors
            Should -Invoke Register-ScheduledTask -Exactly 0
            Should -Invoke New-InvalidResultException -Exactly 0
        }
    }
}
#endregion
