configuration allProducts {
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName UpdateServicesDsc

    Node $NodeName
    {
        # Install the IIS role
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
            Languages = @('en','fr')
            Products = @(
                '*'
            )
            Classifications = @(
                'E6CF1350-C01B-414D-A61F-263D14D133B4', #CriticalUpdates
                'E0789628-CE08-4437-BE74-2495B842F43B', #DefinitionUpdates
                '0FA1201D-4330-4FA8-8AE9-B877473B6441', #SecurityUpdates
                '68C5B0A3-D1A6-4553-AE49-01D3A7827828', #ServicePacks
                '28BC880E-0592-4CBF-8F95-C79B17911D5F' #UpdateRollups
            )
            SynchronizeAutomatically = $true
            SynchronizeAutomaticallyTimeOfDay = '15:30:00'
            ClientTargetingMode = "Client"
        }
    }
}

configuration defaultProducts {
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName UpdateServicesDsc

    Node $NodeName
    {
        # Install the IIS role
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
            Languages = @('en','fr')
            Classifications = @(
                'E6CF1350-C01B-414D-A61F-263D14D133B4', #CriticalUpdates
                'E0789628-CE08-4437-BE74-2495B842F43B', #DefinitionUpdates
                '0FA1201D-4330-4FA8-8AE9-B877473B6441', #SecurityUpdates
                '68C5B0A3-D1A6-4553-AE49-01D3A7827828', #ServicePacks
                '28BC880E-0592-4CBF-8F95-C79B17911D5F' #UpdateRollups
            )
            SynchronizeAutomatically = $true
            SynchronizeAutomaticallyTimeOfDay = '15:30:00'
            ClientTargetingMode = "Client"
        }
    }
}

configuration onlyOneProduct {
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName UpdateServicesDsc

    Node $NodeName
    {
        # Install the IIS role
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
            Languages = @('en','fr')
            Products = @(
                'Windows Server 2019'
            )
            Classifications = @(
                'E6CF1350-C01B-414D-A61F-263D14D133B4', #CriticalUpdates
                'E0789628-CE08-4437-BE74-2495B842F43B', #DefinitionUpdates
                '0FA1201D-4330-4FA8-8AE9-B877473B6441', #SecurityUpdates
                '68C5B0A3-D1A6-4553-AE49-01D3A7827828', #ServicePacks
                '28BC880E-0592-4CBF-8F95-C79B17911D5F' #UpdateRollups
            )
            SynchronizeAutomatically = $true
            SynchronizeAutomaticallyTimeOfDay = '15:30:00'
            ClientTargetingMode = "Client"
        }
    }
}

configuration wildcardInProduct {
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName UpdateServicesDsc

    Node $NodeName
    {
        # Install the IIS role
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
            Languages = @('en','fr')
            Products = @(
                'Windows Server*'
            )
            Classifications = @(
                'E6CF1350-C01B-414D-A61F-263D14D133B4', #CriticalUpdates
                'E0789628-CE08-4437-BE74-2495B842F43B', #DefinitionUpdates
                '0FA1201D-4330-4FA8-8AE9-B877473B6441', #SecurityUpdates
                '68C5B0A3-D1A6-4553-AE49-01D3A7827828', #ServicePacks
                '28BC880E-0592-4CBF-8F95-C79B17911D5F' #UpdateRollups
            )
            SynchronizeAutomatically = $true
            SynchronizeAutomaticallyTimeOfDay = '15:30:00'
            ClientTargetingMode = "Client"
        }
    }
}
