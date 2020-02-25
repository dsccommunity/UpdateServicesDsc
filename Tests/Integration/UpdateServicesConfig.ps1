Configuration UpdateServicesConfig
{
    Import-DscResource -ModuleName UpdateServicesDsc
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $AllNodes.NodeName
    {

        WindowsFeature UpdateServices
        {
            Ensure = 'Present'
            Name = 'UpdateServices'
        }

        WindowsFeature UpdateServicesRSAT
        {
            Ensure = 'Present'
            Name = 'UpdateServices-RSAT'
            IncludeAllSubFeature =  $True
        }

        UpdateServicesServer 'UpdateServices'
            {
                DependsOn = @(
                    '[WindowsFeature]UpdateServices'
                )
                Ensure = 'Present'
                ContentDir = 'C:\WSUS'
                Languages = @('en','fr','es')
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
                ClientTargetingMode = "Client"
           }
            UpdateServicesApprovalRule 'DefinitionUpdates'
           {
                DependsOn = '[UpdateServicesServer]UpdateServices'
                Name = 'Definition Updates'
                Classifications = 'E0789628-CE08-4437-BE74-2495B842F43B'
                Enabled = $true
                RunRuleNow = $true
            }

           UpdateServicesApprovalRule 'CriticalUpdates'
           {
                DependsOn = '[UpdateServicesServer]UpdateServices'
                Name = 'Critical Updates'
                Classifications = 'E6CF1350-C01B-414D-A61F-263D14D133B4'
                Enabled = $true
                RunRuleNow = $true
            }

           UpdateServicesApprovalRule 'SecurityUpdates'
           {
                DependsOn = '[UpdateServicesServer]UpdateServices'
                Name = 'Security Updates'
                Classifications = '0FA1201D-4330-4FA8-8AE9-B877473B6441'
                Enabled = $true
                RunRuleNow = $true
            }

           UpdateServicesApprovalRule 'ServicePacks'
           {
                DependsOn = '[UpdateServicesServer]UpdateServices'
                Name = 'Service Packs'
                Classifications = '68C5B0A3-D1A6-4553-AE49-01D3A7827828'
                Enabled = $true
                RunRuleNow = $true
            }

            UpdateServicesApprovalRule 'UpdateRollUps'
           {
                DependsOn = '[UpdateServicesServer]UpdateServices'
                Name = 'Update RollUps'
                Classifications = '28BC880E-0592-4CBF-8F95-C79B17911D5F'
                Enabled = $true
                RunRuleNow = $true
            }

            UpdateServicesCleanup 'UpdateServices'
            {
                DependsOn = '[UpdateServicesServer]UpdateServices'
                Ensure = 'Present'
                DeclineExpiredUpdates = $true
                DeclineSupersededUpdates = $true
                CleanupObsoleteUpdates = $true
                CleanupUnneededContentFiles = $true
            }
        }
}

# Example command to compile in Azure Automation DSC
# Start-AzureRmAutomationDscCompilationJob -ResourceGroupName <ResourceGroupName> -AutomationAccountName <AutomationAccountName> -ConfigurationName "UpdateServicesConfig"
