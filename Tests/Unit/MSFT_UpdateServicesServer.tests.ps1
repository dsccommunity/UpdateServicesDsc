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

#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $script:DSCResourceName {

        #region Pester Test Initialization
        Import-Module $PSScriptRoot\..\Helpers\ImitateUpdateServicesModule.psm1 -force

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
        #endregion

        #region Function Get-TargetResource expecting Ensure Present
        Describe "MSFT_UpdateServicesServer\Get-TargetResource" {

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'SQLServerName' } -MockWith { @{SQLServerName = 'SQLServer' } } -Verifiable
            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'ContentDir' } -MockWith { @{ContentDir = 'C:\WSUSContent\' } } -Verifiable

            Context 'server should be configured.' {

                It 'calling Get should not throw' {
                    { $Script:resource = Get-TargetResource -Ensure 'Present' -verbose } | Should not throw
                }

                It 'sets the value for Ensure' {
                    $Script:resource.Ensure | Should be 'Present'
                }

                foreach ($setting in $DSCSetValues.Keys)
                {
                    It "returns $setting in Get results" {
                        $Script:resource.$setting | Should be $DSCGetReturnValues.$setting
                    }
                }

                It 'mocks were called' {
                    Assert-VerifiableMock
                }
            }

            Context 'server should not be configured.' {

                It 'calling Get should not throw' {
                    Mock -CommandName Get-WSUSServer -MockWith { }
                    { $Script:resource = Get-TargetResource -Ensure 'Absent' -verbose } | Should not throw
                }

                It 'sets the value for Ensure' {
                    $Script:resource.Ensure | Should be 'Absent'
                }

                It 'mocks were called' {
                    Assert-VerifiableMock
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

                It 'calling test should not throw' {
                    { $script:result = Get-TargetResource -Ensure 'Present' -verbose } | Should not throw
                }

                It "Products should contain right value" {
                    $DesiredProducts = @('Windows Server 2003','Windows Server 2008','Windows Server 2008R2','Windows Server 2012','Windows Server 2016','Windows Server 2019')

                    ($script:result.Products |Measure-Object).Count | Should -Be $DesiredProducts.Count

                    $DesiredProducts | ForEach-Object {
                        $script:result.Products | Should -Contain $_
                    }
                }

                It 'mocks were called' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "MSFT_UpdateServicesServer\Test-TargetResource" {

            Context 'server is in correct state (Ensure=Present)' {

                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure', 'Present')

                Mock -CommandName Get-TargetResource -MockWith { $DSCTestValues } -Verifiable

                $script:result = $null

                It 'calling test should not throw' {
                    { $script:result = Test-TargetResource @DSCTestValues -verbose } | Should not throw
                }

                It "result should be true" {
                    $script:result | Should be $true
                }

                It 'mocks were called' {
                    Assert-VerifiableMock
                }
            }

            Context 'server should not be configured (Ensure=Absent)' {

                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure', 'Absent')

                Mock -CommandName Get-TargetResource -MockWith { $DSCTestValues } -Verifiable

                $script:result = $null

                It 'calling test should not throw' {
                    { $script:result = Test-TargetResource @DSCTestValues -verbose } | Should not throw
                }

                It "result should be true" {
                    $script:result | Should be $true
                }

                It 'mocks were called' {
                    Assert-VerifiableMock
                }
            }

            Context 'server should be configured correctly but is not' {

                $DSCTestValues.Remove('Ensure')

                Mock -CommandName Get-TargetResource -MockWith { $DSCTestValues } -Verifiable

                $script:result = $null

                It 'calling test should not throw' {
                    { $script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -verbose } | Should not throw
                }

                It "result should be false" {
                    $script:result | Should be $false
                }

                It 'mocks were called' {
                    Assert-VerifiableMock
                }
            }

            Context "setting has drifted" {

                $DSCTestValues.Remove('Ensure')
                $DSCTestValues.Add('Ensure', 'Present')

                # Settings not currently tested: ProxyServerUserName, ProxyServerCredential, ProxyServerBasicAuthentication, 'Languages', 'Products', 'Classifications', 'SynchronizeAutomatically'
                $settingsList = 'UpdateImprovementProgram', 'UpstreamServerName', 'UpstreamServerPort', 'UpstreamServerSSL', 'UpstreamServerReplica', 'ProxyServerName', 'ProxyServerPort', 'SynchronizeAutomaticallyTimeOfDay', 'SynchronizationsPerDay'
                foreach ($setting in $settingsList)
                {
                    Mock -CommandName Get-TargetResource -MockWith {
                        $DSCTestValues.Remove("$setting")
                        $DSCTestValues
                    } -Verifiable

                    $script:result = $null

                    It "calling test with change to $setting should not throw" {
                        { $script:result = Test-TargetResource @DSCTestValues -verbose } | Should not throw
                    }

                    It "result should be false when $setting has changed" {
                        $script:result | Should be $false
                    }

                    It 'mocks were called' {
                        Assert-VerifiableMock
                    }

                    $DSCTestValues.Add("$setting", $true)
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
                    { $script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -verbose } | Should not throw
                }

                It "result should be true" {
                    $script:result | Should be $true
                }

                It 'mocks were called' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "MSFT_UpdateServicesServer\Set-TargetResource" {

            $DSCTestValues.Remove('Ensure')

            Mock -CommandName Test-TargetResource -MockWith { $true }
            Mock -CommandName New-InvalidOperationException -MockWith { }
            Mock -CommandName New-InvalidResultException -MockWith { }
            Mock SaveWsusConfiguration -MockWith { }

            Context 'resource is idempotent (Ensure=Present)' {

                It 'should not throw when running on a properly configured server' {
                    { Set-targetResource @DSCTestValues -Ensure Present -verbose } | Should not throw
                }

                It "mocks were called" {
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                    Assert-MockCalled -CommandName SaveWsusConfiguration -Times 1
                }

                It "mocks were not called that log errors" {
                    Assert-MockCalled -CommandName New-InvalidResultException -Times 0
                    Assert-MockCalled -CommandName New-InvalidOperationException -Times 0
                }
            }

            Context 'resource supports Ensure=Absent' {

                It 'should not throw when running on a properly configured server' {
                    { Set-targetResource @DSCTestValues -Ensure Absent -verbose } | Should not throw
                }

                It "mocks were called" {
                    Assert-MockCalled -CommandName Test-TargetResource -Times 1
                    Assert-MockCalled -CommandName SaveWsusConfiguration -Times 1
                }

                It "mocks were not called that log errors" {
                    Assert-MockCalled -CommandName New-InvalidResultException -Times 0
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
