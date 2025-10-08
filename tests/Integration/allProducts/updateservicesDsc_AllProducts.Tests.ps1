Describe "Tests installation with all products" {
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
            {$script:wuServer = Get-WsusServer}| Should -Not -Throw
        }

        It "Should product are correctly configured" {
            $AllProducts = $script:wuServer.GetUpdateCategories().Title | Where-Object {$_ -in @('Windows','Office')}

            ($AllProducts | Measure-Object).Count | Should -Be ($script:wuServer.GetSubscription().GetUpdateCategories().Title | Measure-Object ).Count

            foreach ($ProductServer in $AllProductsServer)
            {
                $script:wuServer.GetSubscription().GetUpdateCategories().Title | Should -Contain $ProductServer
            }
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
