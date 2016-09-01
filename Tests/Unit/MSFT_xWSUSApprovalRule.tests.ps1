<#
.Synopsis
   Unit tests for xWSUSApprovalRule
.DESCRIPTION
   Unit tests for xWSUSApprovalRule

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>

$Global:DSCModuleName      = 'xWSUS' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xWSUSApprovalRule' # Example MSFT_xFirewall

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
        Import-Module .\Tests\Helpers\ImitateWSUSModule.psm1

        $global:WsusServer = [pscustomobject] @{
            Name = 'ServerName'
            }
        
        $DSCPropertyValues = @{
            Name = $Global:WsusServer.Name
            Classifications = "00000000-0000-0000-0000-0000testguid"
            Products = "Product"
            ComputerGroups = "Computer Target Group" 
            Enabled = $true
        }
        #endregion
        
        #region Function Get-TargetResource expecting Ensure Present
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            
            Context 'server is configured.' {
                $resource = Get-TargetResource -Name $Global:WsusServer.Name -verbose

                it "Ensure" {
                    $resource.Ensure | should be 'Present'
                } 

                it "Classifications" {
                    $resource.Classifications | should be $DSCPropertyValues.Classifications
                }

                it "Products" {
                    $resource.Products | should be $DSCPropertyValues.Products
                }

                it "Computer Groups" {
                    $resource.ComputerGroups | should be $DSCPropertyValues.ComputerGroups
                }

                it "Enabled" {
                    $resource.Enabled | should be $DSCPropertyValues.Enabled
                }
            }

            Context 'server is not configured.' {
                $resource = Get-TargetResource -Name 'Foo' -verbose

                it "Ensure" {
                    $resource.Ensure | should be 'Absent'
                } 

                it "Classifications" {
                    $resource.Classifications | should be $null
                }

                it "Products" {
                    $resource.Products | should be $null
                }

                it "Computer Groups" {
                    $resource.ComputerGroups | should be $null
                }

                it "Enabled" {
                    $resource.Enabled | should be $null
                }
            }    
        }
        #endregion

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {

            Context 'server is in correct state (Ensure=Present)' {
                $script:result = $null
                    
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource @DSCPropertyValues -verbose} | should not throw
                }

                it "result should be true" {
                    $script:result | should be $true
                }
            }

            Context 'server should not be configured (Ensure=Absent)' {
                $script:result = $null
                    
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource -Name $Global:WsusServer.Name -Ensure Absent -verbose} | should not throw
                }

                it "result should be false" {
                    $script:result | should be $false
                }
            }

            Context 'server is not in correct state' {
                $script:result = $null
                    
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource -Name 'Foo' -verbose} | should not throw
                }

                it "result should be false" {
                    $script:result | should be $false
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
                    {Set-targetResource @DSCPropertyValues -verbose} | should not throw
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
                    {Set-targetResource @DSCPropertyValues -Ensure Absent -verbose} | should not throw
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
                    {Set-targetResource @DSCPropertyValues -Synchronize $true -verbose} | should not throw
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
