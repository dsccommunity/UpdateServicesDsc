Configuration WSUSDsc_Config
{
    Import-DscResource -ModuleName WSUSDsc

    Node $AllNodes.NodeName
    { 

        WindowsFeature WSUS
        {
            Ensure = 'Present'
            Name = 'UpdateServices'
        }

        WindowsFeature WSUSRSAT
        {
            Ensure = 'Present'
            Name = 'UpdateServices-RSAT'
        }

        WSUSServer 'WSUS'
            {
                DependsOn = @(
                    '[WindowsFeature]WSUS'
                )
                Ensure = 'Present'
                ContentDir = 'C:\WSUS'
                Languages = 'en'
                Products = @(
                    'Forefront Endpoint Protection 2010',
                    'Windows Server 2012 R2'
                )
                Classifications = @(
                    'E6CF1350-C01B-414D-A61F-263D14D133B4', #CriticalUpdates
                    'E0789628-CE08-4437-BE74-2495B842F43B', #DefinitionUpdates
                    '0FA1201D-4330-4FA8-8AE9-B877473B6441', #SecurityUpdates
                    '68C5B0A3-D1A6-4553-AE49-01D3A7827828', #ServicePacks
                    '28BC880E-0592-4CBF-8F95-C79B17911D5F' #UpdateRollUps
                )
                SynchronizeAutomatically = $true
                SynchronizeAutomaticallyTimeOfDay = '15:30:00'
           }
            WSUSApprovalRule 'DefinitionUpdates'
           {
                DependsOn = '[WSUSServer]WSUS'
                Name = 'Definition Updates'
                Classifications = 'E0789628-CE08-4437-BE74-2495B842F43B'
                Enabled = $true
                RunRuleNow = $true
            }

           WSUSApprovalRule 'CriticalUpdates'
           {
                DependsOn = '[WSUSServer]WSUS'
                Name = 'Critical Updates'
                Classifications = 'E6CF1350-C01B-414D-A61F-263D14D133B4'
                Enabled = $true
                RunRuleNow = $true
            }
           
           WSUSApprovalRule 'SecurityUpdates'
           {
                DependsOn = '[WSUSServer]WSUS'
                Name = 'Security Updates'
                Classifications = '0FA1201D-4330-4FA8-8AE9-B877473B6441'
                Enabled = $true
                RunRuleNow = $true
            }
           
           WSUSApprovalRule 'ServicePacks'
           {
                DependsOn = '[WSUSServer]WSUS'
                Name = 'Service Packs'
                Classifications = '68C5B0A3-D1A6-4553-AE49-01D3A7827828'
                Enabled = $true
                RunRuleNow = $true
            }

            WSUSApprovalRule 'UpdateRollUps'
           {
                DependsOn = '[WSUSServer]WSUS'
                Name = 'Update RollUps'
                Classifications = '28BC880E-0592-4CBF-8F95-C79B17911D5F'
                Enabled = $true
                RunRuleNow = $true
            }

            WSUSCleanup 'WSUS'
            {
                DependsOn = '[WSUSServer]WSUS'
                Ensure = 'Present'
                DeclineExpiredUpdates = $true
                DeclineSupersededUpdates = $true
                CleanupObsoleteUpdates = $true
                CleanupUnneededContentFiles = $true
            } 
        }
}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            #For use with Azure Automation DSC
            #PSDscAllowPlainTextPassword = $True
        },
        @{
            NodeName = "localhost"
        }
    )
}
