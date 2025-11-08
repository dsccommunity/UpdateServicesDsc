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
    $script:dscResourceName = 'DSC_UpdateServicesComputerTargetGroup'

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

Describe 'DSC_UpdateServicesComputerTargetGroup\Get-ComputerTargetGroupPath' -Tag 'Private' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:WsusServer = CommonTestHelper\Get-WsusServerTemplate
        }
    }

    Context 'When getting the path for the ''All Computers'' ComputerTargetGroup' {
        It 'Should return the correct path' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $ComputerTargetGroup = $script:WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'All Computers' }
                Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup | Should -Be 'All Computers'
            }
        }
    }

    Context 'When getting the path for the ''Desktops'' ComputerTargetGroup' {
        It 'Should return the correct path' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $ComputerTargetGroup = $script:WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'Desktops' }
                Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup | Should -Be 'All Computers/Workstations'
            }
        }
    }

    Context 'When getting the path for the ''Workstations'' ComputerTargetGroup' {
        It 'Should return the correct path' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $ComputerTargetGroup = $script:WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'Workstations' }
                Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup | Should -Be 'All Computers'
            }
        }
    }
}


Describe 'DSC_UpdateServicesComputerTargetGroup\Get-TargetResource' -Tag 'Get' {
    Context 'When an error occurs retrieving WSUS Server configuration information' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith { throw 'An error occurred' }
        }

        It 'Should throw when an error occurs retrieving WSUS Server information' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.WSUSConfigurationFailed

                $testParams = @{
                    Name = 'Servers'
                    Path = 'All Computers'
                }

                { Get-TargetResource @testParams } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the WSUS Server is not yet configured' {
        BeforeAll {
            Mock -CommandName Get-WsusServer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'Servers'
                    Path = 'All Computers'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Absent'
                $result.Id | Should -BeNullOrEmpty
                $result.Name | Should -Be 'Servers'
                $result.Path | Should -Be 'All Computers'
            }

            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the Computer Target Group is not in the desired state (specified name does not exist at any path)' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'Domain Controllers'
                    Path = 'All Computers'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Absent'
                $result.Id | Should -BeNullOrEmpty
                $result.Name | Should -Be 'Domain Controllers'
                $result.Path | Should -Be 'All Computers'
            }
        }
    }

    Context 'When the Computer Target Group is not in the desired state (specified name exists but not at the desired path)' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.DuplicateComputerTargetGroup -f
                    'Desktops', 'All Computers/Workstations')

                $testParams = @{
                    Name = 'Desktops'
                    Path = 'All Computers/Servers'
                }

                { Get-TargetResource @testParams } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }
        }
    }

    Context 'When the Computer Target Group is in the desired state (specified name exists with the desired path)' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'Desktops'
                    Path = 'All Computers/Workstations'
                }

                $result = Get-TargetResource @testParams

                $result.Ensure | Should -Be 'Present'
                $result.Id | Should -Be '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                $result.Name | Should -Be 'Desktops'
                $result.Path | Should -Be 'All Computers/Workstations'
            }
        }
    }
}

Describe 'DSC_UpdateServicesComputerTargetGroup\Test-TargetResource' -Tag 'Test' {
    Context 'When the Computer Target Group ''Desktops'' is ''Present'' at Path ''All Computers/Workstations'' which is the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure = 'Present'
                    Name   = 'Desktops'
                    Path   = 'All Computers/Workstations'
                    Id     = '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name   = 'Desktops'
                    Path   = 'All Computers/Workstations'
                    Ensure = 'Present'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }

            Should -Invoke -CommandName Get-TargetResource -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the Computer Target Group ''Desktops'' is ''Absent'' at Path ''All Computers/Workstations'' which is the desired state (Present)' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure = 'Absent'
                    Name   = 'Desktops'
                    Path   = 'All Computers/Workstations'
                    Id     = $null
                }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name   = 'Desktops'
                    Path   = 'All Computers/Workstations'
                    Ensure = 'Absent'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }

            Should -Invoke -CommandName Get-TargetResource -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the Computer Target Group ''Desktops'' is ''Present'' at Path ''All Computers/Workstations'' which is NOT the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure = 'Present'
                    Name   = 'Desktops'
                    Path   = 'All Computers/Workstations'
                    Id     = '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name   = 'Desktops'
                    Path   = 'All Computers/Workstations'
                    Ensure = 'Absent'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Get-TargetResource -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the Computer Target Group ''Desktops'' is ''Absent'' at Path ''All Computers/Workstations'' which is NOT the desired state (Present)' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure = 'Absent'
                    Name   = 'Desktops'
                    Path   = 'All Computers/Workstations'
                    Id     = $null
                }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name   = 'Desktops'
                    Path   = 'All Computers/Workstations'
                    Ensure = 'Present'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Get-TargetResource -Times 1 -Exactly -Scope It
        }
    }
}

Describe 'DSC_UpdateServicesComputerTargetGroup\Set-TargetResource' -Tag 'Set' {
    Context 'When an error occurs retrieving WSUS Server configuration information' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith { throw 'An error occurred' }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.WSUSConfigurationFailed

                $testParams = @{
                    Name = 'Servers'
                    Path = 'All Computers'
                }

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the WSUS Server is not yet configured' {
        BeforeAll {
            Mock -CommandName Get-WsusServer
        }

        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'Servers'
                    Path = 'All Computers'
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the Parent of the Computer Target Group is not present and therefore the new group cannot be created' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }

            Mock -CommandName Write-Warning
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'Win10'
                    Path = 'All Computers/Desktops'
                }

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.NotFoundParentComputerTargetGroup -f @(
                        'Desktops', 'All Computers', $testParams.Name
                    )
                )

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the new Computer Target Group (at Root Level) is successfully created' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }
        }

        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'Member Servers'
                    Path = 'All Computers'
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the new Computer Target Group is successfully created' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }
        }

        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name = 'Database'
                    Path = 'All Computers/Servers'
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly -Scope It
        }
    }

    Context 'When the new Computer Target Group is successfully deleted' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }
        }

        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name   = 'Web'
                    Path   = 'All Computers/Servers'
                    Ensure = 'Absent'
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly -Scope It
        }
    }
}
