# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

    # Load stub cmdlets and classes.
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\UpdateServices.stubs.psm1')
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload stub module
    Remove-Module -Name UpdateServices.stubs -Force
    Remove-Module -Name CommonTestHelper -Force

    # Unload the module being tested so that It doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'MSFT_UpdateServicesServer\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource is in the desired state' {
        Context 'When the server exists' {
            BeforeAll {
                Mock -CommandName Get-WsusServer -MockWith {
                    return CommonTestHelper\Get-WsusServerTemplate
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'SQLServerName'
                } -MockWith {
                    @{
                        SQLServerName = 'SQLServer'
                    }
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'ContentDir'
                } -MockWith {
                    @{
                        ContentDir = 'C:\WSUSContent\'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    #ISSUE: $ProxyCredentialUserName is not initialized
                    # Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Ensure 'Present'

                    $result.Ensure | Should -Be 'Present'
                    $result.SQLServer | Should -Be 'SQLServer'
                    $result.ContentDir | Should -Be 'C:\WSUSContent\'
                    $result.UpdateImprovementProgram | Should -BeTrue
                    $result.UpstreamServerName | Should -BeNullOrEmpty
                    $result.UpstreamServerPort | Should -BeNullOrEmpty
                    $result.UpstreamServerSSL | Should -BeNullOrEmpty
                    $result.UpstreamServerReplica | Should -BeNullOrEmpty
                    $result.ProxyServerName | Should -BeNullOrEmpty
                    $result.ProxyServerPort | Should -BeNullOrEmpty
                    $result.ProxyServerCredentialUsername | Should -BeNullOrEmpty
                    $result.ProxyServerBasicAuthentication | Should -BeNullOrEmpty
                    $result.Languages | Should -Be '*'
                    $result.Products | Should -Be @('Office', 'Windows')
                    $result.Classifications | Should -Be '*'
                    $result.SynchronizeAutomatically | Should -BeTrue
                    $result.SynchronizeAutomaticallyTimeOfDay | Should -Be '04:00:00'
                    $result.SynchronizationsPerDay | Should -Be 24
                    $result.ClientTargetingMode | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the server does not exist' {
            BeforeAll {
                Mock -CommandName Get-WsusServer
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    #ISSUE: variables are not initialized
                    # Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Ensure 'Absent'

                    $result.Ensure | Should -Be 'Absent'
                    $result.SQLServer | Should -BeNullOrEmpty
                    $result.ContentDir | Should -BeNullOrEmpty
                    $result.UpdateImprovementProgram | Should -BeNullOrEmpty
                    $result.UpstreamServerName | Should -BeNullOrEmpty
                    $result.UpstreamServerPort | Should -BeNullOrEmpty
                    $result.UpstreamServerSSL | Should -BeNullOrEmpty
                    $result.UpstreamServerReplica | Should -BeNullOrEmpty
                    $result.ProxyServerName | Should -BeNullOrEmpty
                    $result.ProxyServerPort | Should -BeNullOrEmpty
                    $result.ProxyServerCredentialUsername | Should -BeNullOrEmpty
                    $result.ProxyServerBasicAuthentication | Should -BeNullOrEmpty
                    $result.Languages | Should -BeNullOrEmpty
                    $result.Products | Should -BeNullOrEmpty
                    $result.Classifications | Should -BeNullOrEmpty
                    $result.SynchronizeAutomatically | Should -BeNullOrEmpty
                    $result.SynchronizeAutomaticallyTimeOfDay | Should -BeNullOrEmpty
                    $result.SynchronizationsPerDay | Should -BeNullOrEmpty
                    $result.ClientTargetingMode | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        Context 'When the server exists' {
            BeforeAll {
                Mock -CommandName Get-WsusServer -MockWith {
                    return CommonTestHelper\Get-WsusServerTemplate
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'SQLServerName'
                } -MockWith {
                    @{
                        SQLServerName = 'SQLServer'
                    }
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'ContentDir'
                } -MockWith {
                    @{
                        ContentDir = 'C:\WSUSContent\'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    #ISSUE: $ProxyCredentialUserName is not initialized
                    # Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Ensure 'Absent'

                    $result.Ensure | Should -Be 'Present'
                    $result.SQLServer | Should -Be 'SQLServer'
                    $result.ContentDir | Should -Be 'C:\WSUSContent\'
                    $result.UpdateImprovementProgram | Should -BeTrue
                    $result.UpstreamServerName | Should -BeNullOrEmpty
                    $result.UpstreamServerPort | Should -BeNullOrEmpty
                    $result.UpstreamServerSSL | Should -BeNullOrEmpty
                    $result.UpstreamServerReplica | Should -BeNullOrEmpty
                    $result.ProxyServerName | Should -BeNullOrEmpty
                    $result.ProxyServerPort | Should -BeNullOrEmpty
                    $result.ProxyServerCredentialUsername | Should -BeNullOrEmpty
                    $result.ProxyServerBasicAuthentication | Should -BeNullOrEmpty
                    $result.Languages | Should -Be '*'
                    $result.Products | Should -Be @('Office', 'Windows')
                    $result.Classifications | Should -Be '*'
                    $result.SynchronizeAutomatically | Should -BeTrue
                    $result.SynchronizeAutomaticallyTimeOfDay | Should -Be '04:00:00'
                    $result.SynchronizationsPerDay | Should -Be 24
                    $result.ClientTargetingMode | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the server does not exist' {
            BeforeAll {
                Mock -CommandName Get-WsusServer
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    #ISSUE: variables are not initialized
                    # Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Ensure 'Present'

                    $result.Ensure | Should -Be 'Absent'
                    $result.SQLServer | Should -BeNullOrEmpty
                    $result.ContentDir | Should -BeNullOrEmpty
                    $result.UpdateImprovementProgram | Should -BeNullOrEmpty
                    $result.UpstreamServerName | Should -BeNullOrEmpty
                    $result.UpstreamServerPort | Should -BeNullOrEmpty
                    $result.UpstreamServerSSL | Should -BeNullOrEmpty
                    $result.UpstreamServerReplica | Should -BeNullOrEmpty
                    $result.ProxyServerName | Should -BeNullOrEmpty
                    $result.ProxyServerPort | Should -BeNullOrEmpty
                    $result.ProxyServerCredentialUsername | Should -BeNullOrEmpty
                    $result.ProxyServerBasicAuthentication | Should -BeNullOrEmpty
                    $result.Languages | Should -BeNullOrEmpty
                    $result.Products | Should -BeNullOrEmpty
                    $result.Classifications | Should -BeNullOrEmpty
                    $result.SynchronizeAutomatically | Should -BeNullOrEmpty
                    $result.SynchronizeAutomaticallyTimeOfDay | Should -BeNullOrEmpty
                    $result.SynchronizationsPerDay | Should -BeNullOrEmpty
                    $result.ClientTargetingMode | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'Products property contains wildcard' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith {
                return CommonTestHelper\Get-WsusServerMockWildCardPrdt
            }

            Mock -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'SQLServerName'
            } -MockWith {
                @{
                    SQLServerName = 'SQLServer'
                }
            }

            Mock -CommandName Get-ItemProperty -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -and $Name -eq 'ContentDir'
            } -MockWith {
                @{
                    ContentDir = 'C:\WSUSContent\'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                #ISSUE: variables are not initialized
                # Set-StrictMode -Version 1.0

                $script:result = Get-TargetResource -Ensure 'Present'

                $script:result.Products | Should -HaveCount 6
            }

            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
        }

        BeforeDiscovery {
            $testCases = @(
                @{
                    Name = 'Windows Server 2003'
                }
                @{
                    Name = 'Windows Server 2008'
                }
                @{
                    Name = 'Windows Server 2008R2'
                }
                @{
                    Name = 'Windows Server 2012'
                }
                @{
                    Name = 'Windows Server 2016'
                }
                @{
                    Name = 'Windows Server 2019'
                }
            )
        }

        It 'Should have Product ''<Name>'' returned' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:result.Products | Should -Contain $name
            }
        }
    }
}

Describe 'MSFT_UpdateServicesServer\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource is in the desired state' {
        Context 'When the resource should be ''Present''' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure                            = 'Present'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows', 'Office')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }
                }

                Mock -CommandName Get-WsusServer -MockWith {
                    return CommonTestHelper\Get-WsusServerTemplate
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                            = 'Present'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows', 'Office')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the resource should be ''Absent''' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure                            = 'Absent'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows', 'Office')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }
                }

                Mock -CommandName Get-WsusServer -MockWith {
                    return CommonTestHelper\Get-WsusServerTemplate
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                            = 'Absent'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows', 'Office')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the Products property contains wildcard' {
            BeforeAll {
                Mock -CommandName Get-WsusServer -Verifiable -MockWith {
                    return Get-WsusServerMockWildCardPrdt
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure                            = 'Present'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows Server 2003', 'Windows Server 2008', 'Windows Server 2008R2', 'Windows Server 2012', 'Windows Server 2016', 'Windows Server 2019')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = 'Windows Server*'
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }

                    Test-TargetResource @testParams -Ensure 'Present' | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        Context 'When the server should be ''Present''' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure                            = 'Absent'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows', 'Office')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }
                }

                Mock -CommandName Get-WsusServer -MockWith {
                    return CommonTestHelper\Get-WsusServerTemplate
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                            = 'Present'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows', 'Office')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }

                    Test-TargetResource @testParams | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 0 -Scope It
            }
        }

        BeforeDiscovery {
            # Settings not currently tested: ProxyServerUserName, ProxyServerCredential, ProxyServerBasicAuthentication, 'Languages', 'Products', 'Classifications', 'SynchronizeAutomatically'
            $testCases = @(
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
        }

        Context 'When property ''<_>'' is incorrect' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    $data = @{
                        Ensure                            = 'Absent'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows', 'Office')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }
                    $data.Remove($_)

                    return $data
                }

                Mock -CommandName Get-WsusServer -MockWith {
                    return CommonTestHelper\Get-WsusServerTemplate
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                            = 'Present'
                        SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                         = 'SQLServer'
                        ContentDir                        = 'C:\WSUSContent\'
                        UpdateImprovementProgram          = $true
                        UpstreamServerName                = 'UpstreamServer'
                        UpstreamServerPort                = $false
                        UpstreamServerSSL                 = $false
                        UpstreamServerReplica             = $false
                        ProxyServerName                   = 'ProxyServer'
                        ProxyServerPort                   = 8080
                        Languages                         = '*'
                        Products                          = @('Windows', 'Office')
                        Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically          = $true
                        SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                        SynchronizationsPerDay            = 24
                        ClientTargetingMode               = 'Client'
                    }

                    Test-TargetResource @testParams | Should -BeFalse

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Get-WsusServer -Exactly -Times 0 -Scope It
                }
            }
        }
    }
}

Describe 'MSFT_UpdateServicesServer\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Test-TargetResource -MockWith { $true }
        Mock -CommandName SaveWsusConfiguration
        Mock -CommandName Get-WsusServer -MockWith {
            return CommonTestHelper\Get-WsusServerTemplate
        }
    }

    Context 'When the resource should be ''Present''' {
        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure                            = 'Present'
                    SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                    SQLServer                         = 'SQLServer'
                    ContentDir                        = 'C:\WSUSContent\'
                    UpdateImprovementProgram          = $true
                    UpstreamServerName                = 'UpstreamServer'
                    UpstreamServerPort                = $false
                    UpstreamServerSSL                 = $false
                    UpstreamServerReplica             = $false
                    ProxyServerName                   = 'ProxyServer'
                    ProxyServerPort                   = 8080
                    Languages                         = '*'
                    Products                          = @('Windows', 'Office')
                    Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                    SynchronizeAutomatically          = $true
                    SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                    SynchronizationsPerDay            = 24
                    ClientTargetingMode               = 'Client'
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName SaveWsusConfiguration -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 2 -Scope It
        }
    }

    Context 'When the resource should be ''Absent''' {
        It 'Should call the correct mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure                            = 'Absent'
                    SetupCredential                   = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                    SQLServer                         = 'SQLServer'
                    ContentDir                        = 'C:\WSUSContent\'
                    UpdateImprovementProgram          = $true
                    UpstreamServerName                = 'UpstreamServer'
                    UpstreamServerPort                = $false
                    UpstreamServerSSL                 = $false
                    UpstreamServerReplica             = $false
                    ProxyServerName                   = 'ProxyServer'
                    ProxyServerPort                   = 8080
                    Languages                         = '*'
                    Products                          = @('Windows', 'Office')
                    Classifications                   = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                    SynchronizeAutomatically          = $true
                    SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                    SynchronizationsPerDay            = 24
                    ClientTargetingMode               = 'Client'
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName SaveWsusConfiguration -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 2 -Scope It
        }
    }
}
