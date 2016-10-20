# DSC resource to initialize and configure WSUS Server.

# Classifications ID reference...
# 
# Applications       = 5C9376AB-8CE6-464A-B136-22113DD69801
# Connectors         = 434DE588-ED14-48F5-8EED-A15E09A991F6
# Critical Updates   = E6CF1350-C01B-414D-A61F-263D14D133B4
# Definition Updates = E0789628-CE08-4437-BE74-2495B842F43B
# Developer Kits     = E140075D-8433-45C3-AD87-E72345B36078
# Feature Packs      = B54E7D24-7ADD-428F-8B75-90A396FA584F
# Guidance           = 9511D615-35B2-47BB-927F-F73D8E9260BB
# Security Updates   = 0FA1201D-4330-4FA8-8AE9-B877473B6441
# Service Packs      = 68C5B0A3-D1A6-4553-AE49-01D3A7827828
# Tools              = B4832BD8-E735-4761-8DAF-37F882276DAB
# Update Rollups     = 28BC880E-0592-4CBF-8F95-C79B17911D5F
# Updates            = CD5FFD1E-E932-4E3A-BF74-18BF0B1BBD83

$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\WSUSHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Write-Verbose 'Getting WSUSServer'
    try
    {
        if($WsusServer = Get-WsusServer)
        {
            $Ensure = 'Present'
        }
        else
        {
            $Ensure = 'Absent'
        }
    }
    catch
    {
        $Ensure = 'Absent'
    }

    Write-Verbose "WSUSServer is $Ensure"
    if($Ensure -eq 'Present')
    {
        Write-Verbose 'Getting WSUSServer configuration'
        $WsusConfiguration = $WsusServer.GetConfiguration()
        Write-Verbose 'Getting WSUSServer subscription'
        $WsusSubscription = $WsusServer.GetSubscription()
            
        Write-Verbose 'Getting WSUSServer SQL Server'
        $SQLServer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -Name 'SQLServerName').SQLServerName
        Write-Verbose "WSUSServer SQL Server is $SQLServer"
        Write-Verbose 'Getting WSUSServer content directory'
        $ContentDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' -Name 'ContentDir').ContentDir
        Write-Verbose "WSUSServer content directory is $ContentDir"
        
        Write-Verbose 'Getting WSUSServer update improvement program'
        $UpdateImprovementProgram = $WsusConfiguration.MURollupOptin
        Write-Verbose "WSUSServer content update improvement program is $UpdateImprovementProgram"

        if(!$WsusConfiguration.SyncFromMicrosoftUpdate)
        {
            Write-Verbose 'Getting WSUSServer upstream server'
            $UpstreamServerName = $WsusConfiguration.UpstreamWsusServerName
            $UpstreamServerPort = $WsusConfiguration.UpstreamWsusServerPortNumber
            $UpstreamServerSSL = $WsusConfiguration.UpstreamWsusServerUseSsl
            $UpstreamServerReplica = $WsusConfiguration.IsReplicaServer
            Write-Verbose "WSUSServer upstream server is $UpstreamServerName, port $UpstreamServerPort, use SSL $UpstreamServerSSL, replica $UpstreamServerReplica"
        }
        else
        {
            $UpstreamServerName = ""
            $UpstreamServerPort = $null
            $UpstreamServerSSL = $null
            $UpstreamServerReplica = $null
        }
   
        if($WsusConfiguration.UseProxy)
        {
            Write-Verbose 'Getting WSUSServer proxy server'
            $ProxyServerName = $WsusConfiguration.ProxyName
            $ProxyServerPort = $WsusConfiguration.ProxyServerPort
            $ProxyServerBasicAuthentication = $WsusConfiguration.AllowProxyCredentialsOverNonSsl
            if (!($WsusConfiguration.AnonymousProxyAccess))
            {
                $ProxyServerCredentialUsername = "$($WsusConfiguration.ProxyUserDomain)\$($WsusConfiguration.ProxyUserName)".Trim('\')
            }
            Write-Verbose "WSUSServer proxy server is $ProxyServerName, port $ProxyServerPort, basic authentication $ProxyServerBasicAuthentication"
        }
        else
        {
            $ProxyServerName = ""
            $ProxyServerPort = $null
            $ProxyServerBasicAuthentication = $null
        }

        Write-Verbose 'Getting WSUSServer languages'
        if($WsusConfiguration.AllUpdateLanguagesEnabled)
        {
            $Languages = @("*")
        }
        else
        {
            $Languages = $WsusConfiguration.GetEnabledUpdateLanguages()
        }
        #Write-Verbose "WSUSServer languages are $Languages"

        Write-Verbose 'Getting WSUSServer classifications'
        $Classifications = @($WsusSubscription.GetUpdateClassifications().ID.Guid)
        if((Compare-Object -ReferenceObject ($Classifications | Sort-Object -Unique) -DifferenceObject (($WsusServer.GetUpdateClassifications().ID.Guid) | Sort-Object -Unique) -SyncWindow 0) -eq $null)
        {
            $Classifications = @("*")
        }
        Write-Verbose "WSUSServer classifications are $Classifications"
        Write-Verbose 'Getting WSUSServer products'
        $Products = @($WsusSubscription.GetUpdateCategories().Title)
        if((Compare-Object -ReferenceObject ($Products | Sort-Object -Unique) -DifferenceObject (($WsusServer.GetUpdateCategories().Title) | Sort-Object -Unique) -SyncWindow 0) -eq $null)
        {
            $Products = @("*")
        }
        Write-Verbose "WSUSServer products are $Products"
        Write-Verbose 'Getting WSUSServer synchronization settings'
        $SynchronizeAutomatically = $WsusSubscription.SynchronizeAutomatically
        Write-Verbose "WSUSServer synchronize automatically is $SynchronizeAutomatically"
        $SynchronizeAutomaticallyTimeOfDay = $WsusSubscription.SynchronizeAutomaticallyTimeOfDay
        Write-Verbose "WSUSServer synchronize automatically time of day is $SynchronizeAutomaticallyTimeOfDay"
        $SynchronizationsPerDay = $WsusSubscription.NumberOfSynchronizationsPerDay
        Write-Verbose "WSUSServer number of synchronizations per day is $SynchronizationsPerDay"
    }

    $returnValue = @{
        Ensure = $Ensure
        SQLServer = $SQLServer
        ContentDir = $ContentDir
        UpdateImprovementProgram = $UpdateImprovementProgram
        UpstreamServerName = $UpstreamServerName
        UpstreamServerPort = $UpstreamServerPort
        UpstreamServerSSL = $UpstreamServerSSL
        UpstreamServerReplica = $UpstreamServerReplica
        ProxyServerName = $ProxyServerName
        ProxyServerPort = $ProxyServerPort
        ProxyServerCredentialUsername = $ProxyServerCredentialUsername
        ProxyServerBasicAuthentication = $ProxyServerBasicAuthentication
        Languages = $Languages
        Products = $Products
        Classifications = $Classifications
        SynchronizeAutomatically = $SynchronizeAutomatically
        SynchronizeAutomaticallyTimeOfDay = $SynchronizeAutomaticallyTimeOfDay
        SynchronizationsPerDay = $SynchronizationsPerDay
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [System.String]
        $SQLServer,

        [System.String]
        $ContentDir = "%SystemDrive%\WSUS",

        [System.Boolean]
        $UpdateImprovementProgram,

        [System.String]
        $UpstreamServerName,

        [System.UInt16]
        $UpstreamServerPort = 8530,

        [System.Boolean]
        $UpstreamServerSSL,

        [System.Boolean]
        $UpstreamServerReplica,

        [System.String]
        $ProxyServerName,

        [System.UInt16]
        $ProxyServerPort = 80,

        [System.Management.Automation.PSCredential]
        $ProxyServerCredential,

        [System.Boolean]
        $ProxyServerBasicAuthentication,

        [System.String[]]
        $Languages = "*",

        [System.String[]]
        $Products = @("Windows","Office"),

        [System.String[]]
        $Classifications = @('E6CF1350-C01B-414D-A61F-263D14D133B4','E0789628-CE08-4437-BE74-2495B842F43B','0FA1201D-4330-4FA8-8AE9-B877473B6441'),

        [System.Boolean]
        $SynchronizeAutomatically,

        [System.String]
        $SynchronizeAutomaticallyTimeOfDay,

        [System.UInt16]
        $SynchronizationsPerDay = 1,

        [System.Boolean]
        $Synchronize
    )

    # Is WSUS configured?
    try
    {
        if($WsusServer = Get-WsusServer)
        {
            $PostInstall = $false
        }
    }
    catch
    {
        $PostInstall = $true
    }

    # Complete initial confiugration
    if($PostInstall)
    {
        Write-Verbose "Running WSUS postinstall"

        Import-Module $PSScriptRoot\..\..\PDT.psm1

        $Path = "$($env:ProgramFiles)\Update Services\Tools\WsusUtil.exe"
        $Path = ResolvePath $Path
        Write-Verbose "Path: $Path"

        $Arguments = "postinstall "
        if($PSBoundParameters.ContainsKey('SQLServer'))
        {
            $Arguments += "SQL_INSTANCE_NAME=$SQLServer "
        }
        $Arguments += "CONTENT_DIR=$([Environment]::ExpandEnvironmentVariables($ContentDir))"

        Write-Verbose "Arguments: $Arguments"

        if ($SetupCredential)
        {
            $Process = StartWin32Process -Path $Path -Arguments $Arguments -Credential $SetupCredential
            Write-Verbose $Process
            WaitForWin32ProcessEnd -Path $Path -Arguments $Arguments
        }
        else 
        {
            $Process = StartWin32Process -Path $Path -Arguments $Arguments
            Write-Verbose $Process
            WaitForWin32ProcessEnd -Path $Path -Arguments $Arguments        
        }
    }

    # Get WSUS server
    try
    {
        if($WsusServer = Get-WsusServer)
        {
            $Wsus = $true
        }
    }
    catch
    {
        $Wsus = $false

        throw New-TerminatingError -ErrorType WSUSConfigurationFailed
    }

    # Configure WSUS
    if($Wsus)
    {
        Write-Verbose "Configuring WSUS"

        # Get configuration and make sure that the configuration can be saved before continuing
        $WsusConfiguration = $WsusServer.GetConfiguration()
        $WsusSubscription = $WsusServer.GetSubscription()
        Write-Verbose "Check for previous configuration change"
        SaveWsusConfiguration

        # Configure Update Improvement Program
        Write-Verbose "Configuring WSUS Update Improvement Program"
        $WsusConfiguration.MURollupOptin = $UpdateImprovementProgram

        # Configure Upstream Server
        if($PSBoundParameters.ContainsKey('UpstreamServerName'))
        {
            Write-Verbose "Configuring WSUS Upstream Server"
            $WsusConfiguration.SyncFromMicrosoftUpdate = $false
            $WsusConfiguration.UpstreamWsusServerName = $UpstreamServerName
            $WsusConfiguration.UpstreamWsusServerPortNumber = $UpstreamServerPort
            $WsusConfiguration.UpstreamWsusServerUseSsl = $UpstreamServerSSL
            $WsusConfiguration.IsReplicaServer = $UpstreamServerReplica
        }
        else
        {
            Write-Verbose "Configuring WSUS for Microsoft Update"
            $WsusConfiguration.SyncFromMicrosoftUpdate = $true
        }

        # Configure Proxy Server
        if($PSBoundParameters.ContainsKey('ProxyServerName'))
        {
            Write-Verbose "Configuring WSUS proxy server"
            $WsusConfiguration.UseProxy = $true
            $WsusConfiguration.ProxyName = $ProxyServerName
            $WsusConfiguration.ProxyServerPort = $ProxyServerPort
            if($PSBoundParameters.ContainsKey('ProxyServerCredential'))
            {
                Write-Verbose "Configuring WSUS proxy server credential"
                $WsusConfiguration.ProxyUserDomain = $ProxyServerCredential.GetNetworkCredential().Domain
                $WsusConfiguration.ProxyUserName = $ProxyServerCredential.GetNetworkCredential().UserName
                $WsusConfiguration.SetProxyPassword($ProxyServerCredential.GetNetworkCredential().Password)
                $WsusConfiguration.AllowProxyCredentialsOverNonSsl = $ProxyServerBasicAuthentication
                $WsusConfiguration.AnonymousProxyAccess = $false
            }
            else
            {
                Write-Verbose "Removing WSUS proxy server credential"
                $WsusConfiguration.AnonymousProxyAccess = $true
            }
        }
        else
        {
            Write-Verbose "Configuring WSUS no proxy server"
            $WsusConfiguration.UseProxy = $false
        }

        #Languages
        Write-Verbose "Setting WSUS languages"
        if($Languages -eq "*")
        {
            $WsusConfiguration.AllUpdateLanguagesEnabled = $true
        }
        else
        {
            $WsusConfiguration.AllUpdateLanguagesEnabled = $false
            $WsusConfiguration.SetEnabledUpdateLanguages($Languages)
        }

        # Save configuration before initial sync
        SaveWsusConfiguration

        # Post Install
        if($PostInstall)
        {
            Write-Verbose "Removing default products and classifications before initial sync"
            foreach($Product in ($WsusServer.GetSubscription().GetUpdateCategories().Title))
            {
                Get-WsusProduct | Where-Object {$_.Product.Title -eq $Product} | Set-WsusProduct -Disable
            }
            foreach($Classification in ($WsusServer.GetSubscription().GetUpdateClassifications().ID.Guid))
            {
                Get-WsusClassification | Where-Object {$_.Classification.ID -eq $Classification} | Set-WsusClassification -Disable
            }

            if($Synchronize)
            {
                Write-Verbose "Running WSUS initial synchronization online"
                $WsusServer.GetSubscription().StartSynchronizationForCategoryOnly()
                while($WsusServer.GetSubscription().GetSynchronizationStatus() -eq 'Running')
                {
                    Start-Sleep 1
                }

                if($WsusServer.GetSubscription().GetSynchronizationHistory()[0].Result -eq 'Succeeded')
                {
                    Write-Verbose "Initial WSUS synchronization succeeded"
                    $WsusConfiguration.OobeInitialized = $true
                    SaveWsusConfiguration
                }
                else
                {
                    Write-Verbose "Initial WSUS synchronization failed"
                }
            }
            else
            {
                Write-Verbose "Running WSUS initial synchronization offline"

                $TempFile = [IO.Path]::GetTempFileName()

                $CABPath = Join-Path -Path $PSScriptRoot -ChildPath "\WSUS.cab"

                $Arguments = "import "
                $Arguments += "`"$CABPath`" $TempFile"

                Write-Verbose "Arguments: $Arguments"

                if ($SetupCredential)
                {
                    $Process = StartWin32Process -Path $Path -Arguments $Arguments -Credential $SetupCredential
                    Write-Verbose $Process
                    WaitForWin32ProcessEnd -Path $Path -Arguments $Arguments
                }
                else 
                {
                    $Process = StartWin32Process -Path $Path -Arguments $Arguments
                    Write-Verbose $Process
                    WaitForWin32ProcessEnd -Path $Path -Arguments $Arguments        
                }

                $WsusConfiguration.OobeInitialized = $true
                SaveWsusConfiguration
            }
        }

        # Configure WSUS subscription
        if($WsusConfiguration.OobeInitialized)
        {
            $WsusSubscription = $WsusServer.GetSubscription()

            #Products
            Write-Verbose "Setting WSUS products"
            $ProductCollection = New-Object Microsoft.UpdateServices.Administration.UpdateCategoryCollection
            $AllWsusProducts = $WsusServer.GetUpdateCategories()
            if($Products -eq "*")
            {
                foreach($Product in $AllWsusProducts)
                {
                    $null = $ProductCollection.Add($WsusServer.GetUpdateCategory($Product.Id))
                }
            }
            else
            {
                foreach($Product in $Products)
                {
                    if($WsusProduct = $AllWsusProducts | Where-Object {$_.Title -eq $Product})
                    {
                        $null = $ProductCollection.Add($WsusServer.GetUpdateCategory($WsusProduct.Id))
                    }
                }
            }
            $WsusSubscription.SetUpdateCategories($ProductCollection)

            #Classifications
            Write-Verbose "Setting WSUS classifications"
            $ClassificationCollection = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
            $AllWsusClassifications = $WsusServer.GetUpdateClassifications()
            if($Classifications -eq "*")
            {
                foreach($Classification in $AllWsusClassifications)
                {
                    $null = $ClassificationCollection.Add($WsusServer.GetUpdateClassification($Classification.Id))
                }
            }
            else
            {
                foreach($Classification in $Classifications)
                {
                    if($WsusClassification = $AllWsusClassifications | Where-Object {$_.ID.Guid -eq $Classification})
                    {
                        $null = $ClassificationCollection.Add($WsusServer.GetUpdateClassification($WsusClassification.Id))
                    }
                    else
                    {
                        Write-Verbose "Classification $Classification not found"
                    }
                }
            }
            $WsusSubscription.SetUpdateClassifications($ClassificationCollection)

            #Synchronization Schedule
            Write-Verbose "Setting WSUS synchronization schedule"
            $WsusSubscription.SynchronizeAutomatically = $SynchronizeAutomatically
            if($PSBoundParameters.ContainsKey('SynchronizeAutomaticallyTimeOfDay'))
            {
                $WsusSubscription.SynchronizeAutomaticallyTimeOfDay = $SynchronizeAutomaticallyTimeOfDay
            }
            $WsusSubscription.NumberOfSynchronizationsPerDay = $SynchronizationsPerDay

            $WsusSubscription.Save()

            if($Synchronize)
            {
                Write-Verbose "Synchronizing WSUS"
                    
                $WsusServer.GetSubscription().StartSynchronization()
                while($WsusServer.GetSubscription().GetSynchronizationStatus() -eq 'Running')
                {
                    Start-Sleep 1
                }
                if($WsusServer.GetSubscription().GetSynchronizationHistory()[0].Result -eq 'Succeeded')
                {
                    Write-Verbose "WSUS synchronization succeeded"
                }
                else
                {
                    Write-Verbose "WSUS synchronization failed"
                }
            }
        }
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [System.String]
        $SQLServer,

        [System.String]
        $ContentDir,

        [System.Boolean]
        $UpdateImprovementProgram,

        [System.String]
        $UpstreamServerName,

        [System.UInt16]
        $UpstreamServerPort = 8530,

        [System.Boolean]
        $UpstreamServerSSL,

        [System.Boolean]
        $UpstreamServerReplica,

        [System.String]
        $ProxyServerName,

        [System.UInt16]
        $ProxyServerPort = 80,

        [System.Management.Automation.PSCredential]
        $ProxyServerCredential,

        [System.Boolean]
        $ProxyServerBasicAuthentication,

        [System.String[]]
        $Languages = "*",

        [System.String[]]
        $Products = @("Windows","Office"),

        [System.String[]]
        $Classifications = @('E6CF1350-C01B-414D-A61F-263D14D133B4','E0789628-CE08-4437-BE74-2495B842F43B','0FA1201D-4330-4FA8-8AE9-B877473B6441'),

        [System.Boolean]
        $SynchronizeAutomatically,

        [System.String]
        $SynchronizeAutomaticallyTimeOfDay,

        [System.UInt16]
        $SynchronizationsPerDay = 1,

        [System.Boolean]
        $Synchronize
    )

    $result = $true

    $Wsus = Get-TargetResource -Ensure $Ensure

    # Test Ensure
    if($Wsus.Ensure -ne $Ensure)
    {
        Write-Verbose "Ensure test failed"
        $result = $false
    }
    if($result -and ($Wsus.Ensure -eq "Present"))
    {
        # Test Update Improvement Program
        if($Wsus.UpdateImprovementProgram -ne $UpdateImprovementProgram)
        {
            Write-Verbose "UpdateImprovementProgram test failed"
            $result = $false
        }
        # Test Upstream Server
        if($Wsus.UpstreamServerName -ne $UpstreamServerName)
        {
            Write-Verbose "UpstreamServerName test failed"
            $result = $false
        }
        if($PSBoundParameters.ContainsKey('UpstreamServerName'))
        {
            if($Wsus.UpstreamServerPort -ne $UpstreamServerPort)
            {
                Write-Verbose "UpstreamServerPort test failed"
                $result = $false
            }
            if($Wsus.UpstreamServerSSL -ne $UpstreamServerSSL)
            {
                Write-Verbose "UpstreamServerSSL test failed"
                $result = $false
            }
            if($Wsus.UpstreamServerReplica -ne $UpstreamServerReplica)
            {
                Write-Verbose "UpstreamServerReplica test failed"
                $result = $false
            }
        }
        # Test Proxy Server
        if($Wsus.ProxyServerName -ne $ProxyServerName)
        {
            Write-Verbose "ProxyServerName test failed"
            $result = $false
        }
        if($PSBoundParameters.ContainsKey('ProxyServerName'))
        {
            if($Wsus.ProxyServerPort -ne $ProxyServerPort)
            {
                Write-Verbose "ProxyServerPort test failed"
                $result = $false
            }
            if($PSBoundParameters.ContainsKey('ProxyServerCredential'))
            {
                if(
                    ($Wsus.ProxyServerCredentialUserName -eq $null) -or
                    ($Wsus.ProxyServerCredentialUserName -ne $ProxyServerCredential.UserName)
                )
                {
                    Write-Verbose "ProxyServerCredential test failed - incorrect credential"
                    $result = $false
                }
                if($Wsus.ProxyServerBasicAuthentication -ne $ProxyServerBasicAuthentication)
                {
                    Write-Verbose "ProxyServerBasicAuthentication test failed"
                    $result = $false
                }
            }
            else
            {
                if($Wsus.ProxyServerCredentialUserName -ne $null)
                {
                    Write-Verbose "ProxyServerCredential test failed - credential set"
                    $result = $false
                }
            }
        }
        # Test Languages
        if((Compare-Object -ReferenceObject ($Wsus.Languages | Sort-Object -Unique) -DifferenceObject ($Languages | Sort-Object -Unique) -SyncWindow 0) -ne $null)
        {
            Write-Verbose "Languages test failed"
            $result = $false
        }
        # Test Products
        if((Compare-Object -ReferenceObject ($Wsus.Products | Sort-Object -Unique) -DifferenceObject ($Products | Sort-Object -Unique) -SyncWindow 0) -ne $null)
        {
            Write-Verbose "Products test failed"
            $result = $false
        }
        # Test Classifications
        if((Compare-Object -ReferenceObject ($Wsus.Classifications | Sort-Object -Unique) -DifferenceObject ($Classifications | Sort-Object -Unique) -SyncWindow 0) -ne $null)
        {
            Write-Verbose "Classifications test failed"
            $result = $false
        }
        # Test Synchronization Schedule
        if($SynchronizeAutomatically)
        {
            if($PSBoundParameters.ContainsKey('SynchronizeAutomaticallyTimeOfDay'))
            {
                if($Wsus.SynchronizeAutomaticallyTimeOfDay -ne $SynchronizeAutomaticallyTimeOfDay)
                {
                    Write-Verbose "SynchronizeAutomaticallyTimeOfDay test failed"
                    $result = $false
                }
            }
            if($Wsus.SynchronizationsPerDay -ne $SynchronizationsPerDay)
            {
                Write-Verbose "SynchronizationsPerDay test failed"
                $result = $false
            }
        }
    }

    $result
}


function SaveWsusConfiguration
{
    do
    {
        try
        {
            $WsusConfiguration.Save()
            $WsusConfigurationReady = $true
        }
        catch
        {
            $WsusConfigurationReady = $false
            Start-Sleep 1
        }
    }
    until($WsusConfigurationReady)    
}


Export-ModuleMember -Function *-TargetResource
