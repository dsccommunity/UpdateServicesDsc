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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 1> $null 3> $null 4> $null 5> $null 6> $null
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
    $script:dscResourceName = 'MSFT_UpdateServicesServer'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/ImitateUpdateServicesModule.psm1') -Force

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

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
        Products                          = @("Office", "Windows")
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
        Products                          = @("Office", "Windows")
        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
        SynchronizeAutomatically          = $true
        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
        SynchronizationsPerDay            = 24
        ClientTargetingMode               = "Client"
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    Remove-Module -Name 'ImitateUpdateServicesModule' -Force -ErrorAction SilentlyContinue
}

#region Function Get-TargetResource expecting Ensure Present
Describe "MSFT_UpdateServicesServer\Get-TargetResource" {
    BeforeAll{
        Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'SQLServerName' } -MockWith { @{SQLServerName = 'SQLServer' } }
        Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'ContentDir' } -MockWith { @{ContentDir = 'C:\WSUSContent\' } }
    }

    Context 'server should be configured.' {

        It 'calling Get should not throw and mocks' {
            $Script:resource = Get-TargetResource -Ensure 'Present' -Verbose

            Should -Invoke Get-ItemProperty -Exactly 2
        }

        It 'sets the value for Ensure' {
            $Script:resource.Ensure | Should -Be 'Present'
        }

        It "returns good values in Get results"  {
            foreach ($setting in $DSCGetValues.Keys)
            {
                $Script:resource.$setting | Should -Be $DSCGetValues.$setting
            }
        }
    }

    Context 'server should not configured.' {

        It 'calling Get should not throw and mocks' {
            Mock -CommandName Get-WSUSServer -MockWith { }
            $Script:resource = Get-TargetResource -Ensure 'Absent' -Verbose

            Should -Invoke Get-WsusServer -Times 1 -Exactly
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
            $script:result = Get-TargetResource -Ensure 'Present' -Verbose

            Should -Invoke Get-WsusServer -Times 1 -Exactly
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
            $script:result = Test-TargetResource @DSCTestValues -Verbose

            Should -Invoke Get-TargetResource -Times 1 -Exactly
        }

        It "result should be true" {
            $script:result | Should -BeTrue
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
            $script:result = Test-TargetResource @DSCTestValues -Verbose

            Should -Invoke Get-TargetResource -Times 1 -Exactly
        }

        It "result should be true" {
            $script:result | Should -BeTrue
        }
    }

    Context 'server should be configured correctly but is not' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            Mock -CommandName Get-TargetResource -MockWith { $DSCTestValues } -Verifiable

            $script:result = $null
        }

        It 'calling test should not throw' {
            $script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -Verbose

            Should -Invoke Get-TargetResource -Times 1 -Exactly
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
                $script:result = Test-TargetResource @DSCTestValues -Verbose

                Should -Invoke Get-TargetResource -Times 1 -Exactly
            }

            It "result should be false when <_> has changed" {
                $script:result | Should -BeFalse
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
            $script:result = Test-TargetResource @DSCTestValues -Ensure 'Present' -Verbose
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
            Set-TargetResource @DSCTestValues -Ensure Present -Verbose

            Should -Invoke Test-TargetResource -Times 1 -Exactly
            Should -Invoke SaveWsusConfiguration -Exactly 2
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }

    Context 'resource supports Ensure=Absent' {

        It 'should not throw when running on a properly configured server' {
            Set-TargetResource @DSCTestValues -Ensure Absent -Verbose

            Should -Invoke Test-TargetResource -Times 1 -Exactly
            Should -Invoke SaveWsusConfiguration -Exactly 2

            Should -Invoke New-InvalidResultException -Exactly 0
        }
    }
}
#endregion
