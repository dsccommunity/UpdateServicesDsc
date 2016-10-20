<#
.Synopsis
   Unit tests for WSUSServer
.DESCRIPTION
   Unit tests for WSUSServer

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',Scope='Function',Target='DSCGetValues')]
param()

$Global:DSCModuleName      = 'WSUSDsc' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_WSUSServer' # Example MSFT_xFirewall

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
        Import-Module $PSScriptRoot\..\..\Tests\Helpers\ImitateWSUSModule.psm1 -force

        $DSCGetValues = @{
            SetupCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist 'foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force)
            SQLServer = 'SQLServer'
            ContentDir = 'C:\WSUSContent\'
            UpdateImprovementProgram = $true
            UpstreamServerName = ''
            UpstreamServerPort = $null
            UpstreamServerSSL = $null
            UpstreamServerReplica = $null
            ProxyServerName = ''
            ProxyServerPort = $null
            ProxyServerCredentialUsername = $null
            ProxyServerBasicAuthentication = $null
            Languages = '*'
            Products = '*'
            Classifications = '*'
            SynchronizeAutomatically = $true
            SynchronizeAutomaticallyTimeOfDay = '04:00:00'
            SynchronizationsPerDay = 24
        }

        $DSCTestValues = @{
            SetupCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist 'foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force)
            SQLServer = 'SQLServer'
            ContentDir = 'C:\WSUSContent\'
            UpdateImprovementProgram = $true
            UpstreamServerName = 'UpstreamServer'
            UpstreamServerPort = $false
            UpstreamServerSSL = $false
            UpstreamServerReplica = $false
            ProxyServerName = 'ProxyServer'
            ProxyServerPort = 8080
            Languages = "*"
            Products = @("Windows","Office")
            Classifications = @('E6CF1350-C01B-414D-A61F-263D14D133B4','E0789628-CE08-4437-BE74-2495B842F43B','0FA1201D-4330-4FA8-8AE9-B877473B6441')
            SynchronizeAutomatically = $true
            SynchronizeAutomaticallyTimeOfDay = '04:00:00'
            SynchronizationsPerDay = 24
        }
        #endregion
        
        #region Function Get-TargetResource expecting Ensure Present
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Mock -CommandName Get-ItemProperty -ParameterFilter {$Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'SQLServerName'} -MockWith {@{SQLServerName = 'SQLServer'}} -Verifiable
            Mock -CommandName Get-ItemProperty -ParameterFilter {$Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'ContentDir'} -MockWith {@{ContentDir = 'C:\WSUSContent\'}} -Verifiable

            Context 'server should be configured.' {

                it 'calling Get should not throw' {
                    {$Script:resource = Get-TargetResource -SetupCredential $DSCGetValues.SetupCredential -Ensure 'Present' -verbose} | should not throw
                }
                
                it 'sets the value for Ensure' {
                    $Script:resource.Ensure | should be 'Present'
                }
                
                foreach ($setting in $DSCSetValues.Keys) {
                    it "returns $setting in Get results" {
                        $Script:resource.$setting | should be $DSCGetReturnValues.$setting
                    }
                }

                it 'mocks were called' {
                    Assert-VerifiableMocks
                }
            }

          Context 'server should not be configured.' {

                it 'calling Get should not throw' {
                    Mock -CommandName Get-WSUSServer -MockWith {}
                    {$Script:resource = Get-TargetResource -SetupCredential $DSCGetValues.SetupCredential -Ensure 'Absent' -verbose} | should not throw
                }
                
                it 'sets the value for Ensure' {
                    $Script:resource.Ensure | should be 'Absent'
                }

                it 'mocks were called' {
                    Assert-VerifiableMocks
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {

            Context 'server is in correct state (Ensure=Present)' {

                Mock -CommandName Get-TargetResource -MockWith {$DSCTestValues} -Verifiable

                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure','Present')

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

                # Settings not currently tested: ProxyServerUserName, ProxyServerCredential, ProxyServerBasicAuthentication, 'Languages', 'Products', 'Classifications', 'SynchronizeAutomatically'
                $settingsList = 'UpdateImprovementProgram', 'UpstreamServerName', 'UpstreamServerPort', 'UpstreamServerSSL', 'UpstreamServerReplica', 'ProxyServerName', 'ProxyServerPort', 'SynchronizeAutomaticallyTimeOfDay', 'SynchronizationsPerDay'
                foreach ($setting in $settingsList) {
                    
                    Mock -CommandName Get-TargetResource -MockWith {
                        $DSCTestValues.Remove("$setting")
                        $DSCTestValues
                    } -Verifiable
                                        
                    $script:result = $null
                        
                    it "calling test with change to $setting should not throw" {
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

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            
            $DSCTestValues.Remove('Ensure')
            
            Mock -CommandName Test-TargetResource -MockWith {$true}
            Mock -CommandName New-TerminatingError -MockWith {}
            Mock SaveWsusConfiguration -MockWith {}

            Context 'resource is idempotent (Ensure=Present)' {

                it 'should not throw when running on a properly configured server' {
                    {Set-targetResource @DSCTestValues -Ensure Present -verbose} | should not throw
                }

                it "mocks were called" {
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                    Assert-MockCalled -CommandName SaveWsusConfiguration -Times 1
                }

                it "mocks were not called that log errors" {
                    Assert-MockCalled -CommandName New-TerminatingError -Times 0
                }
            }
            
            Context 'resource supports Ensure=Absent' {

                it 'should not throw when running on a properly configured server' {
                    {Set-targetResource @DSCTestValues -Ensure Absent -verbose} | should not throw
                }

                it "mocks were called" {
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                    Assert-MockCalled -CommandName SaveWsusConfiguration -Times 1
                }

                it "mocks were not called that log errors" {
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
