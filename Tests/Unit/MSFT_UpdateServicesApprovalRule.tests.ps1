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
    $script:dscResourceName = 'MSFT_UpdateServicesApprovalRule'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/ImitateUpdateServicesModule.psm1') -Force

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

    $script:WsusServer = [pscustomobject]@{
        Name = 'ServerName'
    }

    $DSCSetValues = @{
        Name = $script:WsusServer.Name
        Classifications = "00000000-0000-0000-0000-0000testguid"
        Products = "Product"
        ComputerGroups = "Computer Target Group"
        Enabled = $true
    }

    $DSCTestValues = @{
        Name = $script:WsusServer.Name
        Classifications = "00000000-0000-0000-0000-0000testguid"
        Products = "Product"
        ComputerGroups = "Computer Target Group"
        Enabled = $true
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
Describe "MSFT_UpdateServicesApprovalRule\Get-TargetResource" {
    BeforeAll {
        Mock -CommandName New-InvalidOperationException
        Mock -CommandName New-InvalidResultException
        Mock -CommandName New-ArgumentException
    }

    Context 'When server is configured' {

        it 'Should not throw when calling Get-TargetResource' {
            $Script:resource = Get-TargetResource -Name $script:WsusServer.Name -Verbose
        }

        It "Should return Ensure as Present" {
            $Script:resource.Ensure | should -Be 'Present'
        }

        It "Should return correct Classifications" {
            $Script:resource.Classifications | should -Be $DSCSetValues.Classifications
        }

        It "Should return correct Products" {
            $Script:resource.Products | should -Be $DSCSetValues.Products
        }

        It "Should return correct ComputerGroups" {
            $Script:resource.ComputerGroups | should -Be $DSCSetValues.ComputerGroups
        }

        It "Should return correct Enabled state" {
            $Script:resource.Enabled | should -Be $DSCSetValues.Enabled
        }

        It "mocks were not called" {
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-ArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }

    }

    Context 'When server should not be configured' {

        It 'Should not throw when calling Get-TargetResource' {
            Mock -CommandName Get-WSUSServer
            $Script:resource = Get-TargetResource -Name $script:WsusServer.Name -Verbose
        }

        It "Should return Ensure as Absent" {
            $Script:resource.Ensure | should -Be 'Absent'
        }

        It "Should return empty Classifications" {
            $Script:resource.Classifications | should -BeNullOrEmpty
        }

        It "Should return empty Products" {
            $Script:resource.Products | should -BeNullOrEmpty
        }

        It "Should return empty ComputerGroups" {
            $Script:resource.ComputerGroups | should -BeNullOrEmpty
        }

        It "Should return empty Enabled state" {
            $Script:resource.Enabled | should -BeNullOrEmpty
        }

        It "mocks were not called" {
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-ArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }

    Context 'When approval rule does not exist' {

        It 'Should not throw when calling Get-TargetResource with non-existent rule' {
            $Script:resource = Get-TargetResource -Name 'Foo' -Verbose
        }

        It "Should return Ensure as Absent" {
            $Script:resource.Ensure | should -Be 'Absent'
        }

        It "Should return null Classifications" {
            $Script:resource.Classifications | should -Be $null
        }

        It "Should return null Products" {
            $Script:resource.Products | should -Be $null
        }

        It "Should return null ComputerGroups" {
            $Script:resource.ComputerGroups | should -Be $null
        }

        It "Should return null Enabled state" {
            $Script:resource.Enabled | should -Be $null
        }

        It "mocks were not called" {
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-ArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }
}
#endregion

#region Function Test-TargetResource
Describe "MSFT_UpdateServicesApprovalRule\Test-TargetResource" {
    Context 'When server is in correct state (Ensure=Present)' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure','Present')
            $script:result = $null
        }

        It 'Should not throw when calling Test-TargetResource' {
            $script:result = Test-TargetResource @DSCTestValues -Verbose
        }

        It "Should return true when state is correct" {
            $script:result | should -BeTrue
        }
    }

    Context 'When server should not be configured (Ensure=Absent) but is' {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure','Absent')
            $script:result = $null
        }

        It 'Should not throw when calling Test-TargetResource' {
            $script:result = Test-TargetResource @DSCTestValues -Verbose
        }

        It "Should return false when Ensure is Absent but resource exists" {
            $script:result | should -BeFalse
        }
    }

    Context "When setting has drifted" {
        BeforeAll {
            $DSCTestValues.Remove('Ensure')
            $DSCTestValues.Add('Ensure','Present')
        }

        $settingsList = 'Classifications','Products','ComputerGroups'
        Context 'When <_> property is drifted' -Foreach $settingsList {
            It 'Should not throw when calling Test-TargetResource with drifted property' {
                $DSCTestValuesDrifted = $DSCTestValues.Clone()
                $DSCTestValuesDrifted["$_"] = 'foo'
                $script:result = $null
                $script:result = Test-TargetResource @DSCTestValuesDrifted -Verbose
            }

            It "Should return false when property has drifted" {
                $script:result | should -BeFalse
            }
        }
    }
}
#endregion

#region Function Set-TargetResource
Describe "MSFT_UpdateServicesApprovalRule\Set-TargetResource" {
    BeforeAll {
        $Collection = [pscustomobject]@{}
        $Collection | Add-Member -MemberType ScriptMethod -Name Add -Value {}
    }

    Context 'When server is already in correct state (resource is idempotent)' {
        BeforeAll {
            Mock New-Object -mockwith {$Collection}
            Mock Get-WsusProduct
            Mock -CommandName New-InvalidOperationException
            Mock -CommandName New-InvalidResultException
            Mock -CommandName New-ArgumentException
        }

        It 'Should not throw when running on a properly configured server' {
            Set-TargetResource @DSCSetValues -Verbose

            #mock were called
            Should -Invoke New-Object -Exactly 3
            Should -Invoke Get-WsusProduct -Times 1 -Exactly

            #mock are not called
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-ArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }

    Context 'When server is not in correct state (resource takes action)' {
        BeforeAll {
            Mock New-Object -mockwith {$Collection}
            Mock Get-WsusProduct
            Mock -CommandName New-InvalidOperationException
            Mock -CommandName New-InvalidResultException
            Mock -CommandName New-ArgumentException
            Mock Test-TargetResource -mockwith {$true}
        }

        It 'Should not throw when running on an incorrectly configured server' {
            Set-TargetResource -Name "Foo" -Classification "00000000-0000-0000-0000-0000testguid" -Verbose

            #mock were called
            Should -Invoke New-Object -Exactly 3
            Should -Invoke Test-TargetResource -Times 1 -Exactly
            Should -Invoke Get-WsusProduct -Times 1 -Exactly

            #mock are not called
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-ArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }

    Context 'When server should not be configured (Ensure=Absent)' {
        BeforeAll {
            Mock New-Object -mockwith {$Collection}
            Mock Get-WsusProduct
            Mock -CommandName New-InvalidOperationException
            Mock -CommandName New-InvalidResultException
            Mock -CommandName New-ArgumentException
            Mock Test-TargetResource -mockwith {$true}
        }

        It 'Should not throw when removing approval rule'{
            Set-TargetResource @DSCSetValues -Ensure Absent -Verbose

            #mock were called
            Should -Invoke Test-TargetResource -Times 1 -Exactly

            #mock are not called
            Should -Invoke New-Object -Exactly 0
            Should -Invoke Get-WsusProduct -Exactly 0
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-ArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }

    Context 'When server is in correct state and synchronize is included' {
        BeforeAll {
            Mock New-Object -mockwith {$Collection}
            Mock Get-WsusProduct
            Mock -CommandName New-InvalidOperationException
            Mock -CommandName New-InvalidResultException
            Mock -CommandName New-ArgumentException
            Mock Test-TargetResource -mockwith {$true}
        }

        It 'Should not throw when synchronizing on a properly configured server' {
            Set-TargetResource @DSCSetValues -Synchronize $true -Verbose

            #mock were called
            Should -Invoke New-Object -Exactly 3
            Should -Invoke Test-TargetResource -Times 1 -Exactly
            Should -Invoke Get-WsusProduct -Times 1 -Exactly

            #mock are not called
            Should -Invoke New-InvalidResultException -Exactly 0
            Should -Invoke New-ArgumentException -Exactly 0
            Should -Invoke New-InvalidOperationException -Exactly 0
        }
    }
}
#endregion
