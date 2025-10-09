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
    $script:dscResourceName = 'MSFT_UpdateServicesApprovalRule'

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

Describe 'MSFT_UpdateServicesApprovalRule\Get-TargetResource' -Tag 'Get' {
    Context 'When the server should be configured with specific classifications, products and computer groups' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name 'ServerName'

                $result.Ensure | Should -Be 'Present'
                $result.Classifications | Should -Be '00000000-0000-0000-0000-0000testguid'
                $result.Products | Should -Be 'Product'
                $result.ComputerGroups | Should -Be 'Computer Target Group'
                $result.Enabled | Should -BeTrue
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the server should be configured with default classifications, products and computer groups' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                $obj = [PSCustomObject] @{}
                $obj | Add-Member -Force -MemberType ScriptMethod -Name GetInstallApprovalRules -Value {
                    $ApprovalRule = [PSCustomObject] @{
                        Name    = 'ServerName'
                        Enabled = $true
                    }

                    $ApprovalRule | Add-Member -Force -MemberType ScriptMethod -Name GetUpdateClassifications -Value { return }

                    $ApprovalRule | Add-Member -Force -MemberType ScriptMethod -Name GetCategories -Value { return }

                    $ApprovalRule | Add-Member -Force -MemberType ScriptMethod -Name GetComputerTargetGroups -Value { return }

                    return $ApprovalRule
                }

                return $obj
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name 'ServerName'

                $result.Ensure | Should -Be 'Present'
                $result.Classifications | Should -Be @('All Classifications')
                $result.Products | Should -Be @('All Products')
                $result.ComputerGroups | Should -Be @('All Computers')
                $result.Enabled | Should -BeTrue
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the server should not be configured' {
        BeforeAll {
            Mock -CommandName Get-WSUSServer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name 'ServerName'

                $result.Ensure | Should -Be 'Absent'
                $result.Classifications | Should -BeNullOrEmpty
                $result.Products | Should -BeNullOrEmpty
                $result.ComputerGroups | Should -BeNullOrEmpty
                $result.Enabled | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the server is not configured' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                $obj = [PSCustomObject] @{}
                $obj | Add-Member -Force -MemberType ScriptMethod -Name GetInstallApprovalRules -Value {
                    $ApprovalRule = [PSCustomObject] @{
                        Name    = 'ServerName'
                        Enabled = $true
                    }

                    $ApprovalRule | Add-Member -Force -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
                        return @{
                            Name = 'Update Classification'
                            ID   = @{
                                GUID = '00000000-0000-0000-0000-0000testguid'
                            }
                        }
                    }

                    $ApprovalRule | Add-Member -Force -MemberType ScriptMethod -Name GetCategories -Value {
                        return @{
                            Title = 'Product'
                        }
                    }

                    $ApprovalRule | Add-Member -Force -MemberType ScriptMethod -Name GetComputerTargetGroups -Value {
                        return @{
                            Name = 'Computer Target Group'
                        }
                    }

                    return $ApprovalRule
                }

                return $obj
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Name 'Foo'

                    $result.Ensure | Should -Be 'Absent'
                    $result.Classifications | Should -BeNullOrEmpty
                    $result.Products | Should -BeNullOrEmpty
                    $result.ComputerGroups | Should -BeNullOrEmpty
                    $result.Enabled | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the server throws an error' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                throw 'Some error'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.WSUSConfigurationFailed

                { Get-TargetResource -Name 'ServerName' } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'MSFT_UpdateServicesApprovalRule\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource is in the desired state' {
        Context 'When the resource exists' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure          = 'Present'
                        Name            = 'ServerName'
                        Classifications = @('00000000-0000-0000-0000-0000testguid')
                        Products        = @('Product')
                        ComputerGroups  = @('Computer Target Group')
                        Enabled         = $true
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure          = 'Present'
                        Name            = 'ServerName'
                        Classifications = @('00000000-0000-0000-0000-0000testguid')
                        Products        = @('Product')
                        ComputerGroups  = @('Computer Target Group')
                        Enabled         = $true
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }

        Context 'When the resource does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure          = 'Absent'
                        Name            = 'ServerName'
                        Classifications = $null
                        Products        = $null
                        ComputerGroups  = $null
                        Enabled         = $null
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure = 'Absent'
                        Name   = 'ServerName'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        Context 'When the resource exists' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure          = 'Present'
                        Name            = 'ServerName'
                        Classifications = @('00000000-0000-0000-0000-0000testguid')
                        Products        = @('Product')
                        ComputerGroups  = @('Computer Target Group')
                        Enabled         = $true
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure = 'Absent'
                        Name   = 'ServerName'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }
            }
        }

        Context 'When the resource does not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure          = 'Absent'
                        Name            = 'ServerName'
                        Classifications = $null
                        Products        = $null
                        ComputerGroups  = $null
                        Enabled         = $null
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure          = 'Present'
                        Name            = 'ServerName'
                        Classifications = @('00000000-0000-0000-0000-0000testguid')
                        Products        = @('Product')
                        ComputerGroups  = @('Computer Target Group')
                        Enabled         = $true
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{
                    PropertyName = 'Classifications'
                    Value        = 'foo'
                },
                @{
                    PropertyName = 'Products'
                    Value        = 'foo'
                },
                @{
                    PropertyName = 'ComputerGroups'
                    Value        = 'foo'
                }
                @{
                    PropertyName = 'Enabled'
                    Value        = $false
                }
            )
        }

        Context 'When the property <PropertyName> is incorrect' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    $obj = @{
                        Ensure          = 'Present'
                        Name            = 'ServerName'
                        Classifications = @('00000000-0000-0000-0000-0000testguid')
                        Products        = @('Product')
                        ComputerGroups  = @('Computer Target Group')
                        Enabled         = $true
                    }

                    $obj[$PropertyName] = $Value

                    return $obj
                }
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure          = 'Present'
                        Name            = 'ServerName'
                        Classifications = @('00000000-0000-0000-0000-0000testguid')
                        Products        = @('Product')
                        ComputerGroups  = @('Computer Target Group')
                        Enabled         = $true
                    }

                    $result = Test-TargetResource @testParams

                    $result | Should -BeFalse
                }
            }
        }
    }
}

Describe 'MSFT_UpdateServicesApprovalRule\Set-TargetResource' -Tag 'Set' {
    Context 'When setting the resource fails' {
        BeforeAll {
            Mock Get-WsusServer -MockWith {
                throw 'Some error'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Name           = 'ServerName'
                    Classification = @('00000000-0000-0000-0000-0000testguid')
                }

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.RuleFailedToCreate -f $testParams.Name)

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting the WSUS server fails' {
        BeforeAll {
            Mock -CommandName Get-WsusServer
            Mock -CommandName Test-TargetResource -MockWith { $true }
        }

        Context 'When property ''Synchronize'' is $false the resource should not throw' {
            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Name           = 'ServerName'
                        Classification = @('00000000-0000-0000-0000-0000testguid')
                    }

                    $null = Set-TargetResource @testParams
                }

                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the approval rule already exists' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerTemplate
            }

            Mock -CommandName New-Object -MockWith {
                $obj = [PSCustomObject] @{}
                $obj | Add-Member -Force -MemberType ScriptMethod -Name Add -Value { return }
                return $obj
            }

            Mock -CommandName Get-WsusClassification -MockWith {
                return [PSCustomObject] @{
                    Classification = [PSCustomObject] @{
                        ID = [PSCustomObject] @{
                            Guid = '00000000-0000-0000-0000-0000testguid'
                        }
                    }
                }
            }

            Mock -CommandName Get-WsusProduct -MockWith {
                return [PSCustomObject] @{
                    Title = 'Product'
                    Id    = 'SomeId'
                }
            }
            Mock -CommandName Test-TargetResource -MockWith { $true }
        }

        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure         = 'Present'
                    Name           = 'ServerName'
                    Classification = @('00000000-0000-0000-0000-0000testguid')
                    Products       = @('Product')
                    ComputerGroups = @('Computer Target Group')
                    Enabled        = $true
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-WsusClassification -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-WsusProduct -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
        }

        Context 'When the classification does not exist' {
            BeforeAll {
                Mock -CommandName Get-WsusClassification
                Mock -CommandName Get-WsusProduct
                Mock -CommandName Test-TargetResource -MockWith { $true }
            }

            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure         = 'Present'
                        Name           = 'ServerName'
                        Classification = @('00000000-0000-0000-0000-0000testguid')
                        Products       = @('Product')
                        ComputerGroups = @('Computer Target Group')
                        Enabled        = $true
                    }

                    $null = Set-TargetResource @testParams
                }

                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WsusClassification -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WsusProduct -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the approval rule should be created' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                $template = CommonTestHelper\Get-WsusServerTemplate
                $template | Add-Member -Force -MemberType ScriptMethod -Name GetInstallApprovalRules -Value { return }

                return $template
            }

            Mock -CommandName New-Object -MockWith {
                $obj = [PSCustomObject] @{}
                $obj | Add-Member -Force -MemberType ScriptMethod -Name Add -Value { return }
                return $obj
            }

            Mock -CommandName Get-WsusClassification -MockWith {
                return [PSCustomObject] @{
                    Classification = [PSCustomObject] @{
                        ID = [PSCustomObject] @{
                            Guid = '00000000-0000-0000-0000-0000testguid'
                        }
                    }
                }
            }

            Mock -CommandName Get-WsusProduct
            Mock -CommandName Test-TargetResource -MockWith { $true }
        }

        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure         = 'Present'
                    Name           = 'ServerName'
                    Classification = @('00000000-0000-0000-0000-0000testguid')
                    Products       = @('Product')
                    ComputerGroups = @('Computer Target Group')
                    Enabled        = $true
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-WsusClassification -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-WsusProduct -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the approval rule should be removed' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                CommonTestHelper\Get-WsusServerTemplate
            }

            Mock -CommandName New-Object -MockWith {
                $obj = [PSCustomObject] @{}
                $obj | Add-Member -Force -MemberType ScriptMethod -Name Add -Value { return }
                return $obj
            }

            Mock -CommandName Get-WsusClassification -MockWith {
                return [PSCustomObject] @{
                    Classification = [PSCustomObject] @{
                        ID = [PSCustomObject] @{
                            Guid = '00000000-0000-0000-0000-0000testguid'
                        }
                    }
                }
            }

            Mock -CommandName Get-WsusProduct
            Mock -CommandName Test-TargetResource -MockWith { $true }
        }

        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure         = 'Absent'
                    Name           = 'ServerName'
                    Classification = @('00000000-0000-0000-0000-0000testguid')
                    Products       = @('Product')
                    ComputerGroups = @('Computer Target Group')
                    Enabled        = $true
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-WsusClassification -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-WsusProduct -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the approval rule does not create' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                $template = CommonTestHelper\Get-WsusServerTemplate
                $template | Add-Member -Force -MemberType ScriptMethod -Name GetInstallApprovalRules -Value { return }
                $template | Add-Member -Force -MemberType ScriptMethod -Name CreateInstallApprovalRule -Value { return }

                return $template
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure         = 'Present'
                    Name           = 'ServerName'
                    Classification = @('00000000-0000-0000-0000-0000testguid')
                    Products       = @('Product')
                    ComputerGroups = @('Computer Target Group')
                    Enabled        = $true
                }

                $errorRecord = Get-InvalidOperationRecord -Message ($script:localizedData.RuleFailedToCreate -f $testParams.Name)

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
        }
    }
}
