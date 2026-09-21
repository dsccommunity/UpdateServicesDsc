# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
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
    $script:subModuleName = 'PDT'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force
}

Describe 'PDT\Start-Win32Process' {
    Context 'When the process is already running' {
        BeforeAll {
            Mock -CommandName Get-Win32Process -MockWith {
                return @{
                    ProcessId = 1234
                }
            }

            Mock -CommandName Start-Process
        }

        It 'Should return that the process was already started, without starting it again' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Start-Win32Process -Path 'C:\Windows\System32\cmd.exe' |
                    Should -Be ($script:localizedData.ProcessAlreadyStarted -f 'C:\Windows\System32\cmd.exe', 1234)
            }

            Should -Invoke -CommandName Start-Process -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the process is started successfully' {
        BeforeAll {
            $script:getWin32ProcessCallCount = 0

            Mock -CommandName Get-Win32Process -MockWith {
                $script:getWin32ProcessCallCount++

                # The process does not exist until it has been started
                if ($script:getWin32ProcessCallCount -eq 1)
                {
                    return @()
                }

                return @{
                    ProcessId = 1234
                }
            }

            Mock -CommandName Start-Process
            Mock -CommandName Wait-Win32ProcessStart -MockWith { $true }
        }

        It 'Should return that the process was started' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Start-Win32Process -Path 'C:\Windows\System32\cmd.exe' |
                    Should -Be ($script:localizedData.ProcessStarted -f 'C:\Windows\System32\cmd.exe', 1234)
            }

            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Wait-Win32ProcessStart -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the process does not start within the timeout' {
        BeforeAll {
            Mock -CommandName Get-Win32Process -MockWith { return @() }
            Mock -CommandName Start-Process
            Mock -CommandName Wait-Win32ProcessStart -MockWith { $false }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = $script:localizedData.ProcessFailedToStartError -f @('C:\Windows\System32\cmd.exe', 'test')

                { Start-Win32Process -Path 'C:\Windows\System32\cmd.exe' -Arguments 'test' } |
                    Should -Throw -ExpectedMessage ('*' + $errorMessage + '*')
            }

            Should -Invoke -CommandName Wait-Win32ProcessStart -Exactly -Times 1 -Scope It
        }
    }

    Context 'When starting the process returns an error' {
        BeforeAll {
            Mock -CommandName Get-Win32Process -MockWith { return @() }
            Mock -CommandName Start-Process -MockWith { return 'Some error' }
            Mock -CommandName Wait-Win32ProcessStart
        }

        It 'Should throw the returned error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Start-Win32Process -Path 'C:\Windows\System32\cmd.exe' } | Should -Throw -ExpectedMessage '*Some error*'
            }

            Should -Invoke -CommandName Wait-Win32ProcessStart -Exactly -Times 0 -Scope It
        }
    }
}
