<#
.Synopsis
   Unit tests for UpdateServicesApprovalRuleDsc
.DESCRIPTION
   Unit tests for UpdateServicesApprovalRuleDsc

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>

$Global:DSCModuleName      = 'UpdateServicesDsc' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_UpdateServicesApprovalRule' # Example MSFT_xFirewall

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion


# Begin Testing
try
{

    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        Import-Module $PSScriptRoot\..\..\Tests\Helpers\ImitateUpdateServicesModule.psm1

        $global:WsusServer = [pscustomobject] @{
            Name = 'ServerName'
            }
        
        $DSCSetValues = @{
            Name = $Global:WsusServer.Name
            Classifications = "00000000-0000-0000-0000-0000testguid"
            Products = "Product"
            ComputerGroups = "Computer Target Group" 
            Enabled = $true
        }

        $DSCTestValues = @{
                Name = $Global:WsusServer.Name
                Classifications = "00000000-0000-0000-0000-0000testguid"
                Products = "Product"
                ComputerGroups = "Computer Target Group" 
                Enabled = $true
        }
        #endregion
        
        #region Function Get-TargetResource expecting Ensure Present
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Mock -CommandName New-TerminatingError -MockWith {}
            
            Context 'server should be configured.' {

                it 'calling Get should not throw' {
                    {$Script:resource = Get-TargetResource -Name $Global:WsusServer.Name -verbose} | should not throw
                }

                it "Ensure" {
                    $Script:resource.Ensure | should be 'Present'
                } 

                it "Classifications" {
                    $Script:resource.Classifications | should be $DSCSetValues.Classifications
                }

                it "Products" {
                    $Script:resource.Products | should be $DSCSetValues.Products
                }

                it "Computer Groups" {
                    $Script:resource.ComputerGroups | should be $DSCSetValues.ComputerGroups
                }

                it "Enabled" {
                    $Script:resource.Enabled | should be $DSCSetValues.Enabled
                }

                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }

            }

            Context 'server should not be configured.' {

                it 'calling Get should not throw' {
                    Mock -CommandName Get-WSUSServer -MockWith {} -Verifiable
                    {$Script:resource = Get-TargetResource -Name $Global:WsusServer.Name -verbose} | should not throw
                }

                it "Ensure" {
                    $Script:resource.Ensure | should be 'Absent'
                } 

                it "Classifications" {
                    $Script:resource.Classifications | should BeNullOrEmpty
                }

                it "Products" {
                    $Script:resource.Products | should BeNullOrEmpty
                }

                it "Computer Groups" {
                    $Script:resource.ComputerGroups | should BeNullOrEmpty
                }

                it "Enabled" {
                    $Script:resource.Enabled | should BeNullOrEmpty
                }

                it "mocks were called" {
                    Assert-VerifiableMocks
                }

                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }
            }

            Context 'server is not configured.' {

                it 'calling Get should not throw' {
                    {$Script:resource = Get-TargetResource -Name 'Foo' -verbose} | should not throw
                }

                it "Ensure" {
                    $Script:resource.Ensure | should be 'Absent'
                } 

                it "Classifications" {
                    $Script:resource.Classifications | should be $null
                }

                it "Products" {
                    $Script:resource.Products | should be $null
                }

                it "Computer Groups" {
                    $Script:resource.ComputerGroups | should be $null
                }

                it "Enabled" {
                    $Script:resource.Enabled | should be $null
                }

                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }
            }    
        }
        #endregion

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {

            Context 'server is in correct state (Ensure=Present)' {

                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Present')

                $script:result = $null
                    
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                }

                it "result should be true" {
                    $script:result | should be $true
                }
            }

            Context 'server should not be configured (Ensure=Absent) but is' {
                
                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Absent')

                $script:result = $null
                    
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                }

                it "result should be false" {
                    $script:result | should be $false
                }
            }

            Context "setting has drifted" {

                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Present')
                    
                $settingsList = 'Classifications','Products','ComputerGroups'
                foreach ($setting in $settingsList) { 
                
                    $valueWithoutDrift = $DSCSetValues.$setting

                    $DSCTestValues.Remove("$setting")
                    $DSCTestValues.Add("$setting",'foo')

                    $script:result = $null
                        
                    it 'calling test should not throw' {
                        {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                    }

                    it "result should be false when $setting has changed" {
                        $script:result | should be $false
                    }
                    
                    $DSCTestValues.Remove("$setting")
                    $DSCTestValues.Add("$setting",$valueWithoutDrift)
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            
            $Collection = [pscustomobject]@{}
            $Collection | Add-Member -MemberType ScriptMethod -Name Add -Value {}

            context 'server is already in a correct state (resource is idempotent)' {
                
                Mock New-Object -mockwith {$Collection}
                Mock Get-WsusProduct -mockwith {}
                Mock New-TerminatingError -mockwith {}
                
                it 'should not throw when running on a properly configured server' {
                    {Set-targetResource @DSCSetValues -verbose} | should not throw
                }

                it "mocks were called" {
                    Assert-MockCalled -CommandName New-Object -Times 1
                    Assert-MockCalled -CommandName Get-WsusProduct -Times 1
                }
                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }
            }

            context 'server is not in a correct state (resource takes action)' {
                
                Mock New-Object -mockwith {$Collection}
                Mock Get-WsusProduct -mockwith {}
                Mock New-TerminatingError -mockwith {}
                Mock Test-TargetResource -mockwith {$true}

                it 'should not throw when running on an incorrectly configured server' {
                    {Set-targetResource -Name "Foo" -Classification "00000000-0000-0000-0000-0000testguid" -verbose} | should not throw
                }

                it "mocks were called" {
                    Assert-MockCalled -CommandName New-Object -Times 1
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                    Assert-MockCalled -CommandName Get-WsusProduct -Times 1
                }
                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }
            }

            context 'server should not be configured (Ensure=Absent)' {
                
                Mock New-Object -mockwith {$Collection}
                Mock Get-WsusProduct -mockwith {}
                Mock New-TerminatingError -mockwith {}
                Mock Test-TargetResource -mockwith {$true}

                it 'should not throw when running on an incorrectly configured server' {
                    {Set-targetResource @DSCSetValues -Ensure Absent -verbose} | should not throw
                }

                it "mocks were called" {
                    
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                }
                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-Object -Times 0
                    Assert-MockCalled -CommandName Get-WsusProduct -Times 0
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }
            }

            context 'server is in correct state and synchronize is included' {
                
                Mock New-Object -mockwith {$Collection}
                Mock Get-WsusProduct -mockwith {}
                Mock New-TerminatingError -mockwith {}
                
                it 'should not throw when running on a properly configured server' {
                    {Set-targetResource @DSCSetValues -Synchronize $true -verbose} | should not throw
                }

                it "mocks were called" {
                    Assert-MockCalled -CommandName New-Object -Times 1
                    Assert-MockCalled -CommandName Get-WsusProduct -Times 1
                }
                it "mocks were not called" {
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
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
