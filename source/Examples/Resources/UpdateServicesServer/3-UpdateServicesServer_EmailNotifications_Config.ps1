<#PSScriptInfo
.VERSION 1.0.0
.GUID fbbc8f14-b7e5-43ba-9caa-c1fb82f60e63
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/UpdateServicesDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/UpdateServicesDsc
.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png
.RELEASENOTES
First version.
#>

#Requires -Module UpdateServicesDsc

<#
    .SYNOPSIS
        Configure WSUS e-mail notifications.

    .DESCRIPTION
        This configuration sets up the SMTP server that WSUS sends e-mail through,
        subscribes recipients to new update notifications, and sends a weekly
        status summary.

        Both recipient lists can be set to an empty array to turn that kind of
        notification off.

        StatusNotificationTimeOfDay is given as UTC.

    .PARAMETER EmailServerCredential
        Credential used to authenticate to the SMTP server.

    .EXAMPLE
        UpdateServicesServer_EmailNotifications_Config -EmailServerCredential (Get-Credential)

        Compiles a configuration that sets up WSUS e-mail notifications.
#>
Configuration UpdateServicesServer_EmailNotifications_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $EmailServerCredential
    )

    Import-DscResource -ModuleName UpdateServicesDsc

    node localhost
    {
        UpdateServicesServer 'WsusEmailNotifications'
        {
            Ensure                       = 'Present'

            SmtpHostName                 = 'smtp.contoso.com'
            SmtpPort                     = 587
            EmailServerCredential        = $EmailServerCredential
            SenderDisplayName            = 'WSUS Server'
            SenderEmailAddress           = 'wsus@contoso.com'
            EmailLanguage                = 'en'

            # Notify these recipients as soon as new updates are synchronized.
            SyncNotificationRecipients   = @(
                'updates@contoso.com'
            )

            # Send a status summary once a week, at 07:00 UTC.
            StatusNotificationRecipients = @(
                'serveradmins@contoso.com'
                'helpdesk@contoso.com'
            )
            StatusNotificationFrequency  = 'Weekly'
            StatusNotificationTimeOfDay  = '07:00:00'
        }
    }
}
