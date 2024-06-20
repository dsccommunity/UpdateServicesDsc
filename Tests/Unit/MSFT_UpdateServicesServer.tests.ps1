$script:DSCModuleName = 'UpdateServicesDsc' # Example xNetworking
$script:DSCResourceName = 'MSFT_UpdateServicesServer' # Example MSFT_xFirewall

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

#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $script:DSCResourceName {
        BeforeAll {
            $DSCGetValues = @{
                SQLServer                         = 'SQLServer'
                ContentDir                        = 'C:\WSUSContent\'
                UpdateImprovementProgram          = $true
                UpstreamServerName                = ''
                UpstreamServerPort                = $null
                UpstreamServerSSL                 = $null
                UpstreamServerReplica             = $null
                ProxyServerName                   = ''
                ProxyServerPort                   = $null
                ProxyServerCredentialUsername     = $null
                ProxyServerBasicAuthentication    = $null
                Languages                         = '*'
                Products                          = '*'
                Classifications                   = '*'
                SynchronizeAutomatically          = $true
                SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                SynchronizationsPerDay            = 24
                ClientTargetingMode               = "Client"
            }

            $DSCTestValues = @{
                SetupCredential                   = New-Object -typename System.Management.Automation.PSCredential -argumentlist 'foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force)
                SQLServer                         = 'SQLServer'
                ContentDir                        = 'C:\WSUSContent\'
                UpdateImprovementProgram          = $true
                UpstreamServerName                = 'UpstreamServer'
                UpstreamServerPort                = $false
                UpstreamServerSSL                 = $false
                UpstreamServerReplica             = $false
                ProxyServerName                   = 'ProxyServer'
                ProxyServerPort                   = 8080
                Languages                         = "*"
                Products                          = @("Windows", "Office")
                Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                SynchronizeAutomatically          = $true
                SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                SynchronizationsPerDay            = 24
                ClientTargetingMode               = "Client"
            }
        }
        #endregion

        #region Function Get-TargetResource expecting Ensure Present
        Describe "MSFT_UpdateServicesServer\Get-TargetResource" {
            BeforeAll{
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'SQLServerName' } -MockWith { @{SQLServerName = 'SQLServer' } }
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'ContentDir' } -MockWith { @{ContentDir = 'C:\WSUSContent\' } }
            }

            Context 'server should be configured.' {

                It 'calling Get should not throw and mocks' {
                    { $Script:resource = Get-TargetResource -Ensure 'Present' -verbose } | Should -Not -Throw

                    Should -Invoke Get-ItemProperty -Exactly 2
                }

                It 'sets the value for Ensure' {
                    $Script:resource.Ensure | Should -Be 'Present'
                }

                It "returns good values in Get results"  {
                    foreach ($setting in $DSCSetValues.Keys)
                    {
                        $Script:resource.$setting | Should -Be $DSCGetValues.$setting
                    }
                }
            }

            Context 'server should not configured.' {

                It 'calling Get should not throw and mocks' {
                    Mock -CommandName Get-WSUSServer -MockWith { }
                    { $Script:resource = Get-TargetResource -Ensure 'Absent' -verbose } | Should -Not -Throw

                    Should -Invoke Get-WsusServer -Exactly 1
                }

                It 'sets the value for Ensure' {
                    $Script:resource.Ensure | Should -Be 'Absent'
                }
            }

            Context 'Products property contains wildcard' {
                BeforeAll {
                    Mock -CommandName Get-WsusServer -Verifiable -MockWith {
                        #Function presents in Tests\Helpers\ImitateUpdateServicesModule.psm1
                        return $(Get-WsusServerMockWildCardPrdt)
                    }

                    $script:result = $null
                }

                It 'calling test should not throw and mocks' {
                    { $script:result = Get-TargetResource -Ensure 'Present' -verbose } | Should -Not -Throw

                    Should -Invoke Get-WsusServer -Exactly 1
                }

                It "Products should contain right value" {
                    $DesiredProducts = @('Windows Server 2003','Windows Server 2008','Windows Server 2008R2','Windows Server 2012','Windows Server 2016','Windows Server 2019')

                    ($script:result.Products | Measure-Object).Count | Should -Be $DesiredProducts.Count

                    $DesiredProducts | ForEach-Object {
                        $script:result.Products | Should -Contain $_
                    }
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "MSFT_UpdateServicesServer\Test-TargetResource" {

            Context 'server is in correct state (Ensure=Present)' {
                BeforeAll {
                    $DSCTestValues.Remove('Ensure')
                    $DSCTestValues.Add('Ensure', 'Present')

                    Mock -CommandName Get-TargetResource -MockWith { $DSCTestValues } -Verifiable
                    $script:result = $null
                }

                It 'calling test should not throw' {
                    { $script:result = Test-TargetResource @DSCTestValues -verbose } | Should -Not -Throw

                    Should -Invoke Get-TargetResource -Exactly 1
                }

                It "result should be true" {
                    $script:result | Should -BeTrue
                }

                It 'mocks were called' {
                    Assert-VerifiableMock
                }
            }

            Context 'server should not be configured (Ensure=Absent)' {
                BeforeAll {
                    $DSCTestValues.Remove('Ensure')
                    $DSCTestValues.Add('Ensure', 'Absent')

                    Mock -CommandName Get-TargetResource -MockWith { $DSCTestValues } -Verifiable
                    $script:result = $null
                }

                It 'calling test should not throw' {
                    { $script:result = Test-TargetResource @DSCTestValues -verbose } | Should -Not -Throw

                    Should -Invoke Get-TargetResource -Exactly 1
                }

                It "result should be true" {
                    $script:result | Should -Be true
                }
            }

            Context 'server should be configured correctly but is not' {
                BeforeAll {
                    $DSCTestValues.Remove('Ensure')
                    Mock -CommandName Get-TargetResource -MockWith { $DSCTestValues } -Verifiable

                    $script:result = $null
                }

                It 'calling test should not throw' {
                    { $script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -verbose } | Should -Not -Throw

                    Should -Invoke Get-TargetResource -Exactly 1
                }

                It "result should be false" {
                    $script:result | Should -BeFalse
                }
            }

            Context "setting has drifted" {
                BeforeAll {
                    $DSCTestValues.Remove('Ensure')
                    $DSCTestValues.Add('Ensure', 'Present')
                }

                # Settings not currently tested: ProxyServerUserName, ProxyServerCredential, ProxyServerBasicAuthentication, 'Languages', 'Products', 'Classifications', 'SynchronizeAutomatically'
                $settingsList = @(
                    'UpdateImprovementProgram'
                    'UpstreamServerName'
                    'UpstreamServerPort'
                    'UpstreamServerSSL'
                    'UpstreamServerReplica'
                    'ProxyServerName'
                    'ProxyServerPort'
                    'SynchronizeAutomaticallyTimeOfDay'
                    'SynchronizationsPerDay'
                )

                Context "When <_> property is invalid" -Foreach $settingsList {
                    BeforeAll {
                        $setting = $_
                        Mock -CommandName Get-TargetResource -MockWith {
                            $DSCTestValues.Remove("$setting")
                            $DSCTestValues
                        }
                    }

                    $script:result = $null

                    It "calling test with change to <_> should not throw" {
                        { $script:result = Test-TargetResource @DSCTestValues -verbose } | Should -Not -Throw

                        Should -Invoke Get-TargetResource -Exactly 1
                    }

                    It "result should be false when <_> has changed" {
                        $script:result | Should -Be $false
                    }

                    AfterAll {
                        $DSCTestValues.Add("$_", $true)
                    }
                }
            }

            Context 'Products property contains wildcard' {
                BeforeAll {
                    Mock -CommandName Get-WsusServer -Verifiable -MockWith {
                        return $(Get-WsusServerMockWildCardPrdt)
                    }

                    $DSCGetValues = @{
                        Ensure                            = 'Present'
                        SetupCredential                   = New-Object -typename System.Management.Automation.PSCredential -argumentlist 'foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force)
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = "*"
                        Products                          = @('Windows Server 2003','Windows Server 2008','Windows Server 2008R2','Windows Server 2012','Windows Server 2016','Windows Server 2019')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = "Client"
                    }

                    $DSCTestValues = @{
                        SetupCredential                   = New-Object -typename System.Management.Automation.PSCredential -argumentlist 'foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force)
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = "*"
                        Products                          = 'Windows Server*'
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = "Client"
                    }

                    $DSCTestValues.Remove('Ensure')

                    Mock -CommandName Get-TargetResource -MockWith { $DSCGetValues } -Verifiable

                    $script:result = $null
                }

                It 'calling test should not throw' {
                    { $script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -verbose } | Should -Not -Throw
                }

                It "result should be true" {
                    $script:result | Should -Be  $true
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "MSFT_UpdateServicesServer\Set-TargetResource" {
            BeforeAll {
                $DSCTestValues.Remove('Ensure')

                Mock -CommandName Test-TargetResource -MockWith { $true }
                Mock -CommandName New-InvalidOperationException -MockWith { }
                Mock -CommandName New-InvalidResultException -MockWith { }
                Mock SaveWsusConfiguration -MockWith { }
            }
            Context 'resource is idempotent (Ensure=Present)' {

                It 'should not throw when running on a properly configured server' {
                    { Set-targetResource @DSCTestValues -Ensure Present -verbose } | Should -Not -Throw

                    Should -Invoke Test-TargetResource -Exactly 1
                    Should -Invoke SaveWsusConfiguration -Exactly 2
                    Should -Invoke New-InvalidResultException -Exactly 0
                    Should -Invoke New-InvalidOperationException -Exactly 0
                }
            }

            Context 'resource supports Ensure=Absent' {

                It 'should not throw when running on a properly configured server' {
                    { Set-targetResource @DSCTestValues -Ensure Absent -verbose } | Should -Not -Throw

                    Should -Invoke Test-TargetResource -Exactly 1
                    Should -Invoke SaveWsusConfiguration -Exactly 2

                    Should -Invoke New-InvalidResultException -Exactly 0
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
