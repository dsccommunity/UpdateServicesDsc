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
Import-Module $currentPath\..\..\UpdateServicesHelper.psm1 -Verbose:$false -ErrorAction Stop

<#
    .SYNOPSIS
    Returns the current configuration of WSUS
    .PARAMETER Ensure
    Determinse if the configuration should be added or removed
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Write-Verbose -Message 'Getting WSUSServer'
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

    Write-Verbose -Message "WSUSServer is $Ensure"
    if($Ensure -eq 'Present')
    {
        Write-Verbose -Message 'Getting WSUSServer configuration'
        $WsusConfiguration = $WsusServer.GetConfiguration()
        Write-Verbose -Message 'Getting WSUSServer subscription'
        $WsusSubscription = $WsusServer.GetSubscription()

        Write-Verbose -Message 'Getting WSUSServer SQL Server'
        $SQLServer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' `
                -Name 'SQLServerName').SQLServerName
        Write-Verbose -Message "WSUSServer SQL Server is $SQLServer"
        Write-Verbose -Message 'Getting WSUSServer content directory'
        $ContentDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' `
                -Name 'ContentDir').ContentDir
        Write-Verbose -Message "WSUSServer content directory is $ContentDir"

        Write-Verbose -Message 'Getting WSUSServer update improvement program'
        $UpdateImprovementProgram = $WsusConfiguration.MURollupOptin
        Write-Verbose -Message "WSUSServer content update improvement program is $UpdateImprovementProgram"

        if(!$WsusConfiguration.SyncFromMicrosoftUpdate)
        {
            Write-Verbose -Message 'Getting WSUSServer upstream server'
            $UpstreamServerName = $WsusConfiguration.UpstreamWsusServerName
            $UpstreamServerPort = $WsusConfiguration.UpstreamWsusServerPortNumber
            $UpstreamServerSSL = $WsusConfiguration.UpstreamWsusServerUseSsl
            $UpstreamServerReplica = $WsusConfiguration.IsReplicaServer
            Write-Verbose -Message "WSUSServer upstream server is $UpstreamServerName, `
                port $UpstreamServerPort, use SSL $UpstreamServerSSL, replica $UpstreamServerReplica"
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
            Write-Verbose -Message 'Getting WSUSServer proxy server'
            $ProxyServerName = $WsusConfiguration.ProxyName
            $ProxyServerPort = $WsusConfiguration.ProxyServerPort
            $ProxyServerBasicAuthentication = $WsusConfiguration.AllowProxyCredentialsOverNonSsl
            if (!($WsusConfiguration.AnonymousProxyAccess))
            {
                $ProxyServerCredentialUsername = "$($WsusConfiguration.ProxyUserDomain)\ `
                    $($WsusConfiguration.ProxyUserName)".Trim('\')
            }
            Write-Verbose -Message "WSUSServer proxy server is $ProxyServerName, port $ProxyServerPort, `
                basic authentication $ProxyServerBasicAuthentication"
        }
        else
        {
            $ProxyServerName = ""
            $ProxyServerPort = $null
            $ProxyServerBasicAuthentication = $null
        }

        Write-Verbose -Message 'Getting WSUSServer languages'
        if($WsusConfiguration.AllUpdateLanguagesEnabled)
        {
            $Languages = @("*")
        }
        else
        {
            $Languages = $WsusConfiguration.GetEnabledUpdateLanguages()
        }
        Write-Verbose -Message "WSUSServer languages are $Languages"

        Write-Verbose -Message 'Getting WSUSServer classifications'
        if ($Classifications = @($WsusSubscription.GetUpdateClassifications().ID.Guid))
        {
            if($null -eq (Compare-Object -ReferenceObject ($Classifications | Sort-Object -Unique) -DifferenceObject `
                    (($WsusServer.GetUpdateClassifications().ID.Guid) | Sort-Object -Unique) -SyncWindow 0))
            {
                $Classifications = @("*")
            }
        }
        else {
            $Classifications = @("*")
        }
        Write-Verbose -Message "WSUSServer classifications are $Classifications"
        Write-Verbose -Message 'Getting WSUSServer products'
        if ($Products = @($WsusSubscription.GetUpdateCategories().Title))
        {
            if($null -eq (Compare-Object -ReferenceObject ($Products | Sort-Object -Unique) -DifferenceObject `
                    (($WsusServer.GetUpdateCategories().Title) | Sort-Object -Unique) -SyncWindow 0))
            {
                $Products = @("*")
            }
        }
        else {
            $Products = @("*")
        }
        Write-Verbose -Message "WSUSServer products are $Products"
        Write-Verbose -Message 'Getting WSUSServer synchronization settings'
        $SynchronizeAutomatically = $WsusSubscription.SynchronizeAutomatically
        Write-Verbose -Message "WSUSServer synchronize automatically is $SynchronizeAutomatically"
        $SynchronizeAutomaticallyTimeOfDay = $WsusSubscription.SynchronizeAutomaticallyTimeOfDay
        Write-Verbose -Message "WSUSServer synchronize automatically time of day is $SynchronizeAutomaticallyTimeOfDay"
        $SynchronizationsPerDay = $WsusSubscription.NumberOfSynchronizationsPerDay
        Write-Verbose -Message "WSUSServer number of synchronizations per day is $SynchronizationsPerDay"
        $ClientTargetingMode = $WsusConfiguration.TargetingMode
        Write-Verbose -Message "WSUSServer client targeting mode is $ClientTargetingMode"
    }

    $returnValue = @{
        Ensure                            = $Ensure
        SQLServer                         = $SQLServer
        ContentDir                        = $ContentDir
        UpdateImprovementProgram          = $UpdateImprovementProgram
        UpstreamServerName                = $UpstreamServerName
        UpstreamServerPort                = $UpstreamServerPort
        UpstreamServerSSL                 = $UpstreamServerSSL
        UpstreamServerReplica             = $UpstreamServerReplica
        ProxyServerName                   = $ProxyServerName
        ProxyServerPort                   = $ProxyServerPort
        ProxyServerCredentialUsername     = $ProxyServerCredentialUsername
        ProxyServerBasicAuthentication    = $ProxyServerBasicAuthentication
        Languages                         = $Languages
        Products                          = $Products
        Classifications                   = $Classifications
        SynchronizeAutomatically          = $SynchronizeAutomatically
        SynchronizeAutomaticallyTimeOfDay = $SynchronizeAutomaticallyTimeOfDay
        SynchronizationsPerDay            = $SynchronizationsPerDay
        ClientTargetingMode               = $ClientTargetingMode
    }

    $returnValue
}

<#
    .SYNOPSIS
    Configures a WSUS server instance
    .PARAMETER Ensure
    Determines if the task should be created or removed.
    Accepts 'Present'(default) or 'Absent'.
    .PARAMETER SetupCredential
    Credentisal to use when running setup.
    Applicable when using SQL as data store.
    .PARAMETER SQLServer
    Optionally specify a SQL instance to store WSUS data
    .PARAMETER ContentDir
    Location to store WSUS content files
    .PARAMETER UpdateImprovementProgram
    Provide feedback to Microsoft to help imrpove WSUS
    .PARAMETER UpstreamServerName
    Name of another WSUS server to retrieve content from
    .PARAMETER UpstreamServerPort
    If getting content from another server, port for traffic
    .PARAMETER UpstreamServerSSL
    If getting content from another server, whether to encrypt the traffic
    .PARAMETER UpstreamServerReplica
    Boolean to specify whether to retrieve content from anotehr server
    .PARAMETER ProxyServerName
    Host name of proxy server
    .PARAMETER ProxyServerPort
    Port of proxy server
    .PARAMETER ProxyServerCredential
    Credential to use when authenticating to proxy server
    .PARAMETER ProxyServerBasicAuthentication
    Use basic auth for proxy
    .PARAMETER Languages
    Specify list of languages for content, or "*" for all
    .PARAMETER Products
    List of products to include when synchronizing, by default Windows and Office
    .PARAMETER Classifications
    List of content classifications to synchronize to the WSUS server
    .PARAMETER SynchronizeAutomatically
    Automatically synchronize the WSUS instance
    .PARAMETER SynchronizeAutomaticallyTimeOfDay
    Time of day to schedule an automatic synchronization
    .PARAMETER SynchronizationsPerDay
    Number of automatic synchronizations per day
    .PARAMETER Synchronize
    Run a synchronization immediately when running Set
    .PARAMETER ClientTargetingMode
    An enumerated value that describes if how the Target Groups are populated.
    Accepts 'Client'(default) or 'Server'.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [Parameter()]
        [System.String]
        $SQLServer,

        [Parameter()]
        [System.String]
        $ContentDir = "%SystemDrive%\WSUS",

        [Parameter()]
        [System.Boolean]
        $UpdateImprovementProgram,

        [Parameter()]
        [System.String]
        $UpstreamServerName,

        [Parameter()]
        [System.UInt16]
        $UpstreamServerPort = 8530,

        [Parameter()]
        [System.Boolean]
        $UpstreamServerSSL,

        [Parameter()]
        [System.Boolean]
        $UpstreamServerReplica,

        [Parameter()]
        [System.String]
        $ProxyServerName,

        [Parameter()]
        [System.UInt16]
        $ProxyServerPort = 80,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ProxyServerCredential,

        [Parameter()]
        [System.Boolean]
        $ProxyServerBasicAuthentication,

        [Parameter()]
        [System.String[]]
        $Languages = @("*"),

        [Parameter()]
        [System.String[]]
        $Products = @("Windows","Office"),

        [Parameter()]
        [System.String[]]
        $Classifications = @('E6CF1350-C01B-414D-A61F-263D14D133B4','E0789628-CE08-4437-BE74-2495B842F43B','0FA1201D-4330-4FA8-8AE9-B877473B6441'),

        [Parameter()]
        [System.Boolean]
        $SynchronizeAutomatically,

        [Parameter()]
        [System.String]
        $SynchronizeAutomaticallyTimeOfDay,

        [Parameter()]
        [System.UInt16]
        $SynchronizationsPerDay = 1,

        [Parameter()]
        [System.Boolean]
        $Synchronize,

        [Parameter()]
        [ValidateSet("Client", "Server")]
        [System.String]
        $ClientTargetingMode
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
        Write-Verbose -Message "Running WSUS postinstall"

        Import-Module $PSScriptRoot\..\..\PDT\PDT.psm1

        $Path = "$($env:ProgramFiles)\Update Services\Tools\WsusUtil.exe"
        $Path = Invoke-ResolvePath $Path
        Write-Verbose -Message "Path: $Path"

        $Arguments = "postinstall "
        if($PSBoundParameters.ContainsKey('SQLServer'))
        {
            $Arguments += "SQL_INSTANCE_NAME=$SQLServer "
        }
        $Arguments += "CONTENT_DIR=$([Environment]::ExpandEnvironmentVariables($ContentDir))"

        Write-Verbose -Message "Arguments: $Arguments"

        if ($SetupCredential)
        {
            $Process = Start-Win32Process -Path $Path -Arguments $Arguments -Credential $SetupCredential
            Write-Verbose -Message [string]$Process
            Wait-Win32ProcessEnd -Path $Path -Arguments $Arguments
        }
        else
        {
            $Process = Start-Win32Process -Path $Path -Arguments $Arguments
            Write-Verbose -Message [string]$Process
            Wait-Win32ProcessEnd -Path $Path -Arguments $Arguments
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
        Write-Verbose -Message "Configuring WSUS"

        # Get configuration and make sure that the configuration can be saved before continuing
        $WsusConfiguration = $WsusServer.GetConfiguration()
        $WsusSubscription = $WsusServer.GetSubscription()
        Write-Verbose -Message "Check for previous configuration change"
        SaveWsusConfiguration

        # Configure Update Improvement Program
        Write-Verbose -Message "Configuring WSUS Update Improvement Program"
        $WsusConfiguration.MURollupOptin = $UpdateImprovementProgram

        # Configure Upstream Server
        if($PSBoundParameters.ContainsKey('UpstreamServerName')  -And ![string]::IsNullOrEmpty($UpstreamServerName))
        {
            Write-Verbose -Message "Configuring WSUS Upstream Server"
            $WsusConfiguration.SyncFromMicrosoftUpdate = $false
            $WsusConfiguration.UpstreamWsusServerName = $UpstreamServerName
            $WsusConfiguration.UpstreamWsusServerPortNumber = $UpstreamServerPort
            $WsusConfiguration.UpstreamWsusServerUseSsl = $UpstreamServerSSL
            $WsusConfiguration.IsReplicaServer = $UpstreamServerReplica
        }
        else
        {
            Write-Verbose -Message "Configuring WSUS for Microsoft Update"
            $WsusConfiguration.SyncFromMicrosoftUpdate = $true
        }

        # Configure Proxy Server
        if($PSBoundParameters.ContainsKey('ProxyServerName') -And ![string]::IsNullOrEmpty($ProxyServerName))
        {
            Write-Verbose -Message "Configuring WSUS proxy server"
            $WsusConfiguration.UseProxy = $true
            $WsusConfiguration.ProxyName = $ProxyServerName
            $WsusConfiguration.ProxyServerPort = $ProxyServerPort
            if($PSBoundParameters.ContainsKey('ProxyServerCredential'))
            {
                Write-Verbose -Message "Configuring WSUS proxy server credential"
                $WsusConfiguration.ProxyUserDomain = $ProxyServerCredential.GetNetworkCredential().Domain
                $WsusConfiguration.ProxyUserName = $ProxyServerCredential.GetNetworkCredential().UserName
                $WsusConfiguration.SetProxyPassword($ProxyServerCredential.GetNetworkCredential().Password)
                $WsusConfiguration.AllowProxyCredentialsOverNonSsl = $ProxyServerBasicAuthentication
                $WsusConfiguration.AnonymousProxyAccess = $false
            }
            else
            {
                Write-Verbose -Message "Removing WSUS proxy server credential"
                $WsusConfiguration.AnonymousProxyAccess = $true
            }
        }
        else
        {
            Write-Verbose -Message "Configuring WSUS no proxy server"
            $WsusConfiguration.UseProxy = $false
        }

        #Languages
        Write-Verbose -Message "Setting WSUS languages"
        if($Languages -eq "*")
        {
            $WsusConfiguration.AllUpdateLanguagesEnabled = $true
        }
        else
        {
            $WsusConfiguration.AllUpdateLanguagesEnabled = $false
            $WsusConfiguration.SetEnabledUpdateLanguages($Languages)
        }

        #ClientTargetingMode
        if($PSBoundParameters.ContainsKey("ClientTargetingMode"))
        {
            Write-Verbose -Message "Setting WSUS client targeting mode"
            $WsusConfiguration.TargetingMode = $ClientTargetingMode
        }

        # Save configuration before initial sync
        SaveWsusConfiguration

        # Post Install
        if($PostInstall)
        {
            Write-Verbose -Message "Removing default products and classifications before initial sync"
            foreach($Product in ($WsusServer.GetSubscription().GetUpdateCategories().Title))
            {
                Get-WsusProduct | Where-Object {$_.Product.Title -eq $Product} | `
                    Set-WsusProduct -Disable
            }
            foreach($Classification in `
                ($WsusServer.GetSubscription().GetUpdateClassifications().ID.Guid))
            {
                Get-WsusClassification | Where-Object {$_.Classification.ID -eq $Classification} | `
                    Set-WsusClassification -Disable
            }

            if($Synchronize)
            {
                Write-Verbose -Message "Running WSUS initial synchronization online"
                $WsusServer.GetSubscription().StartSynchronizationForCategoryOnly()
                while($WsusServer.GetSubscription().GetSynchronizationStatus() -eq 'Running')
                {
                    Start-Sleep -Seconds 1
                }

                if($WsusServer.GetSubscription().GetSynchronizationHistory()[0].Result -eq 'Succeeded')
                {
                    Write-Verbose -Message "Initial WSUS synchronization succeeded"
                    $WsusConfiguration.OobeInitialized = $true
                    SaveWsusConfiguration
                }
                else
                {
                    Write-Verbose -Message "Initial WSUS synchronization failed"
                }
            }
            else
            {
                Write-Verbose -Message "Running WSUS initial synchronization offline"

                $TempFile = [IO.Path]::GetTempFileName()

                $CABPath = Join-Path -Path $PSScriptRoot -ChildPath "\WSUS.cab"

                $Arguments = "import "
                $Arguments += "`"$CABPath`" $TempFile"

                Write-Verbose -Message "Arguments: $Arguments"

                if ($SetupCredential)
                {
                    $Process = Start-Win32Process -Path $Path -Arguments $Arguments -Credential $SetupCredential
                    Write-Verbose -Message [string]$Process
                    Wait-Win32ProcessEnd -Path $Path -Arguments $Arguments
                }
                else
                {
                    $Process = Start-Win32Process -Path $Path -Arguments $Arguments
                    Write-Verbose -Message [string]$Process
                    Wait-Win32ProcessEnd -Path $Path -Arguments $Arguments
                }

                $WsusConfiguration.OobeInitialized = $true
                SaveWsusConfiguration
            }
        }

        # Configure WSUS subscription
        if($WsusConfiguration.OobeInitialized)
        {
            $WsusSubscription = $WsusServer.GetSubscription()

            # Products
            Write-Verbose -Message "Setting WSUS products"
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

            # Classifications
            Write-Verbose -Message "Setting WSUS classifications"
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
                    if($WsusClassification = $AllWsusClassifications | `
                            Where-Object {$_.ID.Guid -eq $Classification})
                    {
                        $null = $ClassificationCollection.Add($WsusServer.GetUpdateClassification(`
                                    $WsusClassification.Id))
                    }
                    else
                    {
                        Write-Verbose -Message "Classification $Classification not found"
                    }
                }
            }
            $WsusSubscription.SetUpdateClassifications($ClassificationCollection)

            #Synchronization Schedule
            Write-Verbose -Message "Setting WSUS synchronization schedule"
            $WsusSubscription.SynchronizeAutomatically = $SynchronizeAutomatically
            if($PSBoundParameters.ContainsKey('SynchronizeAutomaticallyTimeOfDay'))
            {
                $WsusSubscription.SynchronizeAutomaticallyTimeOfDay = $SynchronizeAutomaticallyTimeOfDay
            }
            $WsusSubscription.NumberOfSynchronizationsPerDay = $SynchronizationsPerDay

            $WsusSubscription.Save()

            if($Synchronize)
            {
                Write-Verbose -Message "Synchronizing WSUS"

                $WsusServer.GetSubscription().StartSynchronization()
                while($WsusServer.GetSubscription().GetSynchronizationStatus() -eq 'Running')
                {
                    Start-Sleep -Seconds 1
                }
                if($WsusServer.GetSubscription().GetSynchronizationHistory()[0].Result -eq 'Succeeded')
                {
                    Write-Verbose -Message "WSUS synchronization succeeded"
                }
                else
                {
                    Write-Verbose -Message "WSUS synchronization failed"
                }
            }
        }
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    Configures a WSUS server instance
    .PARAMETER Ensure
    Determines if the task should be created or removed.
    Accepts 'Present'(default) or 'Absent'.
    .PARAMETER SetupCredential
    Credentisal to use when running setup.
    Applicable when using SQL as data store.
    .PARAMETER SQLServer
    Optionally specify a SQL instance to store WSUS data
    .PARAMETER ContentDir
    Location to store WSUS content files
    .PARAMETER UpdateImprovementProgram
    Provide feedback to Microsoft to help imrpove WSUS
    .PARAMETER UpstreamServerName
    Name of another WSUS server to retrieve content from
    .PARAMETER UpstreamServerPort
    If getting content from another server, port for traffic
    .PARAMETER UpstreamServerSSL
    If getting content from another server, whether to encrypt the traffic
    .PARAMETER UpstreamServerReplica
    Boolean to specify whether to retrieve content from anotehr server
    .PARAMETER ProxyServerName
    Host name of proxy server
    .PARAMETER ProxyServerPort
    Port of proxy server
    .PARAMETER ProxyServerCredential
    Credential to use when authenticating to proxy server
    .PARAMETER ProxyServerBasicAuthentication
    Use basic auth for proxy
    .PARAMETER Languages
    Specify list of languages for content, or "*" for all
    .PARAMETER Products
    List of products to include when synchronizing, by default Windows and Office
    .PARAMETER Classifications
    List of content classifications to synchronize to the WSUS server
    .PARAMETER SynchronizeAutomatically
    Automatically synchronize the WSUS instance
    .PARAMETER SynchronizeAutomaticallyTimeOfDay
    Time of day to schedule an automatic synchronization
    .PARAMETER SynchronizationsPerDay
    Number of automatic synchronizations per day
    .PARAMETER Synchronize
    Run a synchronization immediately when running Set
    .PARAMETER ClientTargetingMode
    An enumerated value that describes if how the Target Groups are populated.
    Accepts 'Client'(default) or 'Server'.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [Parameter()]
        [System.String]
        $SQLServer,

        [Parameter()]
        [System.String]
        $ContentDir,

        [Parameter()]
        [System.Boolean]
        $UpdateImprovementProgram,

        [Parameter()]
        [System.String]
        $UpstreamServerName,

        [Parameter()]
        [System.UInt16]
        $UpstreamServerPort = 8530,

        [Parameter()]
        [System.Boolean]
        $UpstreamServerSSL,

        [Parameter()]
        [System.Boolean]
        $UpstreamServerReplica,

        [Parameter()]
        [System.String]
        $ProxyServerName,

        [Parameter()]
        [System.UInt16]
        $ProxyServerPort = 80,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ProxyServerCredential,

        [Parameter()]
        [System.Boolean]
        $ProxyServerBasicAuthentication,

        [Parameter()]
        [System.String[]]
        $Languages = @("*"),

        [Parameter()]
        [System.String[]]
        $Products = @("Windows","Office"),

        [Parameter()]
        [System.String[]]
        $Classifications = @('E6CF1350-C01B-414D-A61F-263D14D133B4','E0789628-CE08-4437-BE74-2495B842F43B','0FA1201D-4330-4FA8-8AE9-B877473B6441'),

        [Parameter()]
        [System.Boolean]
        $SynchronizeAutomatically,

        [Parameter()]
        [System.String]
        $SynchronizeAutomaticallyTimeOfDay,

        [Parameter()]
        [System.UInt16]
        $SynchronizationsPerDay = 1,

        [Parameter()]
        [System.Boolean]
        $Synchronize,

        [Parameter()]
        [ValidateSet("Client", "Server")]
        [System.String]
        $ClientTargetingMode
    )

    $result = $true

    $Wsus = Get-TargetResource -Ensure $Ensure

    # Test Ensure
    if($Wsus.Ensure -ne $Ensure)
    {
        Write-Verbose -Message "Ensure test failed"
        $result = $false
    }
    if($result -and ($Wsus.Ensure -eq "Present"))
    {
        # Test Update Improvement Program
        if($Wsus.UpdateImprovementProgram -ne $UpdateImprovementProgram)
        {
            Write-Verbose -Message "UpdateImprovementProgram test failed"
            $result = $false
        }
        # Test Upstream Server
        if($Wsus.UpstreamServerName -ne $UpstreamServerName)
        {
            Write-Verbose -Message "UpstreamServerName test failed"
            $result = $false
        }
        if($PSBoundParameters.ContainsKey('UpstreamServerName'))
        {
            if($Wsus.UpstreamServerPort -ne $UpstreamServerPort)
            {
                Write-Verbose -Message "UpstreamServerPort test failed"
                $result = $false
            }
            if($Wsus.UpstreamServerSSL -ne $UpstreamServerSSL)
            {
                Write-Verbose -Message "UpstreamServerSSL test failed"
                $result = $false
            }
            if($Wsus.UpstreamServerReplica -ne $UpstreamServerReplica)
            {
                Write-Verbose -Message "UpstreamServerReplica test failed"
                $result = $false
            }
        }
        # Test Proxy Server
        if($Wsus.ProxyServerName -ne $ProxyServerName)
        {
            Write-Verbose -Message "ProxyServerName test failed"
            $result = $false
        }
        if($PSBoundParameters.ContainsKey('ProxyServerName'))
        {
            if($Wsus.ProxyServerPort -ne $ProxyServerPort)
            {
                Write-Verbose -Message "ProxyServerPort test failed"
                $result = $false
            }
            if($PSBoundParameters.ContainsKey('ProxyServerCredential'))
            {
                if(
                    ($null -eq $Wsus.ProxyServerCredentialUserName) -or
                    ($Wsus.ProxyServerCredentialUserName -ne $ProxyServerCredential.UserName)
                )
                {
                    Write-Verbose -Message "ProxyServerCredential test failed - incorrect credential"
                    $result = $false
                }
                if($Wsus.ProxyServerBasicAuthentication -ne $ProxyServerBasicAuthentication)
                {
                    Write-Verbose -Message "ProxyServerBasicAuthentication test failed"
                    $result = $false
                }
            }
            else
            {
                if($null -ne $Wsus.ProxyServerCredentialUserName)
                {
                    Write-Verbose -Message "ProxyServerCredential test failed - credential set"
                    $result = $false
                }
            }
        }
        # Test Languages
        if($Wsus.Languages.count -le 1 -and $Languages.count -le 1 -and $Languages -ne '*')
        {
            if($Wsus.Languages -notmatch $Languages)
            {
                Write-Verbose -Message "Languages test failed (evaluated as single string)"
                $result = $false
            }
        }
        else {
            if($null -ne (Compare-Object -ReferenceObject ($Wsus.Languages | Sort-Object -Unique) `
                        -DifferenceObject ($Languages | Sort-Object -Unique) -SyncWindow 0))
            {
                Write-Verbose -Message "Languages test failed"
                $result = $false
            }
        }
        # Test Products
        if($null -ne (Compare-Object -ReferenceObject ($Wsus.Products | Sort-Object -Unique) `
                    -DifferenceObject ($Products | Sort-Object -Unique) -SyncWindow 0))
        {
            Write-Verbose -Message "Products test failed"
            $result = $false
        }
        # Test Classifications
        if($null -ne (Compare-Object -ReferenceObject ($Wsus.Classifications | Sort-Object -Unique) `
                    -DifferenceObject ($Classifications | Sort-Object -Unique) -SyncWindow 0))
        {
            Write-Verbose -Message "Classifications test failed"
            $result = $false
        }
        # Test Synchronization Schedule
        if($SynchronizeAutomatically)
        {
            if($PSBoundParameters.ContainsKey('SynchronizeAutomaticallyTimeOfDay'))
            {
                if($Wsus.SynchronizeAutomaticallyTimeOfDay -ne $SynchronizeAutomaticallyTimeOfDay)
                {
                    Write-Verbose -Message "SynchronizeAutomaticallyTimeOfDay test failed"
                    $result = $false
                }
            }
            if($Wsus.SynchronizationsPerDay -ne $SynchronizationsPerDay)
            {
                Write-Verbose -Message "SynchronizationsPerDay test failed"
                $result = $false
            }
        }

        # Test Client Targeting Mode
        if($ClientTargetingMode)
        {
            if($PSBoundParameters.ContainsKey('ClientTargetingMode'))
            {
                if($Wsus.ClientTargetingMode -ne $ClientTargetingMode)
                {
                    Write-Verbose -Message "ClientTargetingMode test failed"
                    $result = $false
                }
            }
        }
    }

    $result
}

<#
    .SYNOPSIS
    Saves the WSUS configuration
#>
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
            Start-Sleep -Seconds 1
        }
    }
    until($WsusConfigurationReady)
}


Export-ModuleMember -Function *-TargetResource
