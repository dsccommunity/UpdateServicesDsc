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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscResourceName = 'MSFT_UpdateServicesComputerTargetGroup'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/ImitateUpdateServicesModule.psm1') -Force

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
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

#region Function Get-ComputerTargetGroupPath
Describe "MSFT_UpdateServicesComputerTargetGroup\Get-ComputerTargetGroupPath." {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:WsusServer = Get-WsusServer
        }
    }

    Context 'When getting the path for the "All Computers" ComputerTargetGroup' {
        It 'Should return the correct path' {
            InModuleScope -ScriptBlock {
                $ComputerTargetGroup = $script:WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'All Computers' }
                $result = Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup
                $result | Should -Be 'All Computers'
            }
        }
    }

    Context 'When getting the path for the "Desktops" ComputerTargetGroup' {
        It 'Should return the correct path' {
            InModuleScope -ScriptBlock {
                $ComputerTargetGroup = $script:WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'Desktops' }
                $result = Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup
                $result | Should -Be 'All Computers/Workstations'
            }
        }
    }

    Context 'When getting the path for the "Workstations" ComputerTargetGroup' {
        It 'Should return the correct path' {
            InModuleScope -ScriptBlock {
                $ComputerTargetGroup = $script:WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'Workstations' }
                $result = Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup
                $result | Should -Be 'All Computers'
            }
        }
    }
}
#endregion

#region Function Get-TargetResource
Describe "MSFT_UpdateServicesComputerTargetGroup\Get-TargetResource." {
    BeforeEach {
        if (Test-Path -Path variable:script:resource) { Remove-Variable -Scope 'script' -Name 'resource' }
    }

    Context 'When an error occurs retrieving WSUS Server configuration information' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith { throw 'An error occurred.' }
        }

        It 'Should throw when an error occurs retrieving WSUS Server information.' {
            { $script:resource = Get-TargetResource -Name 'Servers' -Path 'All Computers' } | Should -Throw ('*' + $script:localizedData.WSUSConfigurationFailed + '*')
            $script:resource | Should -Be $null
            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly
        }
    }

    Context 'When the WSUS Server is not yet configured.' {
        BeforeAll {
            Mock -CommandName Get-WsusServer
        }

        It 'Should not throw when the WSUS Server is not yet configured / cannot be found.' {
            $script:resource = Get-TargetResource -Name 'Servers' -Path 'All Computers'
            $script:resource.Ensure | Should -Be 'Absent'
            $script:resource.Id | Should -Be $null
            $script:resource.Name | Should -Be 'Servers'
            $script:resource.Path | Should -Be 'All Computers'
        }
    }

    Context 'When the Computer Target Group is not in the desired state (specified name does not exist at any path).' {
        It 'Should return absent when Computer Target Group does not exist at any path.' {
            $resource = Get-TargetResource -Name 'Domain Controllers' -Path 'All Computers'
            $resource.Ensure | Should -Be 'Absent'
        }
    }

    Context 'When the Computer Target Group is not in the desired state (specified name exists but not at the desired path).' {
        It 'Should throw when Computer Target Group does not exist at the specified path.' {
            { $script:resource = Get-TargetResource -Name 'Desktops' -Path 'All Computers/Servers' } | Should -Throw `
            ('*' + $script:localizedData.DuplicateComputerTargetGroup -f 'Desktops',  'All Computers/Workstations')
            $script:resource | Should -Be $null
        }
    }

    Context 'When the Computer Target Group is in the desired state (specified name exists with the desired path).' {
        It 'Should return present when Computer Target Group does exist at the specified path.' {
            $resource = Get-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations'
            $resource.Ensure | Should -Be 'Present'
            $resource.Id | Should -Be '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
        }
    }
}
#endregion

#region Function Test-TargetResource
Describe "MSFT_UpdateServicesComputerTargetGroup\Test-TargetResource." {
    Context 'When the Computer Target Group "Desktops" is "Present" at Path "All Computers/Workstations" which is the desired state.' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure          = 'Present'
                    Name            = 'Desktops'
                    Path            = 'All Computers/Workstations'
                    Id              = '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                }
            }
        }

        It 'Should return $true when Computer Target Resource is in the desired state.' {
            $resource = Test-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations'
            $resource | Should -BeTrue
        }
    }

    Context 'When the Computer Target Group "Desktops" is "Absent" at Path "All Computers/Workstations" which is the desired state (Present).' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure          = 'Absent'
                    Name            = 'Desktops'
                    Path            = 'All Computers/Workstations'
                    Id              = $null
                }
            }
        }

        It 'Should return $true when Computer Target Resource is in the desired state.' {
            $resource = Test-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations' -Ensure 'Absent'
            $resource | Should -BeTrue
        }
    }

    Context 'When the Computer Target Group "Desktops" is "Present" at Path "All Computers/Workstations" which is NOT the desired state.' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure          = 'Present'
                    Name            = 'Desktops'
                    Path            = 'All Computers/Workstations'
                    Id              = '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                }
            }
        }

        It 'Should return $false when Computer Target Resource is NOT in the desired state.' {
            $resource = Test-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations' -Ensure 'Absent'
            $resource | Should -BeFalse
        }
    }

    Context 'When the Computer Target Group "Desktops" is "Absent" at Path "All Computers/Workstations" which is NOT the desired state (Present).' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    Ensure          = 'Absent'
                    Name            = 'Desktops'
                    Path            = 'All Computers/Workstations'
                    Id              = $null
                }
            }
        }

        It 'Should return $false when Computer Target Resource is NOT in the desired state.' {
            $resource = Test-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations' -Ensure 'Present'
            $resource | Should -BeFalse
        }
    }
}
#endregion

#region Function Set-TargetResource
Describe "MSFT_UpdateServicesComputerTargetGroup\Set-TargetResource" {
    BeforeEach {
        if (Test-Path -Path variable:script:resource) { Remove-Variable -Scope 'script' -Name 'resource' }
    }

    Context 'When an error occurs retrieving WSUS Server configuration information.' {
        BeforeAll {
            Mock -CommandName Get-WsusServer -MockWith { throw 'An error occurred.' }
        }

        It 'Should throw when an error occurs retrieving WSUS Server information.' {
            { $script:resource = Set-TargetResource -Name 'Servers' -Path 'All Computers'} | Should -Throw ('*' + $script:localizedData.WSUSConfigurationFailed + '*')
            $script:resource | Should -Be $null
            Should -Invoke -CommandName Get-WsusServer -Times 1 -Exactly
        }
    }

    Context 'When the WSUS Server is not yet configured.' {
        BeforeAll {
            Mock -CommandName Get-WsusServer
        }

        It 'Should not throw when the WSUS Server is not yet configuration / cannot be found.' {
            $script:resource = Set-TargetResource -Name 'Servers' -Path 'All Computers'
            $script:resource | Should -Be $null
        }
    }

    Context 'When the Parent of the Computer Target Group is not present and therefore the new group cannot be created.' {
        BeforeAll {
            Mock -CommandName Write-Warning
        }

        It 'Should throw an exception where the Parent of the Computer Target Group does not exist.' {
            { $script:resource = Set-TargetResource -Name 'Win10' -Path 'All Computers/Desktops'} | Should -Throw `
                ('*' + $script:localizedData.NotFoundParentComputerTargetGroup -f 'Desktops', `
                'All Computers', 'Win10')
        }
    }

    Context 'When the new Computer Target Group (at Root Level) is successfully created.' {
        It 'Should create the required group where Computer Target Group (at Root Level) does not exist and Ensure is "Present".' {
            $script:resource = Set-TargetResource -Name 'Member Servers' -Path 'All Computers'
        }
    }

    Context 'When the new Computer Target Group is successfully created.' {
        It 'Should create the required group where Computer Target Group does not exist and Ensure is "Present".' {
            $script:resource = Set-TargetResource -Name 'Database' -Path 'All Computers/Servers'
        }
    }

    Context 'When the new Computer Target Group is successfully deleted.' {
        It 'Should delete the required group where Computer Target Group exists and Ensure is "Absent".' {
            $script:resource = Set-TargetResource -Name 'Web' -Path 'All Computers/Servers' -Ensure 'Absent'
        }
    }
}
#endregion
