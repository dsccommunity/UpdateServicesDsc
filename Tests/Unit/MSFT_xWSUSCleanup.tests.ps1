<#
.Synopsis
   Unit tests for xWSUSCleanup
.DESCRIPTION
   Unit tests for xWSUSCleanup

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>

$Global:DSCModuleName      = 'xWSUS' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xWSUSCleanup' # Example MSFT_xFirewall

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
            DeclineSupersededUpdates = $true
            DeclineExpiredUpdates = $true
            CleanupObsoleteUpdates = $true 
            CompressUpdates = $true
            CleanupObsoleteComputers = $true
            CleanupUnneededContentFiles = $true
            CleanupLocalPublishedContentFiles = $true
            TimeOfDay = "04:00:00"
        }
        #endregion
        
        #region Function Get-TargetResource expecting Ensure Present
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            $Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
            $Execute = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
            $StartBoundary = '20160101T04:00:00'
            
            Context 'server is configured.' {

                Mock Get-ScheduledTask -mockwith {
                    @{
                        State = 'Enabled'
                        Actions = @{
                            Execute = $Execute
                            Arguments = $Arguments
                            }
                        Triggers = @{
                            StartBoundary = $StartBoundary
                        }
                    }
                } -Verifiable

                $resource = Get-TargetResource -Ensure "Present" -verbose

                it 'Ensure' {
                    $resource.Ensure | should be 'Present'
                }

                it 'DeclineSupersededUpdates' {
                    $resource.DeclineSupersededUpdates | Should Be 'True'
                }

                it 'DeclineExpiredUpdates' {
                    $resource.DeclineExpiredUpdates | Should Be 'True'
                }

                it 'CleanupObsoleteUpdates' {
                    $resource.CleanupObsoleteUpdates | Should Be 'True'
                }

                it 'CompressUpdates' {
                    $resource.CompressUpdates | Should Be 'True'
                }

                it 'CleanupObsoleteComputers' {
                    $resource.CleanupObsoleteComputers | Should Be 'True'
                }

                it 'CleanupUnneededContentFiles' {
                    $resource.CleanupUnneededContentFiles | Should Be 'True'
                }

                it 'CleanupLocalPublishedContentFiles' {
                    $resource.CleanupLocalPublishedContentFiles | Should Be 'True'
                }

                it 'TimeOfDay' {
                    $resource.TimeOfDay | Should Be $StartBoundary.Split('T')[1]
                }
                
                it 'mocks were called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'server is not configured.' {

                Mock Get-ScheduledTask -mockwith {} -Verifiable

                $resource = Get-TargetResource -Ensure 'Absent' -verbose

                it 'Ensure' {
                    $resource.Ensure | should be 'Absent'
                }

                it 'mocks were called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'server is configured in an unexpected way.' {

                Mock Get-ScheduledTask -mockwith {
                    @{
                        State = 'Disabled'
                        Actions = @{
                            Execute = $Execute
                            Arguments = $Arguments
                            }
                    Triggers = @{
                            StartBoundary = $StartBoundary
                        }
                    }
                } -Verifiable

                $resource = Get-TargetResource -Ensure 'Present' -verbose

                it 'Ensure' {
                    $resource.Ensure | should be 'Absent'
                }

                it 'mocks were called' {
                    Assert-VerifiableMocks
                }
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            
            $DSCTestValues = $DSCPropertyValues

            Context 'server is in correct state (Ensure=Present)' {

                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Present')

                Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable

                $script:result = $null
                    
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                }

                it "result should be true" {
                    $script:result | should be $true
                }
                
                it 'mocks were called' {
                    Assert-VerifiableMocks
                }
            }
            
            Context 'server should not be configured (Ensure=Absent)' {
                
                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Absent')

                Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
                                    
                $script:result = $null
                    
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                }

                it "result should be true" {
                    $script:result | should be $true
                }

                it 'mocks were called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'server should be configured correctly but is not' {
                
                $DSCTestValues.Remove('Ensure')

                Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
                                    
                $script:result = $null
                    
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -verbose} | should not throw
                }

                it "result should be false" {
                    $script:result | should be $false
                }

                it 'mocks were called' {
                    Assert-VerifiableMocks
                }
            }

            Context "setting has drifted" {
                
                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Present')
                $DriftValue = $DSCTestValues

                $settingsList = 'DeclineSupersededUpdates','DeclineExpiredUpdates','CleanupObsoleteUpdates','CompressUpdates','CleanupObsoleteComputers','CleanupUnneededContentFiles','CleanupLocalPublishedContentFiles'
                foreach ($setting in $settingsList) {
                    
                    $DriftValue.Remove("$setting")
                    Mock -CommandName Get-TargetResource -MockWith {$DriftValue} -Verifiable
                                        
                    $script:result = $null
                        
                    it 'calling test should not throw' {
                        {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                    }

                    it "result should be false when $setting has changed" {
                        $script:result | should be $false
                    }

                    it 'mocks were called' {
                        Assert-VerifiableMocks
                    }

                    $DSCTestValues.Add("$setting",$true)
                }
            }
        }
        #endregion
<#
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
#>        
    }
}

finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

}
