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
    $script:dscResourceName = 'DSC_UpdateServicesServer'

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

    Mock -CommandName Assert-Module
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

Describe 'DSC_UpdateServicesServer\Get-TargetResource' -Tag 'Get' {
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

                Mock -CommandName Test-WsusConfigured -MockWith { $true }
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
                    $result.ProxyServerPort | Should -Be 0
                    $result.ProxyServerCredentialUsername | Should -BeNullOrEmpty
                    $result.ProxyServerBasicAuthentication | Should -BeNullOrEmpty
                    $result.Languages | Should -Be '*'
                    $result.Products | Should -Be @('Office', 'Windows')
                    $result.Classifications | Should -Be '*'
                    $result.SynchronizeAutomatically | Should -BeTrue
                    $result.SynchronizeAutomaticallyTimeOfDay | Should -Be '04:00:00'
                    $result.SynchronizationsPerDay | Should -Be 24
                    $result.ClientTargetingMode | Should -Be 'Client'
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

                Mock -CommandName Test-WsusConfigured -MockWith { $true }
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
                    $result.ProxyServerPort | Should -Be 0
                    $result.ProxyServerCredentialUsername | Should -BeNullOrEmpty
                    $result.ProxyServerBasicAuthentication | Should -BeNullOrEmpty
                    $result.Languages | Should -Be '*'
                    $result.Products | Should -Be @('Office', 'Windows')
                    $result.Classifications | Should -Be '*'
                    $result.SynchronizeAutomatically | Should -BeTrue
                    $result.SynchronizeAutomaticallyTimeOfDay | Should -Be '04:00:00'
                    $result.SynchronizationsPerDay | Should -Be 24
                    $result.ClientTargetingMode | Should -Be 'Client'
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

            Mock -CommandName Test-WsusConfigured -MockWith { $true }
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

Describe 'DSC_UpdateServicesServer\Test-TargetResource' -Tag 'Test' {
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
                Should -Invoke -CommandName Get-WsusServer -Exactly -Times 0 -Scope It
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

        Context 'When the ContentDir property is an empty string' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure             = 'Present'
                        ContentDir         = ''
                        UpstreamServerName = ''
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Test-TargetResource -Ensure 'Present' -ContentDir '' | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }

            Context 'When the server hosts the content locally' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure             = 'Present'
                            ContentDir         = 'C:\WSUSContent\'
                            UpstreamServerName = ''
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        Test-TargetResource -Ensure 'Present' -ContentDir '' | Should -BeFalse
                    }
                }
            }
        }

        Context 'When the GetContentFromMU property is used' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure             = 'Present'
                        ContentDir         = 'C:\WSUSContent\'
                        UpstreamServerName = 'UpstreamServer'
                        UpstreamServerPort = 8530
                        UpstreamServerSSL  = $false
                        GetContentFromMU   = $false
                    }
                }
            }

            Context 'When the setting matches' {
                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure             = 'Present'
                            ContentDir         = 'C:\WSUSContent\'
                            UpstreamServerName = 'UpstreamServer'
                            GetContentFromMU   = $false
                        }

                        Test-TargetResource @testParams | Should -BeTrue
                    }
                }
            }

            Context 'When the setting does not match' {
                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure             = 'Present'
                            ContentDir         = 'C:\WSUSContent\'
                            UpstreamServerName = 'UpstreamServer'
                            GetContentFromMU   = $true
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }

            Context 'When no upstream server is configured' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure             = 'Present'
                            ContentDir         = 'C:\WSUSContent\'
                            UpstreamServerName = ''
                            GetContentFromMU   = $null
                        }
                    }
                }

                It 'Should ignore the setting' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure             = 'Present'
                            ContentDir         = 'C:\WSUSContent\'
                            UpstreamServerName = ''
                            GetContentFromMU   = $true
                        }

                        Test-TargetResource @testParams | Should -BeTrue
                    }
                }
            }

            Context 'When UpstreamServerName is not specified but is configured on the server' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure             = 'Present'
                            ContentDir         = 'C:\WSUSContent\'
                            UpstreamServerName = 'UpstreamServer'
                            GetContentFromMU   = $false
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure           = 'Present'
                            ContentDir       = 'C:\WSUSContent\'
                            GetContentFromMU = $true
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }
        }

        Context 'When the UpstreamServerReplica property is used' {
            Context 'When UpstreamServerName is not specified but is configured on the server' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure                = 'Present'
                            UpstreamServerName    = 'UpstreamServer'
                            UpstreamServerReplica = $false
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure                = 'Present'
                            UpstreamServerReplica = $true
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }
        }

        Context 'When the EmailServerCredential property is used' {
            Context 'When SmtpHostName is not specified but is configured on the server' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure       = 'Present'
                            SmtpHostName = 'smtp.contoso.com'
                            SmtpUserName = ''
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure                = 'Present'
                            EmailServerCredential = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }
        }

        Context 'When the ProxyServerCredential property is used' {
            Context 'When ProxyServerName is not specified but is configured on the server' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure                        = 'Present'
                            ProxyServerName               = 'ProxyServer'
                            ProxyServerCredentialUserName = ''
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure                = 'Present'
                            ProxyServerCredential = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }
        }

        Context 'When the status notification schedule is used without recipients' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        Ensure                      = 'Present'
                        StatusNotificationFrequency = 'Daily'
                        StatusNotificationTimeOfDay = '07:00:00'
                    }
                }
            }

            Context 'When the frequency does not match' {
                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure                      = 'Present'
                            StatusNotificationFrequency = 'Weekly'
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }

            Context 'When the time of day does not match' {
                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure                      = 'Present'
                            StatusNotificationTimeOfDay = '09:00:00'
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }
        }

        Context 'When list properties are compared' {
            BeforeAll {
                Mock -CommandName Get-WsusServer -MockWith {
                    return CommonTestHelper\Get-WsusServerTemplate
                }
            }

            Context 'When the notification recipients are returned in a different order' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure                       = 'Present'
                            SyncNotificationRecipients   = @('b@contoso.com', 'a@contoso.com')
                            StatusNotificationRecipients = @('d@contoso.com', 'c@contoso.com')
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure                       = 'Present'
                            SyncNotificationRecipients   = @('a@contoso.com', 'b@contoso.com')
                            StatusNotificationRecipients = @('c@contoso.com', 'd@contoso.com')
                        }

                        Test-TargetResource @testParams | Should -BeTrue
                    }
                }
            }

            <#
                Get-TargetResource returns an empty array rather than $null for
                these, but Test-TargetResource must not throw if it ever does.
            #>
            Context 'When a list property is not returned at all' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure = 'Present'
                        }
                    }
                }

                It 'Should return the correct result without throwing' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure                       = 'Present'
                            Languages                    = @('en')
                            Products                     = @('Windows')
                            Classifications              = @('E6CF1350-C01B-414D-A61F-263D14D133B4')
                            SyncNotificationRecipients   = @('a@contoso.com')
                            StatusNotificationRecipients = @('c@contoso.com')
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }

            Context 'When a list property is requested as empty and the server has none' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        @{
                            Ensure                       = 'Present'
                            SyncNotificationRecipients   = @()
                            StatusNotificationRecipients = @()
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            Ensure                       = 'Present'
                            SyncNotificationRecipients   = @()
                            StatusNotificationRecipients = @()
                        }

                        Test-TargetResource @testParams | Should -BeTrue
                    }
                }
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
            # SetupCredential, SQLServer and Synchronize are not compared by Test-TargetResource
            $testCases = @(
                'ContentDir'
                'UpdateImprovementProgram'
                'UpstreamServerName'
                'UpstreamServerPort'
                'UpstreamServerSSL'
                'UpstreamServerReplica'
                'ProxyServerName'
                'ProxyServerPort'
                'ProxyServerCredentialUserName'
                'ProxyServerBasicAuthentication'
                'DownloadUpdateBinariesAsNeeded'
                'DownloadExpressPackages'
                'GetContentFromMU'
                'Languages'
                'Products'
                'Classifications'
                'SynchronizeAutomatically'
                'SynchronizeAutomaticallyTimeOfDay'
                'SynchronizationsPerDay'
                'AutoApproveWsusInfrastructureUpdates'
                'AutoRefreshUpdateApprovals'
                'AutoRefreshUpdateApprovalsDeclineExpired'
                'ClientTargetingMode'
                'DoDetailedRollup'
                'SyncNotificationRecipients'
                'StatusNotificationFrequency'
                'StatusNotificationTimeOfDay'
                'StatusNotificationRecipients'
                'EmailLanguage'
                'SmtpHostName'
                'SmtpPort'
                'SenderDisplayName'
                'SenderEmailAddress'
                'SmtpUserName'
                'IIsDynamicCompression'
                'BitsDownloadPriorityForeground'
                'LocalPublishingMaxCabSize'
                'MaxSimultaneousFileDownloads'
            )
        }

        Context 'When property ''<_>'' is incorrect' -ForEach $testCases {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    $data = @{
                        Ensure                                   = 'Present'
                        SetupCredential                          = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                                = 'SQLServer'
                        ContentDir                               = 'C:\WSUSContent\'
                        UpdateImprovementProgram                 = $true
                        UpstreamServerName                       = 'UpstreamServer'
                        UpstreamServerPort                       = $false
                        UpstreamServerSSL                        = $false
                        UpstreamServerReplica                    = $false
                        ProxyServerName                          = 'ProxyServer'
                        ProxyServerPort                          = 8080
                        ProxyServerCredentialUserName            = 'ProxyUser'
                        ProxyServerBasicAuthentication           = $true
                        DownloadUpdateBinariesAsNeeded           = $true
                        DownloadExpressPackages                  = $true
                        GetContentFromMU                         = $true
                        Languages                                = '*'
                        Products                                 = @('Windows', 'Office')
                        Classifications                          = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically                 = $true
                        SynchronizeAutomaticallyTimeOfDay        = '04:00:00'
                        SynchronizationsPerDay                   = 24
                        AutoApproveWsusInfrastructureUpdates     = $true
                        AutoRefreshUpdateApprovals               = $true
                        AutoRefreshUpdateApprovalsDeclineExpired = $true
                        ClientTargetingMode                      = 'Client'
                        DoDetailedRollup                         = $true
                        SyncNotificationRecipients               = @('sync@contoso.com')
                        StatusNotificationFrequency              = 'Daily'
                        StatusNotificationTimeOfDay              = '09:00:00'
                        StatusNotificationRecipients             = @('status@contoso.com')
                        EmailLanguage                            = 'en'
                        SmtpHostName                             = 'smtp.contoso.com'
                        SmtpPort                                 = 25
                        SenderDisplayName                        = 'WSUS Server'
                        SenderEmailAddress                       = 'wsus@contoso.com'
                        SmtpUserName                             = 'SmtpUser'
                        IIsDynamicCompression                    = $true
                        BitsDownloadPriorityForeground           = $true
                        LocalPublishingMaxCabSize                = 100
                        MaxSimultaneousFileDownloads             = 10
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
                        Ensure                                   = 'Present'
                        SetupCredential                          = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        SQLServer                                = 'SQLServer'
                        ContentDir                               = 'C:\WSUSContent\'
                        UpdateImprovementProgram                 = $true
                        UpstreamServerName                       = 'UpstreamServer'
                        UpstreamServerPort                       = $false
                        UpstreamServerSSL                        = $false
                        UpstreamServerReplica                    = $false
                        ProxyServerName                          = 'ProxyServer'
                        ProxyServerPort                          = 8080
                        ProxyServerCredential                    = [System.Management.Automation.PSCredential]::new('ProxyUser', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        ProxyServerBasicAuthentication           = $true
                        DownloadUpdateBinariesAsNeeded           = $true
                        DownloadExpressPackages                  = $true
                        GetContentFromMU                         = $true
                        Languages                                = '*'
                        Products                                 = @('Windows', 'Office')
                        Classifications                          = @('E6CF1350-C01B-414D-A61F-263D14D133B4', 'E0789628-CE08-4437-BE74-2495B842F43B', '0FA1201D-4330-4FA8-8AE9-B877473B6441')
                        SynchronizeAutomatically                 = $true
                        SynchronizeAutomaticallyTimeOfDay        = '04:00:00'
                        SynchronizationsPerDay                   = 24
                        AutoApproveWsusInfrastructureUpdates     = $true
                        AutoRefreshUpdateApprovals               = $true
                        AutoRefreshUpdateApprovalsDeclineExpired = $true
                        ClientTargetingMode                      = 'Client'
                        DoDetailedRollup                         = $true
                        SyncNotificationRecipients               = @('sync@contoso.com')
                        StatusNotificationFrequency              = 'Daily'
                        StatusNotificationTimeOfDay              = '09:00:00'
                        StatusNotificationRecipients             = @('status@contoso.com')
                        EmailLanguage                            = 'en'
                        SmtpHostName                             = 'smtp.contoso.com'
                        SmtpPort                                 = 25
                        SenderDisplayName                        = 'WSUS Server'
                        SenderEmailAddress                       = 'wsus@contoso.com'
                        EmailServerCredential                    = [System.Management.Automation.PSCredential]::new('SmtpUser', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                        IIsDynamicCompression                    = $true
                        BitsDownloadPriorityForeground           = $true
                        LocalPublishingMaxCabSize                = 100
                        MaxSimultaneousFileDownloads             = 10
                    }

                    Test-TargetResource @testParams | Should -BeFalse

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Get-WsusServer -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}

Describe 'DSC_UpdateServicesServer\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Test-TargetResource -MockWith { $true }
        Mock -CommandName Save-WsusConfiguration
        Mock -CommandName Get-WsusServer -MockWith {
            return CommonTestHelper\Get-WsusServerTemplate
        }

        Mock -CommandName Test-WsusConfigured -MockWith { $true }

        Mock -CommandName New-Object -MockWith {
            $mockObject = [PSCustomObject] @{}
            $mockObject | Add-Member -Force -MemberType ScriptMethod -Name Add -Value { return }
            return $mockObject
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
            Should -Invoke -CommandName Save-WsusConfiguration -Exactly -Times 3 -Scope It
            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 2 -Scope It
        }
    }

    Context 'When none of the requested products exist on the server' {
        BeforeAll {
            # Counts the calls that would have cleared the product selection.
            $script:mockSubscription = [PSCustomObject] @{
                SetUpdateCategoriesCallCount = 0
            }

            $script:mockSubscription | Add-Member -MemberType ScriptMethod -Name SetUpdateCategories -Value {
                $this.SetUpdateCategoriesCallCount++
            }

            $script:mockSubscription | Add-Member -MemberType ScriptMethod -Name Save -Value {}

            $mockSubscriptionReference = $script:mockSubscription

            <#
                Return a real collection so that the resource can count what was
                added to it, as the WSUS collection types do.
            #>
            Mock -CommandName New-Object -MockWith {
                return [System.Collections.ArrayList]::new()
            }

            Mock -CommandName Get-WsusServer -MockWith {
                $mockWsusServer = CommonTestHelper\Get-WsusServerTemplate
                $mockWsusServer | Add-Member -Force -MemberType NoteProperty -Name MockSubscription -Value $mockSubscriptionReference
                $mockWsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetSubscription -Value {
                    return $this.MockSubscription
                }

                return $mockWsusServer
            }
        }

        It 'Should throw the correct error without clearing the product selection' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure   = 'Present'
                    Products = @('NoSuchProduct')
                }

                $errorMessage = $script:localizedData.NoProductsFoundError -f 'NoSuchProduct'

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage ('*' + $errorMessage + '*')
            }

            $script:mockSubscription.SetUpdateCategoriesCallCount | Should -Be 0
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
            Should -Invoke -CommandName Save-WsusConfiguration -Exactly -Times 3 -Scope It
            Should -Invoke -CommandName Get-WsusServer -Exactly -Times 2 -Scope It
        }
    }

    Context 'When the WSUS Services role is already configured but the initial synchronization has never completed, and Synchronize is not requested' {
        BeforeAll {
            $parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
            Import-Module (Join-Path -Path $parentModule.ModuleBase -ChildPath 'Modules\PDT\PDT.psm1') -Force

            Mock -CommandName Get-WsusServer -MockWith {
                $wsusServer = CommonTestHelper\Get-WsusServerTemplate

                $wsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetConfiguration -Value {
                    $configuration = @{
                        OobeInitialized           = $false
                        AllUpdateLanguagesEnabled = $true
                    }
                    $configuration | Add-Member -MemberType ScriptMethod -Name Save -Value {}

                    return $configuration
                }

                return $wsusServer
            }

            Mock -CommandName Invoke-ResolvePath -MockWith { 'C:\Program Files\Update Services\Tools\WsusUtil.exe' }
            Mock -CommandName Start-Win32Process -MockWith { 'Process started' }
            Mock -CommandName Wait-Win32ProcessEnd
        }

        It 'Should resolve WsusUtil.exe before running the offline synchronization' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure = 'Present'
                }

                $null = Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Invoke-ResolvePath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Win32Process -ParameterFilter {
                -not [String]::IsNullOrEmpty($Path)
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a dependent setting is specified but the setting it depends on is not' {
        Context 'When an upstream server is already configured on the server' {
            BeforeAll {
                # An upstream server is already configured on the server
                $script:mockConfiguration = @{
                    OobeInitialized           = $true
                    SyncFromMicrosoftUpdate   = $false
                    IsReplicaServer           = $false
                    AllUpdateLanguagesEnabled = $true
                }
                $script:mockConfiguration | Add-Member -MemberType ScriptMethod -Name Save -Value {}

                $mockConfigurationReference = $script:mockConfiguration

                Mock -CommandName Get-WsusServer -MockWith {
                    $mockWsusServer = CommonTestHelper\Get-WsusServerTemplate

                    $mockWsusServer | Add-Member -Force -MemberType NoteProperty -Name MockConfiguration -Value $mockConfigurationReference
                    $mockWsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetConfiguration -Value {
                        return $this.MockConfiguration
                    }

                    return $mockWsusServer
                }
            }

            It 'Should apply GetContentFromMU using the upstream server already configured on the server' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure           = 'Present'
                        ContentDir       = 'C:\WSUSContent\'
                        GetContentFromMU = $true
                    }

                    $null = Set-TargetResource @testParams
                }

                $script:mockConfiguration.GetContentFromMU | Should -BeTrue
            }
        }

        Context 'When an SMTP host is already configured on the server' {
            BeforeAll {
                # An SMTP host is already configured on the server
                $script:mockEmailConfiguration = @{
                    SmtpHostName                     = 'smtp.contoso.com'
                    SmtpServerRequiresAuthentication = $false
                    SetSmtpUserPasswordCallCount     = 0
                }
                $script:mockEmailConfiguration | Add-Member -MemberType ScriptMethod -Name Save -Value {}
                $script:mockEmailConfiguration | Add-Member -MemberType ScriptMethod -Name SetSmtpUserPassword -Value {
                    $this.SetSmtpUserPasswordCallCount++
                }

                $mockEmailConfigurationReference = $script:mockEmailConfiguration

                Mock -CommandName Get-WsusServer -MockWith {
                    $mockWsusServer = CommonTestHelper\Get-WsusServerTemplate

                    $mockWsusServer | Add-Member -Force -MemberType NoteProperty -Name MockEmailConfiguration -Value $mockEmailConfigurationReference
                    $mockWsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetEmailNotificationConfiguration -Value {
                        return $this.MockEmailConfiguration
                    }

                    return $mockWsusServer
                }
            }

            It 'Should apply EmailServerCredential using the SMTP host already configured on the server' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        Ensure                = 'Present'
                        EmailServerCredential = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                    }

                    $null = Set-TargetResource @testParams
                }

                $script:mockEmailConfiguration.SmtpServerRequiresAuthentication | Should -BeTrue
                $script:mockEmailConfiguration.SmtpUserName | Should -Be 'foo'
                $script:mockEmailConfiguration.SetSmtpUserPasswordCallCount | Should -Be 1
            }
        }
    }

    Context 'When the server is already a replica and UpstreamServerReplica is not specified' {
        BeforeAll {
            $script:mockReplicaConfiguration = @{
                OobeInitialized           = $true
                SyncFromMicrosoftUpdate   = $false
                IsReplicaServer           = $true
                AllUpdateLanguagesEnabled = $true
            }
            $script:mockReplicaConfiguration | Add-Member -MemberType ScriptMethod -Name Save -Value {}

            $mockReplicaConfigurationReference = $script:mockReplicaConfiguration

            Mock -CommandName Get-WsusServer -MockWith {
                $mockWsusServer = CommonTestHelper\Get-WsusServerTemplate

                $mockWsusServer | Add-Member -Force -MemberType NoteProperty -Name MockConfiguration -Value $mockReplicaConfigurationReference
                $mockWsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetConfiguration -Value {
                    return $this.MockConfiguration
                }

                return $mockWsusServer
            }
        }

        It 'Should not apply UpdateImprovementProgram' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure                   = 'Present'
                    UpdateImprovementProgram = $true
                }

                $null = Set-TargetResource @testParams
            }

            $script:mockReplicaConfiguration.ContainsKey('MURollupOptin') | Should -BeFalse
        }
    }

    Context 'When ProxyServerName is not specified but a proxy server is configured on the server' {
        BeforeAll {
            # A proxy server is already configured on the server
            $script:mockProxyConfiguration = @{
                OobeInitialized           = $true
                UseProxy                  = $true
                AnonymousProxyAccess      = $true
                AllUpdateLanguagesEnabled = $true
                SetProxyPasswordCallCount = 0
            }
            $script:mockProxyConfiguration | Add-Member -MemberType ScriptMethod -Name Save -Value {}
            $script:mockProxyConfiguration | Add-Member -MemberType ScriptMethod -Name SetProxyPassword -Value {
                $this.SetProxyPasswordCallCount++
            }

            $mockProxyConfigurationReference = $script:mockProxyConfiguration

            Mock -CommandName Get-WsusServer -MockWith {
                $mockWsusServer = CommonTestHelper\Get-WsusServerTemplate

                $mockWsusServer | Add-Member -Force -MemberType NoteProperty -Name MockConfiguration -Value $mockProxyConfigurationReference
                $mockWsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetConfiguration -Value {
                    return $this.MockConfiguration
                }

                return $mockWsusServer
            }
        }

        It 'Should apply ProxyServerCredential' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure                = 'Present'
                    ProxyServerCredential = [System.Management.Automation.PSCredential]::new('foo', $('bar' | ConvertTo-SecureString -AsPlainText -Force))
                }

                $null = Set-TargetResource @testParams
            }

            $script:mockProxyConfiguration.AnonymousProxyAccess | Should -BeFalse
            $script:mockProxyConfiguration.ProxyUserName | Should -Be 'foo'
            $script:mockProxyConfiguration.SetProxyPasswordCallCount | Should -Be 1
        }
    }

    Context 'When the status notification schedule is specified without recipients' {
        BeforeAll {
            $script:mockScheduleConfiguration = @{
                SendStatusNotification = $true
            }
            $script:mockScheduleConfiguration | Add-Member -MemberType ScriptMethod -Name Save -Value {}

            $mockScheduleConfigurationReference = $script:mockScheduleConfiguration

            Mock -CommandName Get-WsusServer -MockWith {
                $mockWsusServer = CommonTestHelper\Get-WsusServerTemplate

                $mockWsusServer | Add-Member -Force -MemberType NoteProperty -Name MockEmailConfiguration -Value $mockScheduleConfigurationReference
                $mockWsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetEmailNotificationConfiguration -Value {
                    return $this.MockEmailConfiguration
                }

                return $mockWsusServer
            }
        }

        It 'Should apply the schedule' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    Ensure                      = 'Present'
                    StatusNotificationFrequency = 'Weekly'
                }

                $null = Set-TargetResource @testParams
            }

            $script:mockScheduleConfiguration.StatusNotificationFrequency | Should -Be 'Weekly'
        }
    }
}
