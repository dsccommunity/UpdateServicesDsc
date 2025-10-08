
# $script:DSCModuleName      = 'UpdateServicesDsc' # Example xNetworking
# $script:DSCResourceName    = 'MSFT_UpdateServicesCleanup' # Example MSFT_xFirewall

# #region HEADER
# $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Import-Module -Name DscResource.Test -Force -ErrorAction Stop

# $TestEnvironment = Initialize-TestEnvironment `
#     -DSCModuleName $script:dscModuleName `
#     -DSCResourceName $script:dscResourceName `
#     -ResourceType 'Mof' `
#     -TestType Unit

# #endregion HEADER

# # Begin Testing
# try
# {
#     #region Pester Tests

#     # The InModuleScope command allows you to perform white-box unit testing on the internal
#     # (non-exported) code of a Script Module.
#     InModuleScope $script:DSCResourceName {
#         BeforeAll {
#             $DSCSetValues =
#             @{
#                 DeclineSupersededUpdates = $true
#                 DeclineExpiredUpdates = $true
#                 CleanupObsoleteUpdates = $true
#                 CompressUpdates = $true
#                 CleanupObsoleteComputers = $true
#                 CleanupUnneededContentFiles = $true
#                 CleanupLocalPublishedContentFiles = $true
#                 TimeOfDay = "04:00:00"
#             }

#             $DSCTestValues =
#             @{
#                 DeclineSupersededUpdates = $true
#                 DeclineExpiredUpdates = $true
#                 CleanupObsoleteUpdates = $true
#                 CompressUpdates = $true
#                 CleanupObsoleteComputers = $true
#                 CleanupUnneededContentFiles = $true
#                 CleanupLocalPublishedContentFiles = $true
#                 TimeOfDay = "04:00:00"
#             }
#         }
#         #endregion

#         #region Function Get-TargetResource expecting Ensure Present
#         Describe "MSFT_UpdateServicesCleanup\Get-TargetResource" {
#             BeforeAll {
#                 $Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
#                 $Execute = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
#                 $StartBoundary = '20160101T04:00:00'
#             }

#             Context 'server is configured.' {
#                 BeforeAll {
#                     Mock -CommandName Get-ScheduledTask -mockwith {
#                         @{
#                             State = 'Enabled'
#                             Actions =
#                             @{
#                                 Execute = $Execute
#                                 Arguments = $Arguments
#                             }
#                             Triggers =
#                             @{
#                                 StartBoundary = $StartBoundary
#                             }
#                         }
#                     } -Verifiable
#                 }

#                 it 'calling Get should not throw' {
#                     {$Script:resource = Get-TargetResource -Ensure "Present" -verbose} | Should -Not -Throw

#                     Should -Invoke Get-ScheduledTask -Exactly 1
#                 }

#                 it 'Ensure' {
#                         $Script:resource.Ensure | should -Be 'Present'
#                 }

#                 $settingsList = @(
#                     'DeclineSupersededUpdates'
#                     'DeclineExpiredUpdates'
#                     'CleanupObsoleteUpdates'
#                     'CompressUpdates'
#                     'CleanupObsoleteComputers'
#                     'CleanupUnneededContentFiles'
#                     'CleanupLocalPublishedContentFiles'
#                 )

#                 Context 'When <_> property is valid' -Foreach $settingsList {
#                     it '<_> should be true' {
#                         $Script:resource.$_ | Should -BeTrue
#                     }
#                 }

#                 it 'TimeOfDay' {
#                     $Script:resource.TimeOfDay | Should -Be $StartBoundary.Split('T')[1]
#                 }
#             }

#             Context 'server is not configured.' {
#                 BeforeAll {
#                     Mock Get-ScheduledTask -mockwith {} -Verifiable
#                 }

#                 it 'calling Get should not throw' {
#                     {$Script:resource = Get-TargetResource -Ensure 'Absent' -verbose} | should -Not -Throw

#                     Should -Invoke Get-ScheduledTask -Exactly 1
#                 }

#                 it 'Ensure' {
#                     $Script:resource.Ensure | should -Be 'Absent'
#                 }
#             }

#             Context 'server is configured in an unexpected way.' {
#                 BeforeAll {
#                     Mock Get-ScheduledTask -mockwith {
#                         @{
#                             State = 'Disabled'
#                             Actions =
#                             @{
#                                 Execute = $Execute
#                                 Arguments = $Arguments
#                             }
#                             Triggers =
#                             @{
#                                 StartBoundary = $StartBoundary
#                             }
#                         }
#                     }
#                 }

#                 it 'calling Get should not throw' {
#                     {$Script:resource = Get-TargetResource -Ensure 'Present' -verbose} | should -Not -Throw

#                     Should -Invoke Get-ScheduledTask -Exactly 1
#                 }

#                 it 'Ensure' {
#                     $Script:resource.Ensure | should -Be 'Absent'
#                 }
#             }
#         }
#         #endregion


#         #region Function Test-TargetResource
#         Describe "MSFT_UpdateServicesCleanup\Test-TargetResource" {
#             Context 'server is in correct state (Ensure=Present)' {
#                 BeforeAll {
#                     $DSCTestValues.Remove('Ensure')
#                     $DSCTestValues.Add('Ensure','Present')
#                     Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
#                     $script:result = $null
#                 }

#                 it 'calling test should not throw' {
#                     {$script:result = Test-TargetResource @DSCTestValues -verbose} | should -Not -Throw

#                     Should -Invoke Get-TargetResource -Exactly 1
#                 }

#                 it "result should be true" {
#                     $script:result | should -BeTrue
#                 }
#             }

#             Context 'server should not be configured (Ensure=Absent)' {
#                 BeforeAll {
#                     $DSCTestValues.Remove('Ensure')
#                     $DSCTestValues.Add('Ensure','Absent')
#                     Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
#                     $script:result = $null
#                 }

#                 it 'calling test should not throw' {
#                     {$script:result = Test-TargetResource @DSCTestValues -verbose} | should -Not -Throw

#                     Should -Invoke Get-TargetResource -Exactly 1
#                 }

#                 it "result should be true" {
#                     $script:result | should -BeTrue
#                 }
#             }

#             Context 'server should be configured correctly but is not' {
#                 BeforeAll {
#                     $DSCTestValues.Remove('Ensure')
#                     Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable
#                     $script:result = $null
#                 }

#                 it 'calling test should not throw' {
#                     {$script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -verbose} | should -Not -Throw

#                     Should -Invoke Get-TargetResource -Exactly 1
#                 }

#                 it "result should be false" {
#                     $script:result | should -BeFalse
#                 }
#             }

#             Context "setting has drifted" {
#                 BeforeAll {
#                     $DSCTestValues.Remove('Ensure')
#                     $DSCTestValues.Add('Ensure','Present')
#                 }

#                 $settingsList = @(
#                     'DeclineSupersededUpdates'
#                     'DeclineExpiredUpdates'
#                     'CleanupObsoleteUpdates'
#                     'CompressUpdates'
#                     'CleanupObsoleteComputers'
#                     'CleanupUnneededContentFiles'
#                     'CleanupLocalPublishedContentFiles'
#                 )

#                 Context 'When <_> property is invalid' -Foreach $settingsList {
#                     BeforeAll {
#                         $setting = $_
#                         Mock -CommandName Get-TargetResource -MockWith {
#                             $DSCTestValuesClone = $DSCTestValues.Clone()
#                             $DSCTestValuesClone.Remove("$setting")
#                             $DSCTestValuesClone
#                         }

#                         $script:result = $null
#                     }

#                     it 'calling test should not throw' {
#                         {$script:result = Test-TargetResource @DSCTestValues -verbose} | should -Not -Throw

#                         Should -Invoke Get-TargetResource -Exactly 1
#                     }

#                     it "result should be false when <_> has changed" {
#                         $script:result | should -BeFalse
#                     }

#                     AfterAll {
#                         #$DSCTestValues.Add("$setting",$true)
#                     }
#                 }
#             }
#         }
#         #endregion

#         #region Function Set-TargetResource
#         Describe "MSFT_UpdateServicesCleanup\Set-TargetResource" {
#             BeforeAll {
#                 $Arguments = 'foo"$DeclineSupersededUpdates = $True;$DeclineExpiredUpdates = $True;$CleanupObsoleteUpdates = $True;$CompressUpdates = $True;$CleanupObsoleteComputers = $True;$CleanupUnneededContentFiles = $True;$CleanupLocalPublishedContentFiles = $True'
#                 $Execute = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
#                 $StartBoundary = '20160101T04:00:00'
#                 Mock -CommandName Unregister-ScheduledTask -MockWith {}
#                 Mock -CommandName Register-ScheduledTask -MockWith {}
#                 Mock -CommandName Test-TargetResource -MockWith {$true}
#                 Mock -CommandName New-InvalidResultException -MockWith {}
#             }

#             Context 'resource is idempotent (Ensure=Present)' {
#                 BeforeAll {
#                     Mock -CommandName Get-ScheduledTask -MockWith {$true}
#                 }

#                it 'should not throw when running on a properly configured server' {
#                     {Set-targetResource @DSCSetValues -Ensure Present -verbose} | should -Not -Throw

#                     #mocks were called for commands that gather information
#                     Should -Invoke Get-ScheduledTask -Exactly 1
#                     Should -Invoke Unregister-ScheduledTask -Exactly 1
#                     Should -Invoke Register-ScheduledTask -Exactly 1
#                     Should -Invoke Test-TargetResource -Exactly 1

#                     #mocks were called that register a task to run WSUS cleanup
#                     Should -Invoke Register-ScheduledTask -Exactly 1

#                     #mocks were not called that remove tasks or log errors
#                     Should -Invoke New-InvalidResultException -Exactly 0
#                 }
#             }

#             Context 'resource processes Set tasks to register Cleanup task (Ensure=Present)' {
#                 BeforeAll {
#                     Mock -CommandName Get-ScheduledTask -MockWith {}
#                 }

#                it 'should not throw when running on a properly configured server' {
#                     {Set-targetResource @DSCSetValues -Ensure Present -verbose} | should -Not -Throw

#                     #mocks were called for commands that gather information
#                     Should -Invoke Get-ScheduledTask -Exactly 1
#                     Should -Invoke Register-ScheduledTask -Exactly 1
#                     Should -Invoke Test-TargetResource -Exactly 1

#                     #mocks were called that register a task to run WSUS cleanup
#                     Should -Invoke Register-ScheduledTask -Exactly 1

#                     #mocks were not called that remove tasks or log errors
#                     Should -Invoke Unregister-ScheduledTask -Exactly 0
#                     Should -Invoke New-InvalidResultException -Exactly 0
#                 }
#             }

#             Context 'resource processes Set tasks to remove Cleanup task (Ensure=Absent)' {
#                 BeforeAll {
#                     Mock -CommandName Get-ScheduledTask -MockWith {$true}
#                 }

#                it 'should not throw when running on a properly configured server' {
#                     {Set-targetResource @DSCSetValues -Ensure Absent -verbose} | should -Not -Throw

#                     #mocks were called for commands that gather information
#                     Should -Invoke Get-ScheduledTask -Exactly 1
#                     Should -Invoke Test-TargetResource -Exactly 1

#                     #mocks were called that register a task to run WSUS cleanup
#                     Should -Invoke Unregister-ScheduledTask -Exactly 1

#                     #mocks were not called that remove tasks or log errors
#                     Should -Invoke Register-ScheduledTask -Exactly 0
#                     Should -Invoke New-InvalidResultException -Exactly 0
#                 }
#             }
#         }
#         #endregion
#     }
# }

# finally
# {
#     #region FOOTER
#     Restore-TestEnvironment -TestEnvironment $TestEnvironment
#     #endregion

# }
