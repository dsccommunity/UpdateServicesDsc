$script:dscModuleName = 'UpdateServicesDsc'
$script:dscResourceName = 'MSFT_UpdateServicesApprovalRule'

#region HEADER
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module -Name DscResource.Test -Force -ErrorAction Stop

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#region Pester Test Initialization
Import-Module $PSScriptRoot\..\Helpers\ImitateUpdateServicesModule.psm1 -force -ErrorAction Stop
#Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\source\Modules\PDT\PDT.psm1') -force -ErrorAction Stop

#endregion HEADER


# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        BeforeAll {
            $script:WsusServer = [pscustomobject]@{
                Name = 'ServerName'
            }

            $DSCSetValues = @{
                Name = $script:WsusServer.Name
                Classifications = "00000000-0000-0000-0000-0000testguid"
                Products = "Product"
                ComputerGroups = "Computer Target Group"
                Enabled = $true
            }

            $DSCTestValues = @{
                Name = $script:WsusServer.Name
                Classifications = "00000000-0000-0000-0000-0000testguid"
                Products = "Product"
                ComputerGroups = "Computer Target Group"
                Enabled = $true
            }
        }
        #endregion

        #region Function Get-TargetResource expecting Ensure Present
        Describe "MSFT_UpdateServicesApprovalRule\Get-TargetResource" {
            BeforeAll {
                Mock -CommandName New-InvalidOperationException -MockWith {}
                Mock -CommandName New-InvalidResultException -MockWith {}
                Mock -CommandName New-InvalidArgumentException -MockWith {}
            }

            Context 'server should be configured.' {

                it 'calling Get should not throw' {
                    {$Script:resource = Get-TargetResource -Name $script:WsusServer.Name -verbose} | should -not -throw
                }

                it "Ensure" {
                    $Script:resource.Ensure | should -Be 'Present'
                }

                it "Classifications" {
                    $Script:resource.Classifications | should -Be $DSCSetValues.Classifications
                }

                it "Products" {
                    $Script:resource.Products | should -Be $DSCSetValues.Products
                }

                it "Computer Groups" {
                    $Script:resource.ComputerGroups | should -Be $DSCSetValues.ComputerGroups
                }

                it "Enabled" {
                    $Script:resource.Enabled | should -Be $DSCSetValues.Enabled
                }

                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-InvalidResultException -Times 0
                    Assert-MockCalled -CommandName New-InvalidArgumentException -Times 0
                    Assert-MockCalled -CommandName New-InvalidOperationException -Times 0
                }

            }

            Context 'server should not be configured.' {

                it 'calling Get should not throw' {
                    Mock -CommandName Get-WSUSServer -MockWith {} -Verifiable
                    {$Script:resource = Get-TargetResource -Name $script:WsusServer.Name -verbose} | should -not -throw
                }

                it "Ensure" {
                    $Script:resource.Ensure | should -Be 'Absent'
                }

                it "Classifications" {
                    $Script:resource.Classifications | should -BeNullOrEmpty
                }

                it "Products" {
                    $Script:resource.Products | should -BeNullOrEmpty
                }

                it "Computer Groups" {
                    $Script:resource.ComputerGroups | should -BeNullOrEmpty
                }

                it "Enabled" {
                    $Script:resource.Enabled | should -BeNullOrEmpty
                }

                it "mocks were called" {
                    Assert-VerifiableMock
                }

                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-InvalidResultException -Times 0
                    Assert-MockCalled -CommandName New-InvalidArgumentException -Times 0
                    Assert-MockCalled -CommandName New-InvalidOperationException -Times 0
                }
            }

            Context 'server is not configured.' {

                it 'calling Get should not throw' {
                    {$Script:resource = Get-TargetResource -Name 'Foo' -verbose} | should -not -throw
                }

                it "Ensure" {
                    $Script:resource.Ensure | should -Be 'Absent'
                }

                it "Classifications" {
                    $Script:resource.Classifications | should -Be $null
                }

                it "Products" {
                    $Script:resource.Products | should -Be $null
                }

                it "Computer Groups" {
                    $Script:resource.ComputerGroups | should -Be $null
                }

                it "Enabled" {
                    $Script:resource.Enabled | should -Be $null
                }

                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-InvalidResultException -Times 0
                    Assert-MockCalled -CommandName New-InvalidArgumentException -Times 0
                    Assert-MockCalled -CommandName New-InvalidOperationException -Times 0
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "MSFT_UpdateServicesApprovalRule\Test-TargetResource" {
            Context 'server is in correct state (Ensure=Present)' {
                BeforeAll {
                    $DSCTestValues.Remove('Ensure')
                    $DSCTestValues.Add('Ensure','Present')
                    $script:result = $null
                }

                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource @DSCTestValues -verbose} | should -not -throw
                }

                it "result should be true" {
                    $script:result | should -Be $true
                }
            }

            Context 'server should not be configured (Ensure=Absent) but is' {
                BeforeAll {
                    $DSCTestValues.Remove('Ensure')
                    $DSCTestValues.Add('Ensure','Absent')
                    $script:result = $null
                }

                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource @DSCTestValues -verbose} | should -not -throw
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

                $settingsList = 'Classifications','Products','ComputerGroups'
                Context 'When <_> property is drifted' -Foreach $settingsList {
                    BeforeAll {
                        #$valueWithoutDrift = $DSCTestValues.$_

                    }

                    it 'calling test should not throw' {
                        $DSCTestValuesDrifted = $DSCTestValues.Clone()
                        $DSCTestValuesDrifted["$_"] = 'foo'
                        $script:result = $null
                        {$script:result = Test-TargetResource @DSCTestValuesDrifted -verbose} | should -Not -Throw
                    }

                    it "result should be false when $setting has changed" {
                        $script:result | should -BeFalse
                    }

                    BeforeAll {
                        #$DSCTestValues.Remove("$_")
                        #$DSCTestValues.Add("$_",$valueWithoutDrift)
                    }
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "MSFT_UpdateServicesApprovalRule\Set-TargetResource" {
            BeforeAll {
                $Collection = [pscustomobject]@{}
                $Collection | Add-Member -MemberType ScriptMethod -Name Add -Value {}
            }

            Context 'server is already in a correct state (resource is idempotent)' {
                BeforeAll {
                    Mock New-Object -mockwith {$Collection}
                    Mock Get-WsusProduct -mockwith {}
                    Mock -CommandName New-InvalidOperationException -MockWith {}
                    Mock -CommandName New-InvalidResultException -MockWith {}
                    Mock -CommandName New-InvalidArgumentException -MockWith {}
                }

                it 'should not throw when running on a properly configured server' {
                    {Set-targetResource @DSCSetValues -verbose} | should -Not -Throw

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
                    Mock New-Object -mockwith {$Collection}
                    Mock Get-WsusProduct -mockwith {}
                    Mock -CommandName New-InvalidOperationException -MockWith {}
                    Mock -CommandName New-InvalidResultException -MockWith {}
                    Mock -CommandName New-InvalidArgumentException -MockWith {}
                    Mock Test-TargetResource -mockwith {$true}
                }

                it 'should not throw when running on an incorrectly configured server' {
                    {Set-targetResource -Name "Foo" -Classification "00000000-0000-0000-0000-0000testguid" -verbose} | should -Not -Throw

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
                    Mock New-Object -mockwith {$Collection}
                    Mock Get-WsusProduct -mockwith {}
                    Mock -CommandName New-InvalidOperationException -MockWith {}
                    Mock -CommandName New-InvalidResultException -MockWith {}
                    Mock -CommandName New-InvalidArgumentException -MockWith {}
                    Mock Test-TargetResource -mockwith {$true}
                }

                it 'should not throw when running on an incorrectly configured server' {
                    {Set-targetResource @DSCSetValues -Ensure Absent -verbose} | should -Not -Throw

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
                    Mock New-Object -mockwith {$Collection}
                    Mock Get-WsusProduct -mockwith {}
                    Mock -CommandName New-InvalidOperationException -MockWith {}
                    Mock -CommandName New-InvalidResultException -MockWith {}
                    Mock -CommandName New-InvalidArgumentException -MockWith {}
                    Mock Test-TargetResource -mockwith {$true}
                }

                it 'should not throw when running on a properly configured server' {
                    {Set-targetResource @DSCSetValues -Synchronize $true -verbose} | should -Not -Throw

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
        #endregion
    }
}

finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
