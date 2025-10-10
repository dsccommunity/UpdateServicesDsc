Describe "Basic tests" {
    Context "Windows Feature are correctly installed" {
        $TestCases = @{
            Feature = 'UpdateServices'
            Installed = $True
        },
        @{
            Feature = 'UpdateServices-RSAT'
            Installed = $True
        }

        It "Should <feature> be installed" -TestCases $TestCases {
            (Get-WindowsFeature -Name $Feature).Installed | Should -Be $Installed
        }
    }

    Context "Wsus service is correctly configured" {
        It "Should can the informations of update service" {
            $script:wuServer = Get-WsusServer
        }

        It "Should product are correctly configured" {
            $script:wuServer.GetSubscription().GetUpdateCategories().Title | Should -Contain "Windows Server 2019"
            ($script:wuServer.GetSubscription().GetUpdateCategories().Title | Measure-Object ).Count | Should -Be 1
        }

        $TestCases = @{Classification = "Critical Updates"},
            @{Classification = "Definition Updates"},
            @{Classification = "Security Updates"},
            @{Classification = "Service Packs"},
            @{Classification = "Update Rollups"}

        It "Should have <Classification> in classifications value" -TestCases $TestCases{
            $script:wuServer.GetSubscription().GetUpdateClassifications().Title | Should -Contain $Classification
        }
    }
}
