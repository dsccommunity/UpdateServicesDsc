$script:dscModuleName = 'UpdateServicesDsc'
$script:dscResourceName = 'MSFT_UpdateServicesComputerTargetGroup'

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
    InModuleScope $script:DSCResourceName {

        #region Pester Test Initialization
        Import-Module $PSScriptRoot\..\Helpers\ImitateUpdateServicesModule.psm1 -Force

        #endregion

        #region Function Get-ComputerTargetGroupPath
        Describe "MSFT_UpdateServicesComputerTargetGroup\Get-ComputerTargetGroupPath." {
            $WsusServer = Get-WsusServer

            Context "The Function returns expected path for the 'All Computers' ComputerTargetGroup." {
                $ComputerTargetGroup = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'All Computers' }
                $result = Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup
                $result | Should -Be 'All Computers'
            }

            Context "The Function returns expected path for the 'Desktops' ComputerTargetGroup." {
                $ComputerTargetGroup = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'Desktops' }
                $result = Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup
                $result | Should -Be 'All Computers/Workstations'
            }

            Context "The Function returns expected path for the 'Workstations' ComputerTargetGroup." {
                $ComputerTargetGroup = $WsusServer.GetComputerTargetGroups() | Where-Object -FilterScript { $_.Name -eq 'Workstations' }
                $result = Get-ComputerTargetGroupPath -ComputerTargetGroup $ComputerTargetGroup
                $result | Should -Be 'All Computers'
            }
        }
        #endregion

        #region Function Get-TargetResource
        Describe "MSFT_UpdateServicesComputerTargetGroup\Get-TargetResource." {
            Mock -CommandName Write-Verbose -MockWith {}
            if (Test-Path -Path variable:script:resource) { Remove-Variable -Scope 'script' -Name 'resource' }

            Context 'An error occurs retrieving WSUS Server configuration information.' {
                Mock -CommandName Get-WsusServer -MockWith { throw 'An error occurred.' }

                It 'Calling Get should throw when an error occurrs retrieving WSUS Server information.' {
                    { $script:resource = Get-TargetResource -Name 'Servers' -Path 'All Computers'} | Should -Throw ($script:localizedData.WSUSConfigurationFailed)
                    $script:resource | Should -Be $null
                    Assert-MockCalled -CommandName Get-WsusServer -Exactly 1
                }
            }

            Context 'The WSUS Server is not yet configured.' {
                Mock -CommandName Get-WsusServer -MockWith {}

                It 'Calling Get should not throw when the WSUS Server is not yet configuration / cannot be found.' {
                    { $script:resource = Get-TargetResource -Name 'Servers' -Path 'All Computers'} | Should -Not -Throw
                    Assert-MockCalled -CommandName Write-Verbose  -ParameterFilter {
                        $message -eq $script:localizedData.GetWsusServerFailed
                    }
                    $script:resource.Ensure | Should -Be 'Absent'
                    $script:resource.Id | should -Be $null
                    $script:resource.Name | should -Be 'Servers'
                    $script:resource.Path | should -Be 'All Computers'
                }
            }

            Context 'The Computer Target Group is not in the desired state (specified name does not exist at any path).' {
                It 'Calling Get should return absent when Computer Target Group does not exist at any path.' {
                    $resource = Get-TargetResource -Name 'Domain Controllers' -Path 'All Computers'
                    $resource.Ensure | Should -Be 'Absent'
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.GetWsusServerSucceeded -f 'ServerName')
                    }
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.NotFoundComputerTargetGroup -f 'Domain Controllers', 'All Computers')
                    }

                }
            }

            Context 'The Computer Target Group is not in the desired state (specified name exists but not at the desired path).' {
                It 'Calling Get should return absent when Computer Target Group does not exist at the specified path.' {
                    $resource = Get-TargetResource -Name 'Desktops' -Path 'All Computers/Servers'
                    $resource.Ensure | Should -Be 'Absent'
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.NotFoundComputerTargetGroup -f 'Desktops', 'All Computers/Servers')
                    }
                }
            }

            Context 'The Computer Target Group is in the desired state (specified name exists with the desired path).' {
                It 'Calling Get should return present when Computer Target Group does exist at the specified path.' {
                    $resource = Get-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations'
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.FoundComputerTargetGroup -f `
                        'Desktops', 'All Computers/Workstations', '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1')
                    }
                    $resource.Ensure | Should -Be 'Present'
                    $resource.Id | Should -Be '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'

                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "MSFT_UpdateServicesComputerTargetGroup\Test-TargetResource." {
            Mock -CommandName Write-Verbose -MockWith {}

            Context 'The Computer Target Group "Desktops" is "Present" at Path "All Computers/Workstations" which is the desired state.' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure          = 'Present'
                        Name            = 'Desktops'
                        Path            = 'All Computers/Workstations'
                        Id              = '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                    }
                }

                It 'Test-TargetResource should return $true when Computer Target Resource is in the desired state.' {
                    $resource = Test-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations'
                    $resource | Should -Be $true
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceInDesiredState -f `
                        'Desktops', 'All Computers/Workstations', 'Present')
                    }
                }
            }

            Context 'The Computer Target Group "Desktops" is "Absent" at Path "All Computers/Workstations" which is the desired state (Present).' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure          = 'Absent'
                        Name            = 'Desktops'
                        Path            = 'All Computers/Workstations'
                        Id              = $null
                    }
                }

                It 'Test-TargetResource should return $true when Computer Target Resource is in the desired state.' {
                    $resource = Test-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations' -Ensure 'Absent'
                    $resource | Should -Be $true
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceInDesiredState -f `
                        'Desktops', 'All Computers/Workstations', 'Absent')
                    }
                }
            }

            Context 'The Computer Target Group "Desktops" is "Present" at Path "All Computers/Workstations" which is NOT the desired state.' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure          = 'Present'
                        Name            = 'Desktops'
                        Path            = 'All Computers/Workstations'
                        Id              = '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                    }
                }

                It 'Test-TargetResource should return $false when Computer Target Resource is NOT in the desired state.' {
                    $resource = Test-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations' -Ensure 'Absent'
                    $resource | Should -Be $false
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceNotInDesiredState -f `
                        'Desktops', 'All Computers/Workstations', 'Present')
                    }
                }
            }

            Context 'The Computer Target Group "Desktops" is "Absent" at Path "All Computers/Workstations" which is NOT the desired state (Present).' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure          = 'Absent'
                        Name            = 'Desktops'
                        Path            = 'All Computers/Workstations'
                        Id              = $null
                    }
                }

                It 'Test-TargetResource should return $false when Computer Target Resource is NOT in the desired state.' {
                    $resource = Test-TargetResource -Name 'Desktops' -Path 'All Computers/Workstations' -Ensure 'Present'
                    $resource | Should -Be $false
                    Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.ResourceNotInDesiredState -f `
                        'Desktops', 'All Computers/Workstations', 'Absent')
                    }
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "MSFT_UpdateServicesComputerTargetGroup\Set-TargetResource" {
            Mock -CommandName Write-Verbose -MockWith {}
            if (Test-Path -Path variable:script:resource) { Remove-Variable -Scope 'script' -Name 'resource' }

            Context 'An error occurs retrieving WSUS Server configuration information.' {
                Mock -CommandName Get-WsusServer -MockWith { throw 'An error occurred.' }

                It 'Calling Set should throw when an error occurrs retrieving WSUS Server information.' {
                    { $script:resource = Set-TargetResource -Name 'Servers' -Path 'All Computers'} | Should -Throw ($script:localizedData.WSUSConfigurationFailed)
                    $script:resource | Should -Be $null
                    Assert-MockCalled -CommandName Get-WsusServer -Exactly 1
                }
            }

            Context 'The WSUS Server is not yet configured.' {
                Mock -CommandName Get-WsusServer -MockWith {}

                It 'Calling Set should not throw when the WSUS Server is not yet configuration / cannot be found.' {
                    { $script:resource = Set-TargetResource -Name 'Servers' -Path 'All Computers'} | Should -Not -Throw
                    Assert-MockCalled -CommandName Write-Verbose  -ParameterFilter {
                        $message -eq $script:localizedData.GetWsusServerFailed
                    }
                    $script:resource | Should -Be $null
                }
            }

            Context 'The Parent of the Computer Target Group is not present and therefore the new group cannot be created.' {
                Mock -CommandName Write-Warning -MockWith {}

                It 'Calling Set where the Parent of the Computer Target Group does not exist generates a warning message.' {
                    { $script:resource = Set-TargetResource -Name 'Win10' -Path 'All Computers/Desktops'} | Should -Not -Throw
                    Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                        $message -eq ($script:localizedData.NotFoundParentComputerTargetGroup -f 'Desktops', `
                        'All Computers', 'Win10')
                    }
                }
            }

            Context 'The new Computer Target Group (at Root Level) is successfully created.' {
                It 'Calling Set where Computer Target Group (at Root Level) does not exist and Ensure is "Present" creates the required group.' {
                    # { $script:resource = Set-TargetResource -Name 'Virtual Servers' -Path 'All Computers'} | Should -Not -Throw
                    $script:resource = Set-TargetResource -Name 'Member Servers' -Path 'All Computers'
                    Assert-MockCalled Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.CreateComputerTargetGroupSuccess -f 'Member Servers', `
                        'All Computers')
                    }
                }
            }

            Context 'The new Computer Target Group is successfully created.' {
                It 'Calling Set where Computer Target Group does not exist and Ensure is "Present" creates the required group.' {
                    { $script:resource = Set-TargetResource -Name 'Database' -Path 'All Computers/Servers'} | Should -Not -Throw
                    Assert-MockCalled Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.CreateComputerTargetGroupSuccess -f 'Database', `
                        'All Computers/Servers')
                    }
                }
            }

            Context 'The new Computer Target Group is successfully deleted.' {
                It 'Calling Set where Computer Target Group exists and Ensure is "Absent" deletes the required group.' {
                    { $script:resource = Set-TargetResource -Name 'Web' -Path 'All Computers/Servers' -Ensure 'Absent' } | Should -Not -Throw
                    Assert-MockCalled Write-Verbose -ParameterFilter {
                        $message -eq ($script:localizedData.DeleteComputerTargetGroupSuccess -f 'Web', `
                        'f4aa59c7-e6a0-4e6d-97b0-293d00a0dc60', 'All Computers/Servers')
                    }
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
