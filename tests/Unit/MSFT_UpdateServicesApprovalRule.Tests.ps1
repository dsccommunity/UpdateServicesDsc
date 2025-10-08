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

    # Unload the module being tested so that It doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

# BeforeAll {
#     $script:WsusServer = [pscustomobject]@{
#         Name = 'ServerName'
#     }

#     $DSCSetValues = @{
#         Name            = $script:WsusServer.Name
#         Classifications = "00000000-0000-0000-0000-0000testguid"
#         Products        = "Product"
#         ComputerGroups  = "Computer Target Group"
#         Enabled         = $true
#     }

#     $DSCTestValues = @{
#         Name            = $script:WsusServer.Name
#         Classifications = "00000000-0000-0000-0000-0000testguid"
#         Products        = "Product"
#         ComputerGroups  = "Computer Target Group"
#         Enabled         = $true
#     }
# }

Describe 'MSFT_UpdateServicesApprovalRule\Get-TargetResource' -Tag 'Get' {
    Context 'When the server should be configured' {
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
        }
    }
}

Describe 'MSFT_UpdateServicesApprovalRule\Test-TargetResource' -Skip:$true {
    Context 'server is in correct state (Ensure=Present)' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure', 'Present')
            $script:result = $null
        }

        It 'calling test should not throw' {
            { $script:result = Test-TargetResource @DSCTestValues -verbose } | Should -not -throw
        }

        It 'result should be true' {
            $script:result | Should -Be $true
        }
    }

    Context 'server should not be configured (Ensure=Absent) but is' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure', 'Absent')
            $script:result = $null
        }

        It 'calling test should not throw' {
            { $script:result = Test-TargetResource @DSCTestValues -verbose } | Should -not -throw
        }

        It 'result should be false' {
            $script:result | Should -BeFalse
        }
    }

    Context 'setting has drifted' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure', 'Present')
        }

        $settingsList = 'Classifications', 'Products', 'ComputerGroups'
        Context 'When <_> property is drifted' -Foreach $settingsList {
            BeforeAll {
                #$valueWithoutDrift = $DSCTestValues.$_
            }

            It 'calling test should not throw' {
                $DSCTestValuesDrifted = $DSCTestValues.Clone()
                $DSCTestValuesDrifted["$_"] = 'foo'
                $script:result = $null
                { $script:result = Test-TargetResource @DSCTestValuesDrifted -verbose } | Should -Not -Throw
            }

            It "result should be false when $setting has changed" {
                $script:result | Should -BeFalse
            }

            BeforeAll {
                #$DSCTestValues.Remove("$_")
                #$DSCTestValues.Add("$_",$valueWithoutDrift)
            }
        }
    }
}

#region Function Set-TargetResource
Describe 'MSFT_UpdateServicesApprovalRule\Set-TargetResource' -Skip:$true {
    BeforeAll {
        $Collection = [pscustomobject]@{}
        $Collection | Add-Member -MemberType ScriptMethod -Name Add -Value {}
    }

    Context 'server is already in a correct state (resource is idempotent)' {
        BeforeAll {
            Mock New-Object -mockwith { $Collection }
            Mock Get-WsusProduct -mockwith {}
            Mock -CommandName New-InvalidOperationException -MockWith {}
            Mock -CommandName New-InvalidResultException -MockWith {}
            Mock -CommandName New-InvalidArgumentException -MockWith {}
        }

        It 'should not throw when running on a properly configured server' {
            { Set-targetResource @DSCSetValues -verbose } | Should -Not -Throw

            #mock were called
            Should -Invoke New-Object -Exactly 3
            Should -Invoke Get-WsusProduct -Exactly 1

            #mock are not called
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-InvalidArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }

    Context 'server is not in a correct state (resource takes action)' {
        BeforeAll {
            Mock New-Object -mockwith { $Collection }
            Mock Get-WsusProduct -mockwith {}
            Mock -CommandName New-InvalidOperationException -MockWith {}
            Mock -CommandName New-InvalidResultException -MockWith {}
            Mock -CommandName New-InvalidArgumentException -MockWith {}
            Mock Test-TargetResource -mockwith { $true }
        }

        It 'should not throw when running on an incorrectly configured server' {
            { Set-targetResource -Name 'Foo' -Classification '00000000-0000-0000-0000-0000testguid' -verbose } | Should -Not -Throw

            #mock were called
            Should -Invoke New-Object -Exactly 3
            Should -Invoke Test-TargetResource -Exactly 1
            Should -Invoke Get-WsusProduct -Exactly 1

            #mock are not called
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-InvalidArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }

    Context 'server should not be configured (Ensure=Absent)' {
        BeforeAll {
            Mock New-Object -mockwith { $Collection }
            Mock Get-WsusProduct -mockwith {}
            Mock -CommandName New-InvalidOperationException -MockWith {}
            Mock -CommandName New-InvalidResultException -MockWith {}
            Mock -CommandName New-InvalidArgumentException -MockWith {}
            Mock Test-TargetResource -mockwith { $true }
        }

        It 'should not throw when running on an incorrectly configured server' {
            { Set-targetResource @DSCSetValues -Ensure Absent -verbose } | Should -Not -Throw

            #mock were called
            Should -Invoke Test-TargetResource -Exactly 1

            #mock are not called
            Should -Invoke New-Object -Exactly 0
            Should -Invoke Get-WsusProduct -Exactly 0
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-InvalidArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }

    Context 'server is in correct state and synchronize is included' {
        BeforeAll {
            Mock New-Object -mockwith { $Collection }
            Mock Get-WsusProduct -mockwith {}
            Mock -CommandName New-InvalidOperationException -MockWith {}
            Mock -CommandName New-InvalidResultException -MockWith {}
            Mock -CommandName New-InvalidArgumentException -MockWith {}
            Mock Test-TargetResource -mockwith { $true }
        }

        It 'should not throw when running on a properly configured server' {
            { Set-targetResource @DSCSetValues -Synchronize $true -verbose } | Should -Not -Throw

            #mock were called
            Should -Invoke New-Object -Exactly 3
            Should -Invoke Test-TargetResource -Exactly 1
            Should -Invoke Get-WsusProduct -Exactly 1

            #mock are not called
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-InvalidArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }
}
