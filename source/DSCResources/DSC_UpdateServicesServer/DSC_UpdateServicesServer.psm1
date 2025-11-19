# DSC resource to initialize and configure WSUS Server.

# Classifications ID reference...
#
# Applications       = 5C9376AB-8CE6-464A-B136-22113DD69801
# Connectors         = 434DE588-ED14-48F5-8EED-A15E09A991F6
# Critical Updates   = E6CF1350-C01B-414D-A61F-263D14D133B4
# Definition Updates = E0789628-CE08-4437-BE74-2495B842F43B
# Driver Sets        = 77835C8D-62A7-41F5-82AD-F28D1AF1E3B1
# Drivers            = EBFC1FC5-71A4-4F7B-9ACA-3B9A503104A0
# Developer Kits     = E140075D-8433-45C3-AD87-E72345B36078
# Feature Packs      = B54E7D24-7ADD-428F-8B75-90A396FA584F
# Guidance           = 9511D615-35B2-47BB-927F-F73D8E9260BB
# Hotfix             = 5EAEF3E6-ABB0-4192-9B26-0FD955381FA9
# Security Updates   = 0FA1201D-4330-4FA8-8AE9-B877473B6441
# Service Packs      = 68C5B0A3-D1A6-4553-AE49-01D3A7827828
# Third Party        = 871A0782-BE12-A5C4-C57F-1BD6D9F7144E
# Tools              = B4832BD8-E735-4761-8DAF-37F882276DAB
# Update Rollups     = 28BC880E-0592-4CBF-8F95-C79B17911D5F
# Updates            = CD5FFD1E-E932-4E3A-BF74-18BF0B1BBD83
# Upgrades           = 3689BDC8-B205-4AF4-8D4A-A63924C5E9D5

# Load Common Module
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
    Returns the current configuration of WSUS
    .PARAMETER Ensure
    Determines if the configuration should be added or removed
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure
    )

    Assert-Module -ModuleName UpdateServices

    $Ensure = 'Absent'

    Write-Verbose -Message $script:localizedData.GettingWsusServer
    try
    {
        if (($WsusServer = Get-WsusServer) -and `
            (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup\Installed Role Services" `
                -Name 'UpdateServices-Services' -ErrorAction Stop).'UpdateServices-Services' -eq '2')
        {
            $Ensure = 'Present'
        }
    }
    catch
    {
        Write-Verbose -Message $script:localizedData.GetWsusServerFailed
    }

    Write-Verbose -Message ($script:localizedData.WsusEnsureValue -f $Ensure)

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message $script:localizedData.GettingWsusConfig
        $WsusConfiguration = $WsusServer.GetConfiguration()
        Write-Verbose -Message $script:localizedData.GettingWsusDatabaseConfig
        $WsusDatabaseConfiguration = $WsusServer.GetDatabaseConfiguration()
        Write-Verbose -Message $script:localizedData.GettingWsusSubscription
        $WsusSubscription = $WsusServer.GetSubscription()
        # Get the current time just before retrieving email configuration for StatusNotificationTimeOfDay DST workarounds
        $currentDateTime = Get-Date
        Write-Verbose -Message $script:localizedData.GettingWsusEmailNotificationConfig
        $WsusEmailNotificationConfiguration = $WsusServer.GetEmailNotificationConfiguration()

        Write-Verbose -Message $script:localizedData.GettingWsusSQLServer
        if (-not $WsusDatabaseConfiguration.IsUsingWindowsInternalDatabase)
        {
            $SQLServer = $WsusDatabaseConfiguration.ServerName
            Write-Verbose -Message ($script:localizedData.SQLServerName -f $SQLServer)
        }
        else {
            $SQLServer = ''
        }

        if (-not $WsusConfiguration.IsReplicaServer)
        {
            Write-Verbose -Message $script:localizedData.GetWsusImproveProgram
            $UpdateImprovementProgram = $WsusConfiguration.MURollupOptin
            Write-Verbose -Message ($script:localizedData.ImprovementProgram -f $UpdateImprovementProgram)
        }
        else
        {
            $UpdateImprovementProgram = $null
        }

        if (-not $WsusConfiguration.SyncFromMicrosoftUpdate)
        {
            Write-Verbose -Message $script:localizedData.GetUpstreamServer
            $UpstreamServerName = $WsusConfiguration.UpstreamWsusServerName
            $UpstreamServerPort = $WsusConfiguration.UpstreamWsusServerPortNumber
            $UpstreamServerSSL = $WsusConfiguration.UpstreamWsusServerUseSsl
            Write-Verbose -Message ($script:localizedData.UpstreamServer -f `
                $UpstreamServerName, $UpstreamServerPort, $UpstreamServerSSL)
        }
        else
        {
            $UpstreamServerName = ''
            $UpstreamServerPort = 0
            $UpstreamServerSSL = $null
        }

        Write-Verbose -Message $script:localizedData.GetReplicaServer
        if (-not $WsusConfiguration.SyncFromMicrosoftUpdate)
        {
            $UpstreamServerReplica = $WsusConfiguration.IsReplicaServer
        }
        else
        {
            $UpstreamServerReplica = $false
        }
        Write-Verbose -Message ($script:localizedData.ReplicaServer -f $UpstreamServerReplica)

        if ($WsusConfiguration.UseProxy)
        {
            Write-Verbose -Message $script:localizedData.GetWsusProxyServer
            $ProxyServerName = $WsusConfiguration.ProxyName
            $ProxyServerPort = $WsusConfiguration.ProxyServerPort
            if (-not ($WsusConfiguration.AnonymousProxyAccess))
            {
                if ($WsusConfiguration.ProxyUserDomain)
                {
                    $ProxyServerCredentialUsername = "$($WsusConfiguration.ProxyUserDomain)\$($WsusConfiguration.ProxyUserName)"
                }
                else
                {
                    $ProxyServerCredentialUsername = $WsusConfiguration.ProxyUserName
                }
                $ProxyServerBasicAuthentication = $WsusConfiguration.AllowProxyCredentialsOverNonSsl
            }
            else
            {
                $ProxyServerCredentialUsername = ''
                $ProxyServerBasicAuthentication = $null
            }
            Write-Verbose -Message ($script:localizedData.WsusProxyServer -f $ProxyServerName, $ProxyServerPort, `
                $ProxyServerCredentialUsername, $ProxyServerBasicAuthentication)
        }
        else
        {
            $ProxyServerName = ''
            $ProxyServerPort = 0
            $ProxyServerCredentialUsername = ''
            $ProxyServerBasicAuthentication = $null
        }

        Write-Verbose -Message $script:localizedData.GettingWsusUpdateFiles
        if (-not $WsusConfiguration.HostBinariesOnMicrosoftUpdate)
        {
            $ContentDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' `
                    -Name 'ContentDir').ContentDir
            $DownloadUpdateBinariesAsNeeded = $WsusConfiguration.DownloadUpdateBinariesAsNeeded
            $DownloadExpressPackages = $WsusConfiguration.DownloadExpressPackages
            if (-not $WsusConfiguration.SyncFromMicrosoftUpdate)
            {
                $GetContentFromMU = $WsusConfiguration.GetContentFromMU
            }
            else
            {
                $GetContentFromMU = $null
            }
        }
        else
        {
            $ContentDir = ''
            $DownloadUpdateBinariesAsNeeded = $null
            $DownloadExpressPackages = $null
            $GetContentFromMU = $null
        }
        Write-Verbose -Message ($script:localizedData.WsusUpdateFiles -f $ContentDir, $DownloadUpdateBinariesAsNeeded, `
            $DownloadExpressPackages, $GetContentFromMU)

        # Get languages - even for servers that host binaries on Microsoft Update, as it is relevant to server configuration
        Write-Verbose -Message $script:localizedData.GettingWsusLanguage
        if ($WsusConfiguration.AllUpdateLanguagesEnabled)
        {
            $Languages = @('*')
        }
        else
        {
            $Languages = [String[]]$WsusConfiguration.GetEnabledUpdateLanguages()
        }
        Write-Verbose -Message ($script:localizedData.WsusLanguages -f ($Languages -join ','))

        # Get classifications - even for replica servers where these are read only, as it is relevant to server configuration
        Write-Verbose -Message $script:localizedData.GettingWsusClassifications
        if ($Classifications = @($WsusSubscription.GetUpdateClassifications().ID.Guid))
        {
            if ($null -eq (Compare-Object -ReferenceObject ($Classifications | Sort-Object -Unique) -DifferenceObject `
                (($WsusServer.GetUpdateClassifications().ID.Guid) | Sort-Object -Unique) -SyncWindow 0))
            {
                $Classifications = @('*')
            }
        }
        else
        {
            $Classifications = @('*')
        }
        Write-Verbose -Message ($script:localizedData.WsusClassifications -f $Classifications)

        # Get products - even for replica servers where these are read only, as it is relevant to server configuration
        Write-Verbose -Message $script:localizedData.GettingWsusProducts
        if ($Products = @($WsusSubscription.GetUpdateCategories().Title) | Sort-Object -Unique)
        {
            if ($null -eq (Compare-Object -ReferenceObject $Products -DifferenceObject `
                (($WsusServer.GetUpdateCategories().Title) | Sort-Object -Unique) -SyncWindow 0))
            {
                $Products = @('*')
            }
        }
        else
        {
            $Products = @('*')
        }
        Write-Verbose -Message ($script:localizedData.WsusProducts -f $($Products -join '; '))

        if (-not $WsusConfiguration.IsReplicaServer)
        {
            Write-Verbose -Message $script:localizedData.GettingWsusAdvancedAutomaticApprovals
            $AutoApproveWsusInfrastructureUpdates = $WsusConfiguration.AutoApproveWsusInfrastructureUpdates
            Write-Verbose -Message ($script:localizedData.WsusAutoApproveWsusInfrastructureUpdates -f $AutoApproveWsusInfrastructureUpdates)
            $AutoRefreshUpdateApprovals = $WsusConfiguration.AutoRefreshUpdateApprovals
            Write-Verbose -Message ($script:localizedData.WsusAutoRefreshUpdateApprovals -f $AutoRefreshUpdateApprovals)
            if ($WsusConfiguration.AutoRefreshUpdateApprovals)
            {
                $AutoRefreshUpdateApprovalsDeclineExpired = $WsusConfiguration.AutoRefreshUpdateApprovalsDeclineExpired
                Write-Verbose -Message ($script:localizedData.WsusAutoRefreshUpdateApprovalsDeclineExpired -f $AutoRefreshUpdateApprovalsDeclineExpired)
            }
            else
            {
                $AutoRefreshUpdateApprovalsDeclineExpired = $null
            }
        }
        else
        {
            $AutoApproveWsusInfrastructureUpdates = $null
            $AutoRefreshUpdateApprovals = $null
            $AutoRefreshUpdateApprovalsDeclineExpired = $null
        }

        Write-Verbose -Message $script:localizedData.GettingWsusSyncConfig
        $SynchronizeAutomatically = $WsusSubscription.SynchronizeAutomatically
        Write-Verbose -Message ($script:localizedData.WsusSyncAuto -f $SynchronizeAutomatically)
        if ($WsusSubscription.SynchronizeAutomatically)
        {
            $SynchronizeAutomaticallyTimeOfDay = $WsusSubscription.SynchronizeAutomaticallyTimeOfDay
            Write-Verbose -Message ($script:localizedData.WsusSyncAutoTimeOfDay -f $SynchronizeAutomaticallyTimeOfDay )
            $SynchronizationsPerDay = $WsusSubscription.NumberOfSynchronizationsPerDay
            Write-Verbose -Message ($script:localizedData.WsusSyncPerDay -f $SynchronizationsPerDay)
        }
        else
        {
            $SynchronizeAutomaticallyTimeOfDay = ''
            $SynchronizationsPerDay = 0
        }

        Write-Verbose -Message $script:localizedData.GettingWsusTargetingMode
        $ClientTargetingMode = $WsusConfiguration.TargetingMode
        Write-Verbose -Message ($script:localizedData.WsusClientTargetingMode -f $ClientTargetingMode)

        if (-not $WsusConfiguration.IsReplicaServer)
        {
            Write-Verbose -Message $script:localizedData.GettingWsusReportingRollup
            $DoDetailedRollup = $WsusConfiguration.DoDetailedRollup
            Write-Verbose -Message ($script:localizedData.WsusDoDetailedRollup -f $DoDetailedRollup)
        }
        else
        {
            $DoDetailedRollup = $null
        }

        Write-Verbose -Message $script:localizedData.GettingWsusEmailNotifications
        if ($WsusEmailNotificationConfiguration.SendSyncNotification)
        {
            # Wrapped in @() to return array even if only one object is returned
            $SyncNotificationRecipients = @($WsusEmailNotificationConfiguration.SyncNotificationRecipients |
                Select-Object -ExpandProperty Address)
            Write-Verbose -Message ($script:localizedData.WsusSyncNotification -f $($SyncNotificationRecipients -join ','))
        }
        else {
            $SyncNotificationRecipients = @()
        }

        if ($WsusEmailNotificationConfiguration.SendStatusNotification)
        {
            $StatusNotificationFrequency = $WsusEmailNotificationConfiguration.StatusNotificationFrequency
            $StatusNotificationTimeOfDay = $WsusEmailNotificationConfiguration.StatusNotificationTimeOfDay

            # When Daylight Savings Time is in effect, StatusNotificationTimeOfDay is supplied as UTC with the DST offset deducted
            # Must add the DST offset after retrieving to get the actual time - see https://learn.microsoft.com/en-us/previous-versions/windows/desktop/aa351886(v=vs.85)
            if ($currentDateTime.IsDaylightSavingTime())
            {
                $currentTimeZone = Get-TimeZone

                # Convert StatusNotificationTimeOfDay from a Timespan to a DateTimeOffset value defined in UTC
                $StatusNotificationTimeOfDayDateTimeOffset = [datetimeoffset]"$($StatusNotificationTimeOfDay.ToString('c'))Z"

                # Add the currently active DST offset to the retrieved DateTimeOffset to get UTC TimeOfDay as TimeSpan
                $StatusNotificationTimeOfDay = $StatusNotificationTimeOfDayDateTimeOffset + ([datetimeoffset]$currentDateTime).Offset - $currentTimeZone.BaseUtcOffset | Select-Object -ExpandProperty TimeOfDay
            }
            # Wrapped in @() to return array even if only one object is returned
            $StatusNotificationRecipients = @($WsusEmailNotificationConfiguration.StatusNotificationRecipients |
                Select-Object -ExpandProperty Address)
            Write-Verbose -Message ($script:localizedData.WsusStatusNotification -f $StatusNotificationFrequency, `
                $StatusNotificationTimeOfDay, $($StatusNotificationRecipients -join ','))
        }
        else {
            $StatusNotificationFrequency = ''
            $StatusNotificationTimeOfDay = ''
            $StatusNotificationRecipients = @()
        }

        $EmailLanguage = $WsusEmailNotificationConfiguration.EmailLanguage
        Write-Verbose -Message ($script:localizedData.WsusEmailLanguage -f $EmailLanguage)
        $SmtpHostName = $WsusEmailNotificationConfiguration.SmtpHostName
        Write-Verbose -Message ($script:localizedData.WsusSmtpHostName -f $SmtpHostName)
        if ($WsusEmailNotificationConfiguration.SmtpHostName)
        {
            $SmtpPort = $WsusEmailNotificationConfiguration.SmtpPort
            Write-Verbose -Message ($script:localizedData.WsusSmtpPort -f $SmtpPort)
        }
        else
        {
            $SmtpPort = 0
        }
        $SenderDisplayName = $WsusEmailNotificationConfiguration.SenderDisplayName
        Write-Verbose -Message ($script:localizedData.WsusSenderDisplayName -f $SenderDisplayName)
        $SenderEmailAddress = $WsusEmailNotificationConfiguration.SenderEmailAddress
        Write-Verbose -Message ($script:localizedData.WsusSenderEmailAddress -f $SenderEmailAddress)

        if ($WsusEmailNotificationConfiguration.SmtpHostName)
        {
            if ($WsusEmailNotificationConfiguration.SmtpServerRequiresAuthentication)
            {
                $SmtpUserName = $WsusEmailNotificationConfiguration.SmtpUserName
                Write-Verbose -Message ($script:localizedData.WsusSmtpServerUserName -f $SmtpUserName)
            }
            else
            {
                $SmtpUserName = ''
            }
        }
        else
        {
            $SmtpUserName = ''
        }

        Write-Verbose -Message $script:localizedData.GettingWsusIIsDynamicCompression
        $IIsDynamicCompression = ($null -ne ((Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup' `
            -ErrorAction SilentlyContinue) | Where-Object -Property Property -Contains 'IIsDynamicCompression'))
        Write-Verbose -Message ($script:localizedData.IIsDynamicCompression -f $IIsDynamicCompression)

        Write-Verbose -Message $script:localizedData.GettingWsusBitsDownloadPriorityForeground
        $BitsDownloadPriorityForeground = $WsusConfiguration.BitsDownloadPriorityForeground
        Write-Verbose -Message ($script:localizedData.BitsDownloadPriorityForeground -f $BitsDownloadPriorityForeground)

        Write-Verbose -Message $script:localizedData.GettingWsusLocalPublishingMaxCabSize
        $LocalPublishingMaxCabSize = $WsusConfiguration.LocalPublishingMaxCabSize
        Write-Verbose -Message ($script:localizedData.WsusLocalPublishingMaxCabSize -f $LocalPublishingMaxCabSize)

        Write-Verbose -Message $script:localizedData.GettingWsusMaxSimultaneousFileDownloads
        $MaxSimultaneousFileDownloads = $WsusConfiguration.MaxSimultaneousFileDownloads
        Write-Verbose -Message ($script:localizedData.WsusMaxSimultaneousFileDownloads -f $MaxSimultaneousFileDownloads)
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
        DownloadUpdateBinariesAsNeeded    = $DownloadUpdateBinariesAsNeeded
        DownloadExpressPackages           = $DownloadExpressPackages
        GetContentFromMU                  = $GetContentFromMU
        Languages                         = $Languages
        Products                          = $Products
        Classifications                   = $Classifications
        SynchronizeAutomatically          = $SynchronizeAutomatically
        SynchronizeAutomaticallyTimeOfDay = $SynchronizeAutomaticallyTimeOfDay
        SynchronizationsPerDay            = $SynchronizationsPerDay
        AutoApproveWsusInfrastructureUpdates = $AutoApproveWsusInfrastructureUpdates
        AutoRefreshUpdateApprovals        = $AutoRefreshUpdateApprovals
        AutoRefreshUpdateApprovalsDeclineExpired = $AutoRefreshUpdateApprovalsDeclineExpired
        ClientTargetingMode               = $ClientTargetingMode
        DoDetailedRollup                  = $DoDetailedRollup
        SyncNotificationRecipients        = $SyncNotificationRecipients
        StatusNotificationFrequency       = $StatusNotificationFrequency
        StatusNotificationTimeOfDay       = $StatusNotificationTimeOfDay
        StatusNotificationRecipients      = $StatusNotificationRecipients
        EmailLanguage                     = $EmailLanguage
        SmtpHostName                      = $SmtpHostName
        SmtpPort                          = $SmtpPort
        SenderDisplayName                 = $SenderDisplayName
        SenderEmailAddress                = [String]$SenderEmailAddress
        SmtpUserName                      = $SmtpUserName
        IIsDynamicCompression             = $IIsDynamicCompression
        BitsDownloadPriorityForeground    = $BitsDownloadPriorityForeground
        LocalPublishingMaxCabSize         = $LocalPublishingMaxCabSize
        MaxSimultaneousFileDownloads      = $MaxSimultaneousFileDownloads
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
        Credential to use when running setup.
        Applicable when using SQL as data store.

    .PARAMETER SQLServer
        Optionally specify a SQL instance to store WSUS data

    .PARAMETER ContentDir
        Location to store WSUS content files.
        Set as empty string ('') to download from Microsoft Update.

    .PARAMETER UpdateImprovementProgram
        Provide feedback to Microsoft to help improve WSUS

    .PARAMETER UpstreamServerName
        Name of another WSUS server to retrieve content from

    .PARAMETER UpstreamServerPort
        If getting content from another server, port for traffic

    .PARAMETER UpstreamServerSSL
        If getting content from another server, whether to encrypt the traffic

    .PARAMETER UpstreamServerReplica
        Boolean to specify whether to retrieve content from another server

    .PARAMETER ProxyServerName
        Host name of proxy server

    .PARAMETER ProxyServerPort
        Port of proxy server

    .PARAMETER ProxyServerCredential
        Credential to use when authenticating to proxy server

    .PARAMETER ProxyServerBasicAuthentication
        Use basic auth for proxy

    .PARAMETER DownloadUpdateBinariesAsNeeded
        Updates are downloaded only when they are approved

    .PARAMETER DownloadExpressPackages
        Express installation packages should be downloaded

    .PARAMETER GetContentFromMU
        Update binaries are downloaded from Microsoft Update instead of from the upstream server

    .PARAMETER Languages
        Specify list of languages for content, or '*' for all

    .PARAMETER Products
        List of products to include when synchronizing, by default Windows and Office

    .PARAMETER Classifications
        List of content classifications to synchronize to the WSUS server

    .PARAMETER SynchronizeAutomatically
        Automatically synchronize the WSUS instance

    .PARAMETER SynchronizeAutomaticallyTimeOfDay
        Time of day to schedule an automatic synchronization (as UTC)
        The value must be a string representation of a TimeSpan value
        The valid range is 00:00:00 to 23:59:59 inclusive

    .PARAMETER SynchronizationsPerDay
        Number of automatic synchronizations per day

    .PARAMETER Synchronize
        Run a synchronization immediately when running Set

    .PARAMETER AutoApproveWsusInfrastructureUpdates
        WSUS infrastructure updates are approved automatically

    .PARAMETER AutoRefreshUpdateApprovals
        The latest revision of an update should be approved automatically

    .PARAMETER AutoRefreshUpdateApprovalsDeclineExpired
        An update should be automatically declined when it is revised to be expired and
        AutoRefreshUpdateApprovals is enabled

    .PARAMETER ClientTargetingMode
        An enumerated value that describes how the Target Groups are populated.
        Accepts 'Client'(default) or 'Server'.

    .PARAMETER DoDetailedRollup
        The downstream server should roll up detailed computer and update status information

    .PARAMETER SyncNotificationRecipients
        E-mail addresses of those to whom notification of new updates should be sent, omit for no notifications

    .PARAMETER StatusNotificationFrequency
        The frequency with which e-mail notifications should be sent
        Accepts 'Daily'(default) or 'Weekly'

    .PARAMETER StatusNotificationTimeOfDay
        The time of the day e-mail notifications should be sent (as UTC)
        The value must be a string representation of a TimeSpan value
        The valid range is 00:00:00 to 23:59:59 inclusive

    .PARAMETER StatusNotificationRecipients
        E-mail addresses of those to whom update status notification should be sent, omit for no notifications

    .PARAMETER EmailLanguage
        E-mail language setting

    .PARAMETER SmtpHostName
        The host name of the SMTP server

    .PARAMETER SmtpPort
        The port number of the SMTP server

    .PARAMETER SenderDisplayName
        The display name of the e-mail sender

    .PARAMETER SenderEmailAddress
        The e-mail address of the sender

    .PARAMETER EmailServerCredential
        The e-mail server credential, omit for anonymous.

    .PARAMETER IIsDynamicCompression
        Use Xpress Encoding to compress update metadata.
        Results in significant bandwidth savings, at the expense of some CPU overhead.

    .PARAMETER BitsDownloadPriorityForeground
        Use foreground priority for BITS downloads to handle issues with proxy servers that do not correctly handle
        HTTP 1.1 range request.

    .PARAMETER LocalPublishingMaxCabSize
        The maximum .cab file size (in megabytes) that Local Publishing will create

    .PARAMETER MaxSimultaneousFileDownloads
        The maximum number of concurrent update downloads

#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
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
        $UpstreamServerSSL = $false,

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
        $ProxyServerBasicAuthentication = $false,

        [Parameter()]
        [System.Boolean]
        $DownloadUpdateBinariesAsNeeded,

        [Parameter()]
        [System.Boolean]
        $DownloadExpressPackages,

        [Parameter()]
        [System.Boolean]
        $GetContentFromMU,

        [Parameter()]
        [System.String[]]
        $Languages,

        [Parameter()]
        [System.String[]]
        $Products,

        [Parameter()]
        [System.String[]]
        $Classifications,

        [Parameter()]
        [System.Boolean]
        $SynchronizeAutomatically,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(0, 86399)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
        })]
        [System.String]
        $SynchronizeAutomaticallyTimeOfDay,

        [Parameter()]
        [ValidateRange(1, 24)]
        [System.UInt16]
        $SynchronizationsPerDay = 1,

        [Parameter()]
        [System.Boolean]
        $Synchronize,

        [Parameter()]
        [System.Boolean]
        $AutoApproveWsusInfrastructureUpdates,

        [Parameter()]
        [System.Boolean]
        $AutoRefreshUpdateApprovals,

        [Parameter()]
        [System.Boolean]
        $AutoRefreshUpdateApprovalsDeclineExpired,

        [Parameter()]
        [ValidateSet('Client', 'Server')]
        [System.String]
        $ClientTargetingMode,

        [Parameter()]
        [System.Boolean]
        $DoDetailedRollup,

        [Parameter()]
        [System.String[]]
        $SyncNotificationRecipients,

        [Parameter()]
        [ValidateSet('Daily', 'Weekly')]
        [System.String]
        $StatusNotificationFrequency,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(0, 86399)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
        })]
        [System.String]
        $StatusNotificationTimeOfDay,

        [Parameter()]
        [System.String[]]
        $StatusNotificationRecipients,

        [Parameter()]
        [System.String]
        $EmailLanguage,

        [Parameter()]
        [System.String]
        $SmtpHostName,

        [Parameter()]
        [System.UInt16]
        $SmtpPort = 25,

        [Parameter()]
        [System.String]
        $SenderDisplayName,

        [Parameter()]
        [System.String]
        $SenderEmailAddress,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $EmailServerCredential,

        [Parameter()]
        [System.Boolean]
        $IIsDynamicCompression,

        [Parameter()]
        [System.Boolean]
        $BitsDownloadPriorityForeground,

        [Parameter()]
        [System.UInt32]
        $LocalPublishingMaxCabSize,

        [Parameter()]
        [System.UInt32]
        $MaxSimultaneousFileDownloads
    )

    Assert-Module -ModuleName UpdateServices

    # Check whether the post installation tasks for the WSUS Services role still need to be run
    try
    {
        if (($WsusServer = Get-WsusServer) -and `
            (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup\Installed Role Services" `
                -Name 'UpdateServices-Services' -ErrorAction Stop).'UpdateServices-Services' -eq '2')
        {
            $PostInstall = $false
        }
        else
        {
            $PostInstall = $true
        }
    }
    catch
    {
        $PostInstall = $true
    }

    # Complete initial configuration
    if ($PostInstall)
    {
        Write-Verbose -Message $script:localizedData.RunningWsusPostInstall

        Import-Module $PSScriptRoot\..\..\Modules\PDT\PDT.psm1

        $Path = "$($env:ProgramFiles)\Update Services\Tools\WsusUtil.exe"
        $Path = Invoke-ResolvePath $Path
        Write-Verbose -Message ($script:localizedData.ResolveWsusUtilExePath -f $Path)

        $Arguments = 'postinstall'
        if ($PSBoundParameters.ContainsKey('SQLServer'))
        {
            $Arguments += " SQL_INSTANCE_NAME=$SQLServer"
        }
        if ($PSBoundParameters.ContainsKey('ContentDir'))
        {
            if ($ContentDir)
            {
                $Arguments += " CONTENT_DIR=$([Environment]::ExpandEnvironmentVariables($ContentDir))"
            }
        }

        Write-Verbose -Message ($script:localizedData.WsusUtilArgs -f $Arguments)

        if ($SetupCredential)
        {
            $Process = Start-Win32Process -Path $Path -Arguments $Arguments -Credential $SetupCredential
            Write-Verbose -Message $Process
            Wait-Win32ProcessEnd -Path $Path -Arguments $Arguments
        }
        else
        {
            $Process = Start-Win32Process -Path $Path -Arguments $Arguments
            Write-Verbose -Message $Process
            Wait-Win32ProcessEnd -Path $Path -Arguments $Arguments
        }
    }

    # Get WSUS server
    try
    {
        if ($WsusServer = Get-WsusServer)
        {
            $Wsus = $true
        }
    }
    catch
    {
        $Wsus = $false

        New-InvalidOperationException -Message $script:localizedData.WSUSConfigurationFailed -ErrorRecord $_
    }

    # Configure WSUS
    if ($Wsus)
    {
        Write-Verbose -Message $script:localizedData.ConfiguringWsus

        # Get configuration and make sure that the configuration can be saved before continuing
        $WsusConfiguration = $WsusServer.GetConfiguration()
        $WsusSubscription = $WsusServer.GetSubscription()
        $WsusEmailNotificationConfiguration = $WsusServer.GetEmailNotificationConfiguration()
        Write-Verbose -Message $script:localizedData.CheckPreviousConfig
        Save-WsusConfiguration

        # If this is not a replica server
        if (-not $UpstreamServerReplica)
        {
            # Configure Update Improvement Program
            if ($PSBoundParameters.ContainsKey('UpdateImprovementProgram'))
            {
                Write-Verbose -Message $script:localizedData.ConfiguringUpdateImprove
                $WsusConfiguration.MURollupOptin = $UpdateImprovementProgram
            }
        }

        # Configure Upstream Server
        if ($PSBoundParameters.ContainsKey('UpstreamServerName'))
        {
            if ($UpstreamServerName)
            {
                Write-Verbose -Message $script:localizedData.ConfiguringUpstreamServer
                $WsusConfiguration.SyncFromMicrosoftUpdate = $false
                $WsusConfiguration.UpstreamWsusServerName = $UpstreamServerName
                $WsusConfiguration.UpstreamWsusServerPortNumber = $UpstreamServerPort
                $WsusConfiguration.UpstreamWsusServerUseSsl = $UpstreamServerSSL
            }
            else
            {
                Write-Verbose -Message $script:localizedData.ConfiguringWsusMsftUpdates
                $WsusConfiguration.SyncFromMicrosoftUpdate = $true
            }
        }

        # Configure Upstream Server Replica separately as IsReplicaServer=$true prevents other settings even when SyncFromMicrosoftUpdate=$true
        if ($PSBoundParameters.ContainsKey('UpstreamServerReplica'))
        {
            if ($UpstreamServerName)
            {
                Write-Verbose -Message $script:localizedData.ConfiguringUpstreamServerReplica
                $WsusConfiguration.IsReplicaServer = $UpstreamServerReplica
            }
            else
            {
                if (-not $UpstreamServerReplica) # If no upstream server is configured, only set this if it is $false
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringUpstreamServerReplica
                    $WsusConfiguration.IsReplicaServer = $UpstreamServerReplica
                }
            }
        }

        # Configure Proxy Server
        if ($PSBoundParameters.ContainsKey('ProxyServerName'))
        {
            if ($ProxyServerName)
            {
                Write-Verbose -Message $script:localizedData.ConfiguringWsusProxy
                $WsusConfiguration.UseProxy = $true
                $WsusConfiguration.ProxyName = $ProxyServerName
                $WsusConfiguration.ProxyServerPort = $ProxyServerPort
                if ($PSBoundParameters.ContainsKey('ProxyServerCredential'))
                {
                    if ($ProxyServerCredential)
                    {
                        Write-Verbose -Message $script:localizedData.ConfiguringProxyCred
                        $WsusConfiguration.AnonymousProxyAccess = $false
                        $WsusConfiguration.ProxyUserDomain = $ProxyServerCredential.GetNetworkCredential().Domain
                        $WsusConfiguration.ProxyUserName = $ProxyServerCredential.GetNetworkCredential().UserName
                        $WsusConfiguration.SetProxyPassword($ProxyServerCredential.GetNetworkCredential().Password)
                        if ($PSBoundParameters.ContainsKey('ProxyServerBasicAuthentication'))
                        {
                            $WsusConfiguration.AllowProxyCredentialsOverNonSsl = $ProxyServerBasicAuthentication
                        }
                    }
                    else
                    {
                        Write-Verbose -Message $script:localizedData.RemovingProxyCred
                        $WsusConfiguration.AnonymousProxyAccess = $true
                    }
                }
            }
            else
            {
                Write-Verbose -Message $script:localizedData.ConfiguringNoProxy
                $WsusConfiguration.UseProxy = $false
            }
        }


        # Configure Update Files
        if ($PSBoundParameters.ContainsKey('ContentDir'))
        {
            if ($ContentDir)
            {
                Write-Verbose -Message $script:localizedData.ConfiguringUpdateFiles
                $WsusConfiguration.HostBinariesOnMicrosoftUpdate = $false
                if ($PSBoundParameters.ContainsKey('DownloadUpdateBinariesAsNeeded'))
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringDownloadUpdateBinariesAsNeeded
                    $WsusConfiguration.DownloadUpdateBinariesAsNeeded = $DownloadUpdateBinariesAsNeeded
                }
                if ($PSBoundParameters.ContainsKey('DownloadExpressPackages'))
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringDownloadExpressPackages
                    $WsusConfiguration.DownloadExpressPackages = $DownloadExpressPackages
                }
                # If we have an upstream server configured - otherwise no point configuring this
                if ($UpstreamServerName)
                {
                    if ($PSBoundParameters.ContainsKey('GetContentFromMU'))
                    {
                        Write-Verbose -Message $script:localizedData.ConfiguringGetContentFromMU
                        $WsusConfiguration.GetContentFromMU = $GetContentFromMU
                    }
                }

                # Languages
                if ($PSBoundParameters.ContainsKey('Languages'))
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringLanguages
                    if ($Languages -eq '*')
                    {
                        $WsusConfiguration.AllUpdateLanguagesEnabled = $true
                    }
                    else
                    {
                        $WsusConfiguration.AllUpdateLanguagesEnabled = $false
                        $WsusConfiguration.SetEnabledUpdateLanguages($Languages)
                    }
                }
            }
            else
            {
                Write-Verbose -Message $script:localizedData.ConfiguringHostMUStore
                $WsusConfiguration.HostBinariesOnMicrosoftUpdate = $true
            }
        }

        # If this is not a replica server
        if (-not $UpstreamServerReplica)
        {
            # Configure Advanced Automatic Approvals
            if ($PSBoundParameters.ContainsKey('AutoApproveWsusInfrastructureUpdates'))
            {
                Write-Verbose -Message $script:localizedData.ConfiguringAutoApproveWsusInfrastructureUpdates
                $WsusConfiguration.AutoApproveWsusInfrastructureUpdates = $AutoApproveWsusInfrastructureUpdates
            }
            if ($PSBoundParameters.ContainsKey('AutoRefreshUpdateApprovals'))
            {
                Write-Verbose -Message $script:localizedData.ConfiguringAutoRefreshUpdateApprovals
                $WsusConfiguration.AutoRefreshUpdateApprovals = $AutoRefreshUpdateApprovals
                if ($AutoRefreshUpdateApprovals)
                {
                    if ($PSBoundParameters.ContainsKey('AutoRefreshUpdateApprovalsDeclineExpired'))
                    {
                        Write-Verbose -Message $script:localizedData.ConfiguringAutoRefreshUpdateApprovalsDeclineExpired
                        $WsusConfiguration.AutoRefreshUpdateApprovalsDeclineExpired = $AutoRefreshUpdateApprovalsDeclineExpired
                    }
                }
            }
        }

        #ClientTargetingMode
        if ($PSBoundParameters.ContainsKey('ClientTargetingMode'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringClientTargetMode
            $WsusConfiguration.TargetingMode = $ClientTargetingMode
        }

        # Configure Email notifications
        if ($PSBoundParameters.ContainsKey('SyncNotificationRecipients'))
        {
            if ($SyncNotificationRecipients)
            {
                Write-Verbose -Message $script:localizedData.ConfiguringSyncNotificationRecipients
                $WsusEmailNotificationConfiguration.SendSyncNotification = $true
                $WsusEmailNotificationConfiguration.SyncNotificationRecipients.Clear()
                foreach ($syncNotificationRecipient in $SyncNotificationRecipients)
                {
                    $WsusEmailNotificationConfiguration.SyncNotificationRecipients.Add($syncNotificationRecipient)
                }
            }
            else
            {
                Write-Verbose -Message $script:localizedData.ConfiguringNoSyncNotificationRecipients
                $WsusEmailNotificationConfiguration.SendSyncNotification = $false
            }
        }

        if ($PSBoundParameters.ContainsKey('StatusNotificationRecipients'))
        {
            if ($StatusNotificationRecipients)
            {
                Write-Verbose -Message $script:localizedData.ConfiguringStatusNotificationRecipients
                $WsusEmailNotificationConfiguration.SendStatusNotification = $true
                $WsusEmailNotificationConfiguration.StatusNotificationRecipients.Clear()
                foreach ($statusNotificationRecipient in $StatusNotificationRecipients)
                {
                    $WsusEmailNotificationConfiguration.StatusNotificationRecipients.Add($statusNotificationRecipient)
                }
                if ($PSBoundParameters.ContainsKey('StatusNotificationFrequency'))
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringStatusNotificationFrequency
                    $WsusEmailNotificationConfiguration.StatusNotificationFrequency = $StatusNotificationFrequency
                }
                if ($PSBoundParameters.ContainsKey('StatusNotificationTimeOfDay'))
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringStatusNotificationTimeOfDay

                    $currentDateTime = Get-Date

                    # When Daylight Savings Time is in effect, StatusNotificationTimeOfDay needs to be set as UTC with the DST offset deducted
                    # Must remove the DST offset before applying to set the actual time - see https://learn.microsoft.com/en-us/previous-versions/windows/desktop/aa351886(v=vs.85)
                    if ($currentDateTime.IsDaylightSavingTime())
                    {
                        $currentTimeZone = Get-TimeZone

                        # Convert StatusNotificationTimeOfDay from a String to a DateTimeOffset value defined in UTC
                        $StatusNotificationTimeOfDayDateTimeOffset = [datetimeoffset]::Parse("$($StatusNotificationTimeOfDay)Z")

                        # Subtract the currently active DST offset from the supplied DateTimeOffset to get UTC TimeOfDay as TimeSpan
                        $StatusNotificationTimeOfDay = $StatusNotificationTimeOfDayDateTimeOffset - ([datetimeoffset]$currentDateTime).Offset + $currentTimeZone.BaseUtcOffset | Select-Object -ExpandProperty TimeOfDay
                    }

                    $WsusEmailNotificationConfiguration.StatusNotificationTimeOfDay = $StatusNotificationTimeOfDay
                }
            }
            else
            {
                Write-Verbose -Message $script:localizedData.ConfiguringNoStatusNotificationRecipients
                $WsusEmailNotificationConfiguration.SendStatusNotification = $false
            }
        }


        if ($PSBoundParameters.ContainsKey('EmailLanguage'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringEmailLanguage
            if ($WsusEmailNotificationConfiguration.SupportedEmailLanguages -contains $EmailLanguage)
            {
                $WsusEmailNotificationConfiguration.EmailLanguage = $EmailLanguage
            }
            else
            {
                New-InvalidOperationException -Message ($script:localizedData.UnsupportedEmailLanguage -f $EmailLanguage)
            }
        }

        if ($PSBoundParameters.ContainsKey('SmtpHostName'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringSmtpHostName
            $WsusEmailNotificationConfiguration.SmtpHostName = $SmtpHostName
            $WsusEmailNotificationConfiguration.SmtpPort = $SmtpPort
        }
        if ($PSBoundParameters.ContainsKey('SenderDisplayName'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringSenderDisplayName
            $WsusEmailNotificationConfiguration.SenderDisplayName = $SenderDisplayName
        }
        if ($PSBoundParameters.ContainsKey('SenderEmailAddress'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringSenderEmailAddress
            # If SenderEmailAddress is an empty string (''), need to set to $null instead
            if ($SenderEmailAddress)
            {
                $WsusEmailNotificationConfiguration.SenderEmailAddress = $SenderEmailAddress
            }
            else
            {
                $WsusEmailNotificationConfiguration.SenderEmailAddress = $null
            }
        }

        if ($SmtpHostName)
        {
            if ($PSBoundParameters.ContainsKey('EmailServerCredential'))
            {
                if ($EmailServerCredential)
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringEmailServerCredential
                    $WsusEmailNotificationConfiguration.SmtpServerRequiresAuthentication = $true
                    $WsusEmailNotificationConfiguration.SmtpUserName = $EmailServerCredential.GetNetworkCredential().UserName
                    $WsusEmailNotificationConfiguration.SetSmtpUserPassword($EmailServerCredential.GetNetworkCredential().Password)
                }
                else
                {
                    Write-Verbose -Message $script:localizedData.RemovingEmailServerCredential
                    $WsusEmailNotificationConfiguration.SmtpServerRequiresAuthentication = $false
                }
            }
        }

        # Save WSUS email configuration
        $WsusEmailNotificationConfiguration.Save()

        # Configure IIS dynamic compression
        if ($PSBoundParameters.ContainsKey('IIsDynamicCompression'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringIIsDynamicCompression
            if ($IIsDynamicCompression)
            {
                & $env:SystemRoot\System32\cscript.exe "$env:ProgramFiles\Update Services\Setup\DynamicCompression.vbs" /enable "$env:ProgramFiles\Update Services\WebServices\suscomp.dll" | Out-Null
            }
            else
            {
                & $env:SystemRoot\System32\cscript.exe "$env:ProgramFiles\Update Services\Setup\DynamicCompression.vbs" /disable | Out-Null
            }
        }

        # Configure BITS download priority foreground
        if ($PSBoundParameters.ContainsKey('BitsDownloadPriorityForeground'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringBitsDownloadPriorityForeground
            $WsusConfiguration.BitsDownloadPriorityForeground = $BitsDownloadPriorityForeground
        }

        # Configure local publishing
        if ($PSBoundParameters.ContainsKey('LocalPublishingMaxCabSize'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringLocalPublishing
            $WsusConfiguration.LocalPublishingMaxCabSize = $LocalPublishingMaxCabSize
        }

        # Configure max simultaneous file downloads
        if ($PSBoundParameters.ContainsKey('MaxSimultaneousFileDownloads'))
        {
            Write-Verbose -Message $script:localizedData.ConfiguringMaxSimultaneousFileDownloads
            $WsusConfiguration.MaxSimultaneousFileDownloads = $MaxSimultaneousFileDownloads
        }

        # Save configuration - avoid 'Operation is not valid due to the current state of the object' when DoDetailedRollup is being set
        Save-WsusConfiguration
   
        # If this is not a replica server
        if (-not $UpstreamServerReplica)
        {
            # Configure Reporting rollup
            if ($PSBoundParameters.ContainsKey('DoDetailedRollup'))
            {
                Write-Verbose -Message $script:localizedData.ConfiguringReportingRollup
                $WsusConfiguration.DoDetailedRollup = $DoDetailedRollup
            }
        }

        # Save configuration before initial sync
        Save-WsusConfiguration

        # If the initial configuration wizard flag is not yet set, perform initial sync
        if (-not $WsusConfiguration.OobeInitialized)
        {
            # If this is not a replica server
            if (-not $UpstreamServerReplica)
            {
                if ($PSBoundParameters.ContainsKey('Products'))
                {
                    Write-Verbose -Message $script:localizedData.RemovingDefaultProductsInit
                    # remove default products
                    foreach ($Product in ($WsusServer.GetSubscription().GetUpdateCategories().Title))
                    {
                        Get-WsusProduct | Where-Object -FilterScript { $_.Product.Title -eq $Product } |
                            Set-WsusProduct -Disable
                    }
                }

                if ($PSBoundParameters.ContainsKey('Classifications'))
                {
                    Write-Verbose -Message $script:localizedData.RemovingDefaultClassificationsInit
                    # remove default classifications
                    foreach ($Classification in `
                        ($WsusServer.GetSubscription().GetUpdateClassifications().ID.Guid))
                    {
                        Get-WsusClassification | Where-Object -FilterScript { $_.Classification.ID -eq $Classification } |
                            Set-WsusClassification -Disable
                    }
                }
            }

            if ($Synchronize)
            {
                Write-Verbose -Message $script:localizedData.RunningInitSync
                $WsusServer.GetSubscription().StartSynchronizationForCategoryOnly()
                while ($WsusServer.GetSubscription().GetSynchronizationStatus() -eq 'Running')
                {
                    Start-Sleep -Seconds 1
                }

                if ($WsusServer.GetSubscription().GetSynchronizationHistory()[0].Result -eq 'Succeeded')
                {
                    Write-Verbose -Message $script:localizedData.InitSyncSuccess
                    $WsusConfiguration.OobeInitialized = $true
                    Save-WsusConfiguration
                }
                else
                {
                    Write-Verbose -Message $script:localizedData.InitSyncFailure
                }
            }
            else
            {
                Write-Verbose -Message $script:localizedData.RunningInitOfflineSync

                $TempFile = [IO.Path]::GetTempFileName()

                $CABPath = Join-Path -Path $PSScriptRoot -ChildPath '\WSUS.cab'

                $Arguments = 'import '
                $Arguments += "`"$CABPath`" $TempFile"

                Write-Verbose -Message ($script:localizedData.WsusUtilArgs -f $Arguments)

                if ($PSBoundParameters.ContainsKey('SetupCredential'))
                {
                    $Process = Start-Win32Process -Path $Path -Arguments $Arguments -Credential $SetupCredential
                    Write-Verbose -Message $Process
                    Wait-Win32ProcessEnd -Path $Path -Arguments $Arguments
                }
                else
                {
                    $Process = Start-Win32Process -Path $Path -Arguments $Arguments
                    Write-Verbose -Message $Process
                    Wait-Win32ProcessEnd -Path $Path -Arguments $Arguments
                }

                $WsusConfiguration.OobeInitialized = $true
                Save-WsusConfiguration
            }
        }

        # If the initial configuration wizard flag is already set, configure WSUS subscription
        if ($WsusConfiguration.OobeInitialized)
        {
            $wsusSubscription = $WsusServer.GetSubscription()

            # If this is not a replica server
            if (-not $UpstreamServerReplica)
            {
                # Products
                if ($PSBoundParameters.ContainsKey('Products'))
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringProducts
                    $productCollection = New-Object Microsoft.UpdateServices.Administration.UpdateCategoryCollection
                    $allWsusProducts = $WsusServer.GetUpdateCategories()

                    switch ($Products)
                    {
                        # All Products
                        '*' {
                            Write-Verbose -Message $script:localizedData.ConfiguringAllProducts
                            foreach ($prdct in $AllWsusProducts)
                            {
                                $null = $productCollection.Add($WsusServer.GetUpdateCategory($prdct.Id))
                            }
                            continue
                        }
                        # if Products property contains wildcard like "Windows*"
                        {[System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($_)} {
                            $wildcardPrdct = $_
                            Write-Verbose -Message $($script:localizedData.ConfiguringWildcardProducts -f $wildcardPrdct)
                            if ($wsusProduct = $allWsusProducts | Where-Object -FilterScript { $_.Title -like $wildcardPrdct })
                            {
                                foreach ($prdct in $wsusProduct)
                                {
                                    $null = $productCollection.Add($WsusServer.GetUpdateCategory($prdct.Id))
                                }
                            }
                            else
                            {
                                Write-Verbose -Message $script:localizedData.NoWildcardProductFound
                            }
                            continue
                        }

                        <#
                            We can try to add GUID support for product with :

                            $StringGuid ="077e4982-4dd1-4d1f-ba18-d36e419971c1"
                            $ObjectGuid = [System.Guid]::New($StringGuid)
                            $IsEmptyGUID = $ObjectGuid -eq [System.Guid]::empty

                            Maybe with function
                        #>

                        default {
                            Write-Verbose -Message $($script:localizedData.ConfiguringNameProduct -f $_)
                            $prdct = $_
                            if ($WsusProduct = $allWsusProducts | Where-Object -FilterScript { $_.Title -eq $prdct })
                            {
                                foreach ($pdt in $WsusProduct)
                                {
                                    $null = $productCollection.Add($WsusServer.GetUpdateCategory($pdt.Id))
                                }
                            }
                            else
                            {
                                Write-Verbose -Message $script:localizedData.NoNameProductFound
                            }
                        }
                    }

                    $wsusSubscription.SetUpdateCategories($ProductCollection)
                }

                # Classifications
                if ($PSBoundParameters.ContainsKey('Classifications'))
                {
                    Write-Verbose -Message $script:localizedData.ConfiguringClassifications
                    $ClassificationCollection = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
                    $AllWsusClassifications = $WsusServer.GetUpdateClassifications()
                    if ($Classifications -eq '*')
                    {
                        foreach ($Classification in $AllWsusClassifications)
                        {
                            $null = $ClassificationCollection.Add($WsusServer.GetUpdateClassification($Classification.Id))
                        }
                    }
                    else
                    {
                        foreach ($Classification in $Classifications)
                        {
                            if ($WsusClassification = $AllWsusClassifications | Where-Object -FilterScript { $_.ID.Guid -eq $Classification })
                            {
                                $null = $ClassificationCollection.Add(
                                    $WsusServer.GetUpdateClassification($WsusClassification.Id)
                                )
                            }
                            else
                            {
                                Write-Verbose -Message ($script:localizedData.ClassificationNotFound -f $Classification)
                            }
                        }
                    }

                    $WsusSubscription.SetUpdateClassifications($ClassificationCollection)
                }
            }

            #Synchronization Schedule
            if ($PSBoundParameters.ContainsKey('SynchronizeAutomatically'))
            {
                Write-Verbose -Message $script:localizedData.ConfiguringSyncSchedule
                $WsusSubscription.SynchronizeAutomatically = $SynchronizeAutomatically
                if ($SynchronizeAutomatically)
                {
                    if ($PSBoundParameters.ContainsKey('SynchronizeAutomaticallyTimeOfDay'))
                    {
                        Write-Verbose -Message $script:localizedData.ConfiguringSyncTimeOfDay
                        $WsusSubscription.SynchronizeAutomaticallyTimeOfDay = $SynchronizeAutomaticallyTimeOfDay
                    }
                    if ($PSBoundParameters.ContainsKey('SynchronizationsPerDay'))
                    {
                        Write-Verbose -Message $script:localizedData.ConfiguringSyncPerDay
                        $WsusSubscription.NumberOfSynchronizationsPerDay = $SynchronizationsPerDay
                    }
                }
            }

            $WsusSubscription.Save()

            if ($Synchronize)
            {
                Write-Verbose -Message $script:localizedData.SynchronizingWsus

                $WsusServer.GetSubscription().StartSynchronization()
                while ($WsusServer.GetSubscription().GetSynchronizationStatus() -eq 'Running')
                {
                    Start-Sleep -Seconds 1
                }

                if ($WsusServer.GetSubscription().GetSynchronizationHistory()[0].Result -eq 'Succeeded')
                {
                    Write-Verbose -Message $script:localizedData.InitSyncSuccess
                }
                else
                {
                    Write-Verbose -Message $script:localizedData.InitSyncFailure
                }
            }
        }
    }

    if (-not (Test-TargetResource @PSBoundParameters))
    {
        $errorMessage = $script:localizedData.TestFailedAfterSet
        New-InvalidResultException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Configures a WSUS server instance

    .PARAMETER Ensure
        Determines if the task should be created or removed.
        Accepts 'Present'(default) or 'Absent'.

    .PARAMETER SetupCredential
        Credential to use when running setup.
        Applicable when using SQL as data store.

    .PARAMETER SQLServer
        Optionally specify a SQL instance to store WSUS data

    .PARAMETER ContentDir
        Location to store WSUS content files.
        Set as empty string ('') to download from Microsoft Update.

    .PARAMETER UpdateImprovementProgram
        Provide feedback to Microsoft to help improve WSUS

    .PARAMETER UpstreamServerName
        Name of another WSUS server to retrieve content from

    .PARAMETER UpstreamServerPort
        If getting content from another server, port for traffic

    .PARAMETER UpstreamServerSSL
        If getting content from another server, whether to encrypt the traffic

    .PARAMETER UpstreamServerReplica
        Boolean to specify whether to retrieve content from another server

    .PARAMETER ProxyServerName
        Host name of proxy server

    .PARAMETER ProxyServerPort
        Port of proxy server

    .PARAMETER ProxyServerCredential
        Credential to use when authenticating to proxy server

    .PARAMETER ProxyServerBasicAuthentication
        Use basic auth for proxy

    .PARAMETER ProxyServerBasicAuthentication
        Use basic auth for proxy

    .PARAMETER DownloadUpdateBinariesAsNeeded
        Updates are downloaded only when they are approved

    .PARAMETER DownloadExpressPackages
        Express installation packages should be downloaded

    .PARAMETER GetContentFromMU
        Update binaries are downloaded from Microsoft Update instead of from the upstream server

    .PARAMETER Languages
        Specify list of languages for content, or '*' for all

    .PARAMETER Products
        List of products to include when synchronizing, by default Windows and Office

    .PARAMETER Classifications
        List of content classifications to synchronize to the WSUS server

    .PARAMETER SynchronizeAutomatically
        Automatically synchronize the WSUS instance

    .PARAMETER SynchronizeAutomaticallyTimeOfDay
        Time of day to schedule an automatic synchronization (as UTC)

    .PARAMETER SynchronizationsPerDay
        Number of automatic synchronizations per day

    .PARAMETER Synchronize
        Run a synchronization immediately when running Set

    .PARAMETER AutoApproveWsusInfrastructureUpdates
        WSUS infrastructure updates are approved automatically

    .PARAMETER AutoRefreshUpdateApprovals
        The latest revision of an update should be approved automatically

    .PARAMETER AutoRefreshUpdateApprovalsDeclineExpired
        An update should be automatically declined when it is revised to be expired and
        AutoRefreshUpdateApprovals is enabled

    .PARAMETER ClientTargetingMode
        An enumerated value that describes how the Target Groups are populated.
        Accepts 'Client'(default) or 'Server'.

    .PARAMETER DoDetailedRollup
        The downstream server should roll up detailed computer and update status information

    .PARAMETER SyncNotificationRecipients
        E-mail addresses of those to whom notification of new updates should be sent, omit for no notifications

    .PARAMETER StatusNotificationFrequency
        The frequency with which e-mail notifications should be sent
        Accepts 'Daily'(default) or 'Weekly'

    .PARAMETER StatusNotificationTimeOfDay
        The time of the day e-mail notifications should be sent (as UTC)
        The value must be a string representation of a TimeSpan value
        The valid range is 00:00:00 to 23:59:59 inclusive

    .PARAMETER StatusNotificationRecipients
        E-mail addresses of those to whom update status notification should be sent, omit for no notifications

    .PARAMETER EmailLanguage
        E-mail language setting

    .PARAMETER SmtpHostName
        The host name of the SMTP server

    .PARAMETER SmtpPort
        The port number of the SMTP server

    .PARAMETER SenderDisplayName
        The display name of the e-mail sender

    .PARAMETER SenderEmailAddress
        The e-mail address of the sender

    .PARAMETER EmailServerCredential
        The e-mail server credential, omit for anonymous.

    .PARAMETER IIsDynamicCompression
        Use Xpress Encoding to compress update metadata.
        Results in significant bandwidth savings, at the expense of some CPU overhead.

    .PARAMETER BitsDownloadPriorityForeground
        Use foreground priority for BITS downloads to handle issues with proxy servers that do not correctly handle
        HTTP 1.1 range request.

    .PARAMETER LocalPublishingMaxCabSize
        The maximum .cab file size (in megabytes) that Local Publishing will create

    .PARAMETER MaxSimultaneousFileDownloads
        The maximum number of concurrent update downloads

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
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
        $UpstreamServerSSL = $false,

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
        $ProxyServerBasicAuthentication = $false,

        [Parameter()]
        [System.Boolean]
        $DownloadUpdateBinariesAsNeeded,

        [Parameter()]
        [System.Boolean]
        $DownloadExpressPackages,

        [Parameter()]
        [System.Boolean]
        $GetContentFromMU,

        [Parameter()]
        [System.String[]]
        $Languages,

        [Parameter()]
        [System.String[]]
        $Products,

        [Parameter()]
        [System.String[]]
        $Classifications,

        [Parameter()]
        [System.Boolean]
        $SynchronizeAutomatically,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(0, 86399)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
        })]
        [System.String]
        $SynchronizeAutomaticallyTimeOfDay,

        [Parameter()]
        [ValidateRange(1, 24)]
        [System.UInt16]
        $SynchronizationsPerDay = 1,

        [Parameter()]
        [System.Boolean]
        $Synchronize,

        [Parameter()]
        [System.Boolean]
        $AutoApproveWsusInfrastructureUpdates,

        [Parameter()]
        [System.Boolean]
        $AutoRefreshUpdateApprovals,

        [Parameter()]
        [System.Boolean]
        $AutoRefreshUpdateApprovalsDeclineExpired,

        [Parameter()]
        [ValidateSet('Client', 'Server')]
        [System.String]
        $ClientTargetingMode,

        [Parameter()]
        [System.Boolean]
        $DoDetailedRollup,

        [Parameter()]
        [System.String[]]
        $SyncNotificationRecipients,

        [Parameter()]
        [ValidateSet('Daily', 'Weekly')]
        [System.String]
        $StatusNotificationFrequency,

        [Parameter()]
        [ValidateScript({
            ([ValidateRange(0, 86399)]$valueInSeconds = [TimeSpan]::Parse($_).TotalSeconds); $?
        })]
        [System.String]
        $StatusNotificationTimeOfDay,

        [Parameter()]
        [System.String[]]
        $StatusNotificationRecipients,

        [Parameter()]
        [System.String]
        $EmailLanguage,

        [Parameter()]
        [System.String]
        $SmtpHostName,

        [Parameter()]
        [System.UInt16]
        $SmtpPort = 25,

        [Parameter()]
        [System.String]
        $SenderDisplayName,

        [Parameter()]
        [System.String]
        $SenderEmailAddress,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $EmailServerCredential,

        [Parameter()]
        [System.Boolean]
        $IIsDynamicCompression,

        [Parameter()]
        [System.Boolean]
        $BitsDownloadPriorityForeground,

        [Parameter()]
        [System.UInt32]
        $LocalPublishingMaxCabSize,

        [Parameter()]
        [System.UInt32]
        $MaxSimultaneousFileDownloads
    )

    Assert-Module -ModuleName UpdateServices

    $Wsus = Get-TargetResource -Ensure $Ensure

    # Test Ensure - if incorrect, return immediately without testing
    if ($Wsus.Ensure -ne $Ensure)
    {
        Write-Verbose -Message $script:localizedData.EnsureTestFailed
        return $false
    }

    # Flag to signal whether settings are correct
    $testTargetResourceReturnValue = $true

    if ($Ensure -eq 'Present')
    {
        # If this is not a replica server
        if (-not $UpstreamServerReplica)
        {
            # Test Update Improvement Program
            if ($PSBoundParameters.ContainsKey('UpdateImprovementProgram'))
            {
                if ($Wsus.UpdateImprovementProgram -ne $UpdateImprovementProgram)
                {
                    Write-Verbose -Message $script:localizedData.ImproveProgramTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }
        }

        # Test Upstream Server
        if ($PSBoundParameters.ContainsKey('UpstreamServerName'))
        {
            if ($Wsus.UpstreamServerName -ne $UpstreamServerName)
            {
                Write-Verbose -Message $script:localizedData.UpstreamNameTestFailed
                $testTargetResourceReturnValue = $false
            }

            if ($UpstreamServerName)
            {
                if ($Wsus.UpstreamServerPort -ne $UpstreamServerPort)
                {
                    Write-Verbose -Message $script:localizedData.UpstreamPortTestFailed
                    $testTargetResourceReturnValue = $false
                }
                if ($Wsus.UpstreamServerSSL -ne $UpstreamServerSSL)
                {
                    Write-Verbose -Message $script:localizedData.UpstreamSSLTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }
        }

        # Test Upstream Server Replica separately as IsReplicaServer=$true prevents other settings even when SyncFromMicrosoftUpdate=$true
        if ($PSBoundParameters.ContainsKey('UpstreamServerReplica'))
        {
            if ($UpstreamServerName)
            {
                if ($Wsus.UpstreamServerReplica -ne $UpstreamServerReplica)
                {
                    Write-Verbose -Message $script:localizedData.UpstreamReplicaTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }
            else
            {
                if (-not $UpstreamServerReplica -and $Wsus.UpstreamServerReplica -eq $true) # If no upstream server is configured, only fail the test if this is true
                {
                    Write-Verbose -Message $script:localizedData.NoUpstreamServerReplicaTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }

        }

        # Test Proxy Server
        if ($PSBoundParameters.ContainsKey('ProxyServerName'))
        {
            if ($Wsus.ProxyServerName -ne $ProxyServerName)
            {
                Write-Verbose -Message $script:localizedData.ProxyNameTestFailed
                $testTargetResourceReturnValue = $false
            }

            if ($ProxyServerName)
            {
                if ($Wsus.ProxyServerPort -ne $ProxyServerPort)
                {
                    Write-Verbose -Message $script:localizedData.ProxyPortTestFailed
                    $testTargetResourceReturnValue = $false
                }
                if ($PSBoundParameters.ContainsKey('ProxyServerCredential'))
                {
                    # Ensure that ProxyServerCredential is returned as string - if empty, otherwise returns $null
                    if ($Wsus.ProxyServerCredentialUserName -ne [String]$ProxyServerCredential.UserName)
                    {
                        Write-Verbose -Message $script:localizedData.ProxyCredTestFailed
                        $testTargetResourceReturnValue = $false
                    }
        
                    if ($ProxyServerCredential)
                    {
                        if ($PSBoundParameters.ContainsKey('ProxyServerBasicAuthentication'))
                        {
                            if ($Wsus.ProxyServerBasicAuthentication -ne $ProxyServerBasicAuthentication)
                            {
                                Write-Verbose -Message $script:localizedData.ProxyBasicAuthTestFailed
                                $testTargetResourceReturnValue = $false
                            }
                        }
                    }
                }
            }
        }

        # Test Update Files
        if ($PSBoundParameters.ContainsKey('ContentDir'))
        {
            if ((Join-Path $Wsus.ContentDir '') -ne (Join-Path $ContentDir ''))
            {
                Write-Verbose -Message $script:localizedData.ContentDirTestFailed
                $testTargetResourceReturnValue = $false
            }

            if ($ContentDir)
            {
                if ($PSBoundParameters.ContainsKey('DownloadUpdateBinariesAsNeeded'))
                {
                    if ($Wsus.DownloadUpdateBinariesAsNeeded -ne $DownloadUpdateBinariesAsNeeded)
                    {
                        Write-Verbose -Message $script:localizedData.UpdateFilesDownloadUpdateBinariesTestFailed
                        $testTargetResourceReturnValue = $false
                    }
                }
                if ($PSBoundParameters.ContainsKey('DownloadExpressPackages'))
                {
                    if ($Wsus.DownloadExpressPackages -ne $DownloadExpressPackages)
                    {
                        Write-Verbose -Message $script:localizedData.UpdateFilesDownloadExpressPackagesTestFailed
                        $testTargetResourceReturnValue = $false
                    }
                }
                if ($UpstreamServerName -eq '')
                {
                    if ($PSBoundParameters.ContainsKey('GetContentFromMU'))
                    {
                        if ($Wsus.GetContentFromMU -ne $GetContentFromMU)
                        {
                            Write-Verbose -Message $script:localizedData.UpdateFilesGetContentFromMUTestFailed
                            $testTargetResourceReturnValue = $false
                        }
                    }
                }

                # Test Languages
                if ($PSBoundParameters.ContainsKey('Languages'))
                {
                    if ($Wsus.Languages.count -le 1 -and $Languages.count -le 1 -and $Languages -ne '*')
                    {
                        if ($Wsus.Languages -notmatch $Languages)
                        {
                            Write-Verbose -Message $script:localizedData.LanguageAsStrTestFailed
                            $testTargetResourceReturnValue = $false
                        }
                    }
                    else
                    {
                        if ($null -ne (Compare-Object -ReferenceObject ($Wsus.Languages | Sort-Object -Unique) `
                                    -DifferenceObject ($Languages | Sort-Object -Unique) -SyncWindow 0))
                        {
                            Write-Verbose -Message $script:localizedData.LanguageSetTestFailed
                            $testTargetResourceReturnValue = $false
                        }
                    }
                }
            }
        }

        # If this is not a replica server
        if (-not $UpstreamServerReplica)
        {
            # Test Products
            if ($PSBoundParameters.ContainsKey('Products'))
            {
                try
                {
                    $wsusServer = Get-WsusServer -ErrorAction Stop
                }
                catch
                {
                    Write-Verbose -Message $script:localizedData.TestGetWsusServer
                    $testTargetResourceReturnValue = $false
                }
                $allWsusProducts = $wsusServer.GetUpdateCategories()
                [System.Collections.ArrayList]$productCollection = @()

                switch ($Products)
                {
                    # All Products
                    '*' {
                        Write-Verbose -Message $script:localizedData.GetAllProductForTest
                        $null = $productCollection.Add('*')
                        continue
                    }
                    # if Products property contains wild card like "Windows*"
                    {[System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($_)} {
                        $wildcardPrdct = $_
                        Write-Verbose -Message $($script:localizedData.GetWildCardProductForTest -f $wildcardPrdct)
                        if ($wsusProduct = $allWsusProducts | Where-Object -FilterScript { $_.Title -like $wildcardPrdct })
                        {
                            foreach ($pdt in $wsusProduct)
                            {
                                $null = $productCollection.Add($pdt.Title)
                            }
                        }
                        else
                        {
                            Write-Verbose -Message $script:localizedData.NoWildcardProductFound
                        }
                        continue
                    }

                    <#
                        We can try to add GUID support for product with :

                        $StringGuid ="077e4982-4dd1-4d1f-ba18-d36e419971c1"
                        $ObjectGuid = [System.Guid]::New($StringGuid)
                        $IsEmptyGUID = $ObjectGuid -eq [System.Guid]::empty

                        Maybe with function
                    #>

                    default {
                        $prdct = $_
                        Write-Verbose -Message $($script:localizedData.GetNameProductForTest -f $prdct)
                        if ($wsusProduct = $allWsusProducts | Where-Object -FilterScript { $_.Title -eq $prdct })
                        {
                            foreach ($pdt in $wsusProduct)
                            {
                                $null = $ProductCollection.Add($pdt.Title)
                            }
                        }
                        else
                        {
                            Write-Verbose -Message $script:localizedData.NoNameProductFound
                        }
                    }
                }


                if ($null -ne (Compare-Object -ReferenceObject ($Wsus.Products | Sort-Object -Unique) `
                            -DifferenceObject ($productCollection | Sort-Object -Unique) -SyncWindow 0))
                {
                    Write-Verbose -Message $script:localizedData.ProductTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }

            # Test Classifications
            if ($PSBoundParameters.ContainsKey('Classifications'))
            {
                if ($null -ne (Compare-Object -ReferenceObject ($Wsus.Classifications | Sort-Object -Unique) `
                            -DifferenceObject ($Classifications | Sort-Object -Unique) -SyncWindow 0))
                {
                    Write-Verbose -Message $script:localizedData.ClassificationsTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }
        }

        # Test Synchronization Schedule
        if ($PSBoundParameters.ContainsKey('SynchronizeAutomatically'))
        {
            if ($Wsus.SynchronizeAutomatically -ne $SynchronizeAutomatically)
            {
                Write-Verbose -Message $script:localizedData.SyncAutomaticallyTestFailed
                $testTargetResourceReturnValue = $false
            }
            if ($SynchronizeAutomatically)
            {
                if ($PSBoundParameters.ContainsKey('SynchronizeAutomaticallyTimeOfDay'))
                {
                    if ($Wsus.SynchronizeAutomaticallyTimeOfDay -ne $SynchronizeAutomaticallyTimeOfDay)
                    {
                        Write-Verbose -Message $script:localizedData.SyncTimeOfDayTestFailed
                        $testTargetResourceReturnValue = $false
                    }
                }
                if ($PSBoundParameters.ContainsKey('SynchronizationsPerDay'))
                {
                    if ($Wsus.SynchronizationsPerDay -ne $SynchronizationsPerDay)
                    {
                        Write-Verbose -Message $script:localizedData.SyncPerDayTestFailed
                        $testTargetResourceReturnValue = $false
                    }
                }
            }
        }

        # If this is not a replica server
        if (-not $UpstreamServerReplica)
        {
            # Test Advanced Automatic Approvals
            if ($PSBoundParameters.ContainsKey('AutoApproveWsusInfrastructureUpdates'))
            {
                if ($Wsus.AutoApproveWsusInfrastructureUpdates -ne $AutoApproveWsusInfrastructureUpdates)
                {
                    Write-Verbose -Message $script:localizedData.UpdateFilesAutoApproveWsusInfraTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }
            if ($PSBoundParameters.ContainsKey('AutoRefreshUpdateApprovals'))
            {
                if ($Wsus.AutoRefreshUpdateApprovals -ne $AutoRefreshUpdateApprovals)
                {
                    Write-Verbose -Message $script:localizedData.UpdateFilesAutoRefreshUpdateApprovalsTestFailed
                    $testTargetResourceReturnValue = $false
                }
                if ($AutoRefreshUpdateApprovals)
                {
                    if ($PSBoundParameters.ContainsKey('AutoRefreshUpdateApprovalsDeclineExpired'))
                    {
                        if ($Wsus.AutoRefreshUpdateApprovalsDeclineExpired -ne $AutoRefreshUpdateApprovalsDeclineExpired)
                        {
                            Write-Verbose -Message $script:localizedData.UpdateFilesAutoDeclineExpiredTestFailed
                            $testTargetResourceReturnValue = $false
                        }
                    }
                }
            }
        }

        # Test Client Targeting Mode
        if ($PSBoundParameters.ContainsKey('ClientTargetingMode'))
        {
            if ($Wsus.ClientTargetingMode -ne $ClientTargetingMode)
            {
                Write-Verbose -Message $script:localizedData.ClientTargetingModeTestFailed
                $testTargetResourceReturnValue = $false
            }
        }

        # If this is not a replica server
        if (-not $UpstreamServerReplica)
        {
            # Test Reporting rollup
            if ($PSBoundParameters.ContainsKey('DoDetailedRollup'))
            {
                if ($Wsus.DoDetailedRollup -ne $DoDetailedRollup)
                {
                    Write-Verbose -Message $script:localizedData.ReportingRollupDoDetailedRollupTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }
        }

        # Test Email notifications
        if ($PSBoundParameters.ContainsKey('SyncNotificationRecipients'))
        {
            if (($Wsus.SyncNotificationRecipients -isnot [Array] -and $Wsus.SyncNotificationRecipients -ne $SyncNotificationRecipients) -or
                ($Wsus.SyncNotificationRecipients -is [Array] -and $null -ne (Compare-Object -ReferenceObject $Wsus.SyncNotificationRecipients `
                -DifferenceObject $SyncNotificationRecipients -SyncWindow 0)))
            {
                Write-Verbose -Message $script:localizedData.SyncNotificationRecipientsTestFailed
                $testTargetResourceReturnValue = $false
            }
        }
        if ($PSBoundParameters.ContainsKey('StatusNotificationRecipients'))
        {
            if (($Wsus.StatusNotificationRecipients -isnot [Array] -and $Wsus.StatusNotificationRecipients -ne $StatusNotificationRecipients) -or
                ($StatusNotificationRecipients -is [Array] -and $null -ne (Compare-Object -ReferenceObject $Wsus.StatusNotificationRecipients `
                -DifferenceObject $StatusNotificationRecipients -SyncWindow 0)))
            {
                Write-Verbose -Message $script:localizedData.StatusNotificationRecipientsTestFailed
                $testTargetResourceReturnValue = $false
            }
            if ($StatusNotificationRecipients)
            {
                if ($PSBoundParameters.ContainsKey('StatusNotificationFrequency'))
                {
                    if ($Wsus.StatusNotificationFrequency -ne $StatusNotificationFrequency)
                    {
                        Write-Verbose -Message $script:localizedData.StatusNotificationFrequencyTestFailed
                        $testTargetResourceReturnValue = $false
                    }
                }
                if ($PSBoundParameters.ContainsKey('StatusNotificationTimeOfDay'))
                {
                    if ($Wsus.StatusNotificationTimeOfDay -ne $StatusNotificationTimeOfDay)
                    {
                        Write-Verbose -Message $script:localizedData.StatusNotificationTimeOfDayTestFailed
                        $testTargetResourceReturnValue = $false
                    }
                }
            }
        }
        if ($PSBoundParameters.ContainsKey('EmailLanguage'))
        {
            if ($Wsus.EmailLanguage -ne $EmailLanguage)
            {
                Write-Verbose -Message $script:localizedData.EmailLanguageTestFailed
                $testTargetResourceReturnValue = $false
            }
        }
        if ($PSBoundParameters.ContainsKey('SmtpHostName'))
        {
            if ($Wsus.SmtpHostName -ne $SmtpHostName)
            {
                Write-Verbose -Message $script:localizedData.SmtpHostNameTestFailed
                $testTargetResourceReturnValue = $false
            }
            if ($SmtpHostName)
            {
                if ($Wsus.SmtpPort -ne $SmtpPort)
                {
                    Write-Verbose -Message $script:localizedData.SmtpPortTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }
        }
        if ($PSBoundParameters.ContainsKey('SenderDisplayName'))
        {
            if ($Wsus.SenderDisplayName -ne $SenderDisplayName)
            {
                Write-Verbose -Message $script:localizedData.SenderDisplayNameTestFailed
                $testTargetResourceReturnValue = $false
            }
        }
        if ($PSBoundParameters.ContainsKey('SenderEmailAddress'))
        {
            if ($Wsus.SenderEmailAddress -ne $SenderEmailAddress)
            {
                Write-Verbose -Message $script:localizedData.SenderEmailAddressTestFailed
                $testTargetResourceReturnValue = $false
            }
        }
        if ($SmtpHostName)
        {
            if ($PSBoundParameters.ContainsKey('EmailServerCredential'))
            {
                if ($Wsus.SmtpUserName -ne $EmailServerCredential.UserName)
                {
                    Write-Verbose -Message $script:localizedData.EmailServerCredTestFailed
                    $testTargetResourceReturnValue = $false
                }
            }
        }

        # Test IIS dynamic compression
        if ($PSBoundParameters.ContainsKey('IIsDynamicCompression'))
        {
            if ($Wsus.IIsDynamicCompression -ne $IIsDynamicCompression)
            {
                Write-Verbose -Message $script:localizedData.IIsDynamicCompressionTestFailed
                $testTargetResourceReturnValue = $false
            }
        }

        # Test BITS download priority foreground
        if ($PSBoundParameters.ContainsKey('BitsDownloadPriorityForeground'))
        {
            if ($Wsus.BitsDownloadPriorityForeground -ne $BitsDownloadPriorityForeground)
            {
                Write-Verbose -Message $script:localizedData.BitsDownloadPriorityForegroundTestFailed
                $testTargetResourceReturnValue = $false
            }
        }

        # Test local publishing
        if ($PSBoundParameters.ContainsKey('LocalPublishingMaxCabSize'))
        {
            if ($Wsus.LocalPublishingMaxCabSize -ne $LocalPublishingMaxCabSize)
            {
                Write-Verbose -Message $script:localizedData.LocalPublishingMaxCabSizeTestFailed
                $testTargetResourceReturnValue = $false
            }
        }

        # Test max simultaneous file downloads
        if ($PSBoundParameters.ContainsKey('MaxSimultaneousFileDownloads'))
        {
            if ($Wsus.MaxSimultaneousFileDownloads -ne $MaxSimultaneousFileDownloads)
            {
                Write-Verbose -Message $script:localizedData.MaxSimultaneousFileDownloadsTestFailed
                $testTargetResourceReturnValue = $false
            }
        }
    }

    return $testTargetResourceReturnValue
}

<#
    .SYNOPSIS
        Saves the WSUS configuration

#>
function Save-WsusConfiguration
{
    param(
        [int]$Attempts = 30
    )
    $Count = 0
    do
    {
        try
        {
            Write-Verbose -Message ($script:localizedData.SavingWSUSConfiguration -f $Count)
            $WsusConfiguration.Save()
            $WsusConfigurationReady = $true
        }
        catch
        {
            $WsusConfigurationReady = $false
            $Count++
            Start-Sleep -Seconds 1
        }
    }
    until ($WsusConfigurationReady -or $Count -gt $Attempts)

    if (-not $WsusConfigurationReady)
    {
        New-InvalidOperationException -Message ($script:localizedData.FailedToSaveWSUSConfiguration -f $Attempts)
    }
}


Export-ModuleMember -Function *-TargetResource
