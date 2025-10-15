# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscResourceName = 'DSC_UpdateServicesCleanup'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Load stub cmdlets and classes.
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\UpdateServices.stubs.psm1')
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload stub module
    Remove-Module -Name UpdateServices.stubs -Force
    Remove-Module -Name CommonTestHelper -Force

    # Unload the module being tested so that It doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_UpdateServicesCleanup\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    State    = 'Enabled'
                    Actions  = @{
                        Execute   = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
                        Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
                    }
                    Triggers = @{
                        StartBoundary = '20160101T04:00:00'
                    }
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Ensure 'Present'

                $result.Ensure | Should -Be 'Present'
                $result.DeclineSupersededUpdates | Should -BeTrue
                $result.DeclineExpiredUpdates | Should -BeTrue
                $result.CleanupObsoleteUpdates | Should -BeTrue
                $result.CompressUpdates | Should -BeTrue
                $result.CleanupObsoleteComputers | Should -BeTrue
                $result.CleanupUnneededContentFiles | Should -BeTrue
                $result.CleanupLocalPublishedContentFiles | Should -BeTrue
                $result.TimeOfDay | Should -Be ('20160101T04:00:00'.Split('T')[1])

                Should -Invoke -CommandName Get-ScheduledTask -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        Context 'When the resource is not configured' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    # ISSUE: does not pass strict mode.
                    # Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Ensure 'Absent'

                    $result.Ensure | Should -Be 'Absent'
                    $result.DeclineSupersededUpdates | Should -BeNullOrEmpty
                    $result.DeclineExpiredUpdates | Should -BeNullOrEmpty
                    $result.CleanupObsoleteUpdates | Should -BeNullOrEmpty
                    $result.CompressUpdates | Should -BeNullOrEmpty
                    $result.CleanupObsoleteComputers | Should -BeNullOrEmpty
                    $result.CleanupUnneededContentFiles | Should -BeNullOrEmpty
                    $result.CleanupLocalPublishedContentFiles | Should -BeNullOrEmpty
                    $result.TimeOfDay | Should -BeNullOrEmpty

                    Should -Invoke -CommandName Get-ScheduledTask -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the resource is configured incorrectly' {
            BeforeAll {
                Mock Get-ScheduledTask -MockWith {
                    @{
                        State    = 'Disabled'
                        Actions  = @{
                            Execute   = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
                            Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
                        }
                        Triggers = @{
                            StartBoundary = '20160101T04:00:00'
                        }
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    # ISSUE: does not pass strict mode.
                    # Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Ensure 'Absent'

                    $result.Ensure | Should -Be 'Absent'
                    $result.DeclineSupersededUpdates | Should -BeNullOrEmpty
                    $result.DeclineExpiredUpdates | Should -BeNullOrEmpty
                    $result.CleanupObsoleteUpdates | Should -BeNullOrEmpty
                    $result.CompressUpdates | Should -BeNullOrEmpty
                    $result.CleanupObsoleteComputers | Should -BeNullOrEmpty
                    $result.CleanupUnneededContentFiles | Should -BeNullOrEmpty
                    $result.CleanupLocalPublishedContentFiles | Should -BeNullOrEmpty
                    $result.TimeOfDay | Should -BeNullOrEmpty

                    Should -Invoke -CommandName Get-ScheduledTask -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}

Describe 'DSC_UpdateServicesCleanup\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource is in the desired state' {
        Context 'When the resource should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure                            = 'Present'
                        DeclineSupersededUpdates          = $true
                        DeclineExpiredUpdates             = $true
                        CleanupObsoleteUpdates            = $true
                        CompressUpdates                   = $true
                        CleanupObsoleteComputers          = $true
                        CleanupUnneededContentFiles       = $true
                        CleanupLocalPublishedContentFiles = $true
                        TimeOfDay                         = '04:00:00'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                            = 'Present'
                        DeclineSupersededUpdates          = $true
                        DeclineExpiredUpdates             = $true
                        CleanupObsoleteUpdates            = $true
                        CompressUpdates                   = $true
                        CleanupObsoleteComputers          = $true
                        CleanupUnneededContentFiles       = $true
                        CleanupLocalPublishedContentFiles = $true
                        TimeOfDay                         = '04:00:00'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the resource should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure = 'Absent'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        Context 'When the resource should be present but is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                            = 'Present'
                        DeclineSupersededUpdates          = $true
                        DeclineExpiredUpdates             = $true
                        CleanupObsoleteUpdates            = $true
                        CompressUpdates                   = $true
                        CleanupObsoleteComputers          = $true
                        CleanupUnneededContentFiles       = $true
                        CleanupLocalPublishedContentFiles = $true
                        TimeOfDay                         = '04:00:00'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the resource should be absent but is present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure                            = 'Present'
                        DeclineSupersededUpdates          = $true
                        DeclineExpiredUpdates             = $true
                        CleanupObsoleteUpdates            = $true
                        CompressUpdates                   = $true
                        CleanupObsoleteComputers          = $true
                        CleanupUnneededContentFiles       = $true
                        CleanupLocalPublishedContentFiles = $true
                        TimeOfDay                         = '04:00:00'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure = 'Absent'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{
                    Setting      = 'DeclineSupersededUpdates'
                    CurrentValue = $false
                },
                @{
                    Setting      = 'DeclineExpiredUpdates'
                    CurrentValue = $false
                },
                @{
                    Setting      = 'CleanupObsoleteUpdates'
                    CurrentValue = $false
                },
                @{
                    Setting      = 'CompressUpdates'
                    CurrentValue = $false
                },
                @{
                    Setting      = 'CleanupObsoleteComputers'
                    CurrentValue = $false
                },
                @{
                    Setting      = 'CleanupUnneededContentFiles'
                    CurrentValue = $false
                },
                @{
                    Setting      = 'CleanupLocalPublishedContentFiles'
                    CurrentValue = $false
                }
            )
        }

        Context 'When the setting <Setting> is different' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure                            = 'Present'
                        DeclineSupersededUpdates          = $true
                        DeclineExpiredUpdates             = $true
                        CleanupObsoleteUpdates            = $true
                        CompressUpdates                   = $true
                        CleanupObsoleteComputers          = $true
                        CleanupUnneededContentFiles       = $true
                        CleanupLocalPublishedContentFiles = $true
                        TimeOfDay                         = '04:00:00'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                            = 'Present'
                        DeclineSupersededUpdates          = $true
                        DeclineExpiredUpdates             = $true
                        CleanupObsoleteUpdates            = $true
                        CompressUpdates                   = $true
                        CleanupObsoleteComputers          = $true
                        CleanupUnneededContentFiles       = $true
                        CleanupLocalPublishedContentFiles = $true
                        TimeOfDay                         = '04:00:00'
                    }

                    $testParams[$Setting] = $CurrentValue

                    Test-TargetResource @testParams | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_UpdateServicesCleanup\Set-TargetResource' -Tag 'Set' {
    Context 'When the resource should be absent' {
        Context 'When the resource is absent' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask
                Mock -CommandName Test-TargetResource -MockWith { $true }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $null = Set-TargetResource -Ensure 'Absent'
                }

                Should -Invoke -CommandName Get-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the resource is present' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask -MockWith { $true }
                Mock -CommandName Unregister-ScheduledTask
                Mock -CommandName Test-TargetResource -MockWith { $true }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $null = Set-TargetResource -Ensure 'Absent'
                }

                Should -Invoke -CommandName Get-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Unregister-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When ''Test-TargetResource'' fails' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask -MockWith { $true }
                Mock -CommandName Unregister-ScheduledTask
                Mock -CommandName Test-TargetResource -MockWith { $false }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorRecord = Get-InvalidResultRecord -Message $script:localizedData.TestFailedAfterSet

                    { Set-TargetResource -Ensure 'Absent' } | Should -Throw -ExpectedMessage $errorRecord.Exception.Message
                }

                Should -Invoke -CommandName Get-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Unregister-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the resource should be present' {
        Context 'When the resource is present' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask -MockWith { $true }
                Mock -CommandName Unregister-ScheduledTask
                Mock -CommandName Register-ScheduledTask -RemoveParameterValidation @('Action', 'Trigger') -RemoveParameterType @('Action', 'Trigger')
                Mock -CommandName Test-TargetResource -MockWith { $true }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                      = 'Present'
                        DeclineSupersededUpdates    = $true
                        DeclineExpiredUpdates       = $true
                        CleanupObsoleteUpdates      = $true
                        CompressUpdates             = $true
                        CleanupObsoleteComputers    = $true
                        CleanupUnneededContentFiles = $true
                        TimeOfDay                   = '04:00:00'
                    }

                    $null = Set-TargetResource @testParams
                }

                Should -Invoke -CommandName Get-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Unregister-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Register-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the resource is absent' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask
                Mock -CommandName Unregister-ScheduledTask
                Mock -CommandName Register-ScheduledTask
                Mock -CommandName Test-TargetResource -MockWith { $true }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                      = 'Present'
                        DeclineSupersededUpdates    = $true
                        DeclineExpiredUpdates       = $true
                        CleanupObsoleteUpdates      = $true
                        CompressUpdates             = $true
                        CleanupObsoleteComputers    = $true
                        CleanupUnneededContentFiles = $true
                        TimeOfDay                   = '04:00:00'
                    }

                    $null = Set-TargetResource @testParams
                }

                Should -Invoke -CommandName Get-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Unregister-ScheduledTask -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Register-ScheduledTask -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}
