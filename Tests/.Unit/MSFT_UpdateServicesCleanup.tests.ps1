<#
.Synopsis
   Unit tests for UpdateServicesCleanup
.DESCRIPTION
   Unit tests for UpdateServicesCleanup

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>

$Global:DSCModuleName      = 'UpdateServicesDsc' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_UpdateServicesCleanup' # Example MSFT_xFirewall

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
        #endregion
        
        #region Function Get-TargetResource expecting Ensure Present
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            $Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
            $Execute = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
            $StartBoundary = '20160101T04:00:00'
            
            Context 'server is configured.'
            {
                Mock -CommandName Get-ScheduledTask -mockwith
                {
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

                it 'calling Get should not throw'
                {
                    {$Script:resource = Get-TargetResource -Ensure "Present" -verbose} | should not throw
                }

                it 'Ensure'
                {
                        $Script:resource.Ensure | should be 'Present'
                }

                $settingsList = 'DeclineSupersededUpdates','DeclineExpiredUpdates','CleanupObsoleteUpdates','CompressUpdates','CleanupObsoleteComputers','CleanupUnneededContentFiles','CleanupLocalPublishedContentFiles'
                foreach ($setting in $settingsList)
                {
                    it "$setting should be true"
                    {
                        $Script:resource.$setting | Should Be 'True'
                    }
                }

                it 'TimeOfDay'
                {
                    $Script:resource.TimeOfDay | Should Be $StartBoundary.Split('T')[1]
                }
                
                it 'mocks were called'
                {
                    Assert-VerifiableMocks
                }
            }

            Context 'server is not configured.'
            {
                Mock Get-ScheduledTask -mockwith {} -Verifiable

                it 'calling Get should not throw'
                {
                    {$Script:resource = Get-TargetResource -Ensure 'Absent' -verbose} | should not throw
                }

                it 'Ensure'
                {
                    $Script:resource.Ensure | should be 'Absent'
                }

                it 'mocks were called'
                {
                    Assert-VerifiableMocks
                }
            }

            Context 'server is configured in an unexpected way.'
            {

                Mock Get-ScheduledTask -mockwith
                {
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
                } -Verifiable

                it 'calling Get should not throw'
                {
                    {$Script:resource = Get-TargetResource -Ensure 'Present' -verbose} | should not throw
                }

                it 'Ensure'
                {
                    $Script:resource.Ensure | should be 'Absent'
                }

                it 'mocks were called'
                {
                    Assert-VerifiableMocks
                }
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Context 'server is in correct state (Ensure=Present)'
            {
                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Present')
                Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
                $script:result = $null
                    
                it 'calling test should not throw'
                {
                    {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                }

                it "result should be true"
                {
                    $script:result | should be $true
                }
                
                it 'mocks were called'
                {
                    Assert-VerifiableMocks
                }
            }
            
            Context 'server should not be configured (Ensure=Absent)'
            {
                
                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Absent')
                Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
                $script:result = $null
                    
                it 'calling test should not throw'
                {
                    {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                }

                it "result should be true"
                {
                    $script:result | should be $true
                }

                it 'mocks were called'
                {
                    Assert-VerifiableMocks
                }
            }

            Context 'server should be configured correctly but is not'
            {
                
                $DSCTestValues.Remove('Ensure')
                Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
                $script:result = $null
                    
                it 'calling test should not throw'
                {
                    {$script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -verbose} | should not throw
                }

                it "result should be false"
                {
                    $script:result | should be $false
                }

                it 'mocks were called'
                {
                    Assert-VerifiableMocks
                }
            }

            Context "setting has drifted"
            {
                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Present')
                $settingsList = 'DeclineSupersededUpdates','DeclineExpiredUpdates','CleanupObsoleteUpdates','CompressUpdates','CleanupObsoleteComputers','CleanupUnneededContentFiles','CleanupLocalPublishedContentFiles'
                foreach ($setting in $settingsList)
                {    
                    Mock -CommandName Get-TargetResource -MockWith
                    {
                        $DSCTestValues.Remove("$setting")
                        $DSCTestValues
                    } -Verifiable
                                        
                    $script:result = $null
                        
                    it 'calling test should not throw'
                    {
                        {$script:result = Test-TargetResource @DSCTestValues -verbose} | should not throw
                    }

                    it "result should be false when $setting has changed"
                    {
                        $script:result | should be $false
                    }

                    it 'mocks were called'
                    {
                        Assert-VerifiableMocks
                    }

                    $DSCTestValues.Add("$setting",$true)
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {    
            $Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
            $Execute = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
            $StartBoundary = '20160101T04:00:00'
            Mock -CommandName Unregister-ScheduledTask -MockWith {}
            Mock -CommandName Register-ScheduledTask -MockWith {}
            Mock -CommandName Test-TargetResource -MockWith {$true}
            Mock -CommandName New-TerminatingError -MockWith {}

            Context 'resource is idempotent (Ensure=Present)'
            {
               Mock -CommandName Get-ScheduledTask -MockWith {$true}
                
               it 'should not throw when running on a properly configured server'
               {
                    {Set-targetResource @DSCSetValues -Ensure Present -verbose} | should not throw
                }

                it "mocks were called for commands that gather information"
                {
                    Assert-MockCalled -CommandName Get-ScheduledTask -Times 1
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 1
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                }

                it "mocks were called that register a task to run WSUS cleanup"
                {
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 1
                }

                it "mocks were not called that remove tasks or log errors"
                {
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }
            }

            Context 'resource processes Set tasks to register Cleanup task (Ensure=Present)'
            {
               Mock -CommandName Get-ScheduledTask -MockWith {}
                
               it 'should not throw when running on a properly configured server'
               {
                    {Set-targetResource @DSCSetValues -Ensure Present -verbose} | should not throw
                }

                it "mocks were called for commands that gather information"
                {
                    Assert-MockCalled -CommandName Get-ScheduledTask -Times 1
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 1
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                }

                it "mocks were called that register a task to run WSUS cleanup"
                {
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 1
                }

                it "mocks were not called that remove tasks or log errors"
                {
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 0
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }
            }

            Context 'resource processes Set tasks to remove Cleanup task (Ensure=Absent)'
            {
                Mock -CommandName Get-ScheduledTask -MockWith {$true}
                
               it 'should not throw when running on a properly configured server'
               {
                    {Set-targetResource @DSCSetValues -Ensure Absent -verbose} | should not throw
                }

                it "mocks were called for commands that gather information"
                {
                    Assert-MockCalled -CommandName Get-ScheduledTask -Times 1
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                }

                it "mocks were called to remove Cleanup task"
                {
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                }

                it "mocks were not called that register tasks or log errors"
                {
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 0
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
