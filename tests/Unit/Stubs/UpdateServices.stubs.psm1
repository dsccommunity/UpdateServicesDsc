# Name: UpdateServices
# Version: 2.0.0.0
# CreatedOn: 2025-10-08 17:52:16Z

Add-Type -IgnoreWarnings -WarningAction SilentlyContinue -TypeDefinition @'
namespace Microsoft.UpdateServices.Administration
{
    public class BiosInfo
    {
        public bool IsSecondaryStubType = true;

        public BiosInfo() { }
    }

    public enum ComputerRole : int
    {
        Unknown = 0,
        Workstation = 1,
        Server = 2,
    }

    [System.Flags]
    public enum DynamicCategoryType : int
    {
        ComputerModel = 1,
        Device = 2,
        Application = 4,
        Any = 255,
    }

    public class IComputerTarget
    {
        public bool IsSecondaryStubType = true;

        public IComputerTarget() { }
    }

    public class IDynamicCategory
    {
        // Property
        public System.String Name { get; set; }
        public System.Guid Id { get; set; }
        public Microsoft.UpdateServices.Administration.DynamicCategoryType Type { get; set; }
        public System.Boolean IsUpdateSyncEnabled { get; set; }
        public System.DateTime DiscoveryTime { get; set; }

        // Fabricated constructor
        private IDynamicCategory() { }
        public static IDynamicCategory CreateTypeInstance()
        {
            return new IDynamicCategory();
        }
    }

    public class IUpdate
    {
        public bool IsSecondaryStubType = true;

        public IUpdate() { }
    }

    public class IUpdateCategory
    {
        public bool IsSecondaryStubType = true;

        public IUpdateCategory() { }
    }

    public class IUpdateClassification
    {
        public bool IsSecondaryStubType = true;

        public IUpdateClassification() { }
    }

    public class IUpdateServer
    {
        // Property
        public System.String PreferredCulture { get; set; }
        public System.Version Version { get; set; }
        public System.String Name { get; set; }
        public System.Boolean IsConnectionSecureForApiRemoting { get; set; }
        public System.Int32 PortNumber { get; set; }
        public System.Version ServerProtocolVersion { get; set; }

        // Fabricated constructor
        private IUpdateServer() { }
        public static IUpdateServer CreateTypeInstance()
        {
            return new IUpdateServer();
        }
    }

    public class OSInfo
    {
        public bool IsSecondaryStubType = true;

        public OSInfo() { }
    }

    public enum SynchronizationResult : int
    {
        NeverRun = 0,
        Succeeded = 1,
        Failed = 2,
        Canceled = 3,
        Unknown = 4,
    }

    public enum UpdateApprovalAction : int
    {
        Install = 0,
        Uninstall = 1,
        NotApproved = 3,
        All = 2147483647,
    }

    [System.Flags]
    public enum UpdateInstallationStates : int
    {
        Unknown = 1,
        NotApplicable = 2,
        NotInstalled = 4,
        Downloaded = 8,
        Installed = 16,
        Failed = 32,
        InstalledPendingReboot = 64,
        All = -1,
    }

}

namespace Microsoft.UpdateServices.Commands
{
    public enum WsusApprovedState : int
    {
        Approved = 3,
        Unapproved = 4,
        AnyExceptDeclined = 7,
        Declined = 8,
    }

    public class WsusClassification
    {
        // Constructor
        public WsusClassification() { }

        // Property
        public Microsoft.UpdateServices.Administration.IUpdateServer UpdateServer { get; set; }
        public Microsoft.UpdateServices.Administration.IUpdateClassification Classification { get; set; }

    }

    public class WsusComputer
    {
        // Constructor
        public WsusComputer(Microsoft.UpdateServices.Administration.IUpdateServer updateServer, Microsoft.UpdateServices.Administration.IComputerTarget computer) { }

        // Property
        public Microsoft.UpdateServices.Administration.IUpdateServer UpdateServer { get; set; }
        public System.String Id { get; set; }
        public System.String FullDomainName { get; set; }
        public System.Net.IPAddress IPAddress { get; set; }
        public System.String Make { get; set; }
        public System.String Model { get; set; }
        public Microsoft.UpdateServices.Administration.BiosInfo BiosInfo { get; set; }
        public Microsoft.UpdateServices.Administration.OSInfo OSInfo { get; set; }
        public System.String OSArchitecture { get; set; }
        public System.Version ClientVersion { get; set; }
        public System.String OSFamily { get; set; }
        public System.String OSDescription { get; set; }
        public Microsoft.UpdateServices.Administration.ComputerRole ComputerRole { get; set; }
        public System.DateTime LastSyncTime { get; set; }
        public Microsoft.UpdateServices.Administration.SynchronizationResult LastSyncResult { get; set; }
        public System.DateTime LastReportedStatusTime { get; set; }
        public System.DateTime LastReportedInventoryTime { get; set; }
        public System.String RequestedTargetGroupName { get; set; }
        public System.Collections.ObjectModel.ReadOnlyCollection<System.Guid> ComputerTargetGroupIds { get; set; }
        public System.Collections.Specialized.StringCollection RequestedTargetGroupNames { get; set; }
        public System.Guid ParentServerId { get; set; }
        public System.Boolean SyncsFromDownstreamServer { get; set; }

        // Fabricated constructor
        private WsusComputer() { }
        public static WsusComputer CreateTypeInstance()
        {
            return new WsusComputer();
        }
    }

    [System.Flags]
    public enum WsusDynamicCategoryStatus : int
    {
        Blocked = 0,
        InventoryOnly = 1,
        SyncUpdates = 2,
    }

    public class WsusProduct
    {
        // Constructor
        public WsusProduct() { }

        // Property
        public Microsoft.UpdateServices.Administration.IUpdateCategory Product { get; set; }

    }

    public class WsusUpdate
    {
        // Constructor
        public WsusUpdate() { }
        public WsusUpdate(Microsoft.UpdateServices.Commands.WsusUpdate update) { }

        // Property
        public Microsoft.UpdateServices.Administration.IUpdate Update { get; set; }
        public System.String Classification { get; set; }
        public System.Int32 InstalledOrNotApplicablePercentage { get; set; }
        public System.String Approved { get; set; }
        public System.Int32 ComputersWithErrors { get; set; }
        public System.Int32 ComputersNeedingThisUpdate { get; set; }
        public System.Int32 ComputersInstalledOrNotApplicable { get; set; }
        public System.Int32 ComputersWithNoStatus { get; set; }
        public System.Collections.Specialized.StringCollection MsrcNumbers { get; set; }
        public System.Boolean Removable { get; set; }
        public System.String RestartBehavior { get; set; }
        public System.Boolean MayRequestUserInput { get; set; }
        public System.Boolean MustBeInstalledExclusively { get; set; }
        public System.String LicenseAgreement { get; set; }
        public System.Collections.Specialized.StringCollection Products { get; set; }
        public System.Collections.Specialized.StringCollection UpdatesSupersedingThisUpdate { get; set; }
        public System.Collections.Specialized.StringCollection UpdatesSupersededByThisUpdate { get; set; }
        public System.Collections.Specialized.StringCollection LanguagesSupported { get; set; }
        public System.String UpdateId { get; set; }

    }

    public enum WsusUpdateClassifications : int
    {
        All = 0,
        Critical = 1,
        Security = 2,
        WSUS = 3,
    }

    public enum WsusUpdateInstallationState : int
    {
        NoStatus = 1,
        InstalledOrNotApplicable = 18,
        InstalledOrNotApplicableOrNoStatus = 19,
        Failed = 32,
        Needed = 76,
        FailedOrNeeded = 108,
        Any = -1,
    }

}

'@

function Add-WsusComputer
{
    <#
    .SYNOPSIS
        Add-WsusComputer -Computer <WsusComputer> -TargetGroupName <string> [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Commands.WsusComputer]
        ${Computer},

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TargetGroupName}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Add-WsusDynamicCategory
{
    <#
    .SYNOPSIS
        Add-WsusDynamicCategory -InputObject <IDynamicCategory> [-UpdateServer <IUpdateServer>] [-WhatIf] [-Confirm] [<CommonParameters>]

Add-WsusDynamicCategory -Name <string> -DynamicCategoryType <DynamicCategoryType> [-UpdateServer <IUpdateServer>] [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.UpdateServices.Administration.IDynamicCategory]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [Alias('Type')]
        [Microsoft.UpdateServices.Administration.DynamicCategoryType]
        ${DynamicCategoryType}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Approve-WsusUpdate
{
    <#
    .SYNOPSIS
        Approve-WsusUpdate -Update <WsusUpdate> -Action <UpdateApprovalAction> -TargetGroupName <string> [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Commands.WsusUpdate]
        ${Update},

        [Parameter(Mandatory = $true)]
        [Microsoft.UpdateServices.Administration.UpdateApprovalAction]
        ${Action},

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${TargetGroupName}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Deny-WsusUpdate
{
    <#
    .SYNOPSIS
        Deny-WsusUpdate -Update <WsusUpdate> [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Commands.WsusUpdate]
        ${Update}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Get-WsusClassification
{
    <#
    .SYNOPSIS
        Get-WsusClassification [-UpdateServer <IUpdateServer>] [<CommonParameters>]
    #>

    [CmdletBinding()]
    [OutputType([Microsoft.UpdateServices.Commands.WsusClassification])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Get-WsusComputer
{
    <#
    .SYNOPSIS
        Get-WsusComputer [-UpdateServer <IUpdateServer>] [-All] [<CommonParameters>]

Get-WsusComputer [-UpdateServer <IUpdateServer>] [-NameIncludes <string>] [-ComputerTargetGroups <StringCollection>] [-IncludeSubgroups] [-ComputerUpdateStatus <WsusUpdateInstallationState>] [-ExcludedInstallationStates <UpdateInstallationStates[]>] [-IncludedInstallationStates <UpdateInstallationStates[]>] [-FromLastSyncTime <datetime>] [-ToLastSyncTime <datetime>] [-FromLastReportedStatusTime <datetime>] [-ToLastReportedStatusTime <datetime>] [-IncludeDownstreamComputerTargets] [-RequestedTargetGroupNames <StringCollection>] [<CommonParameters>]
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllComputers')]
    [OutputType([Microsoft.UpdateServices.Commands.WsusComputer])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [Parameter(ParameterSetName = 'AllComputers')]
        [switch]
        ${All},

        [Parameter(ParameterSetName = 'Scoped')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${NameIncludes},

        [Parameter(ParameterSetName = 'Scoped')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.StringCollection]
        ${ComputerTargetGroups},

        [Parameter(ParameterSetName = 'Scoped')]
        [ValidateNotNullOrEmpty()]
        [switch]
        ${IncludeSubgroups},

        [Parameter(ParameterSetName = 'Scoped')]
        [Microsoft.UpdateServices.Commands.WsusUpdateInstallationState]
        ${ComputerUpdateStatus},

        [Parameter(ParameterSetName = 'Scoped')]
        [Microsoft.UpdateServices.Administration.UpdateInstallationStates[]]
        ${ExcludedInstallationStates},

        [Parameter(ParameterSetName = 'Scoped')]
        [Microsoft.UpdateServices.Administration.UpdateInstallationStates[]]
        ${IncludedInstallationStates},

        [Parameter(ParameterSetName = 'Scoped')]
        [datetime]
        ${FromLastSyncTime},

        [Parameter(ParameterSetName = 'Scoped')]
        [datetime]
        ${ToLastSyncTime},

        [Parameter(ParameterSetName = 'Scoped')]
        [datetime]
        ${FromLastReportedStatusTime},

        [Parameter(ParameterSetName = 'Scoped')]
        [datetime]
        ${ToLastReportedStatusTime},

        [Parameter(ParameterSetName = 'Scoped')]
        [switch]
        ${IncludeDownstreamComputerTargets},

        [Parameter(ParameterSetName = 'Scoped')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.StringCollection]
        ${RequestedTargetGroupNames}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Get-WsusDynamicCategory
{
    <#
    .SYNOPSIS
        Get-WsusDynamicCategory [-UpdateServer <IUpdateServer>] [-DynamicCategoryTypeFilter <DynamicCategoryType>] [-First <long>] [-Skip <long>] [-WhatIf] [-Confirm] [<CommonParameters>]

Get-WsusDynamicCategory -DynamicCategoryType <DynamicCategoryType> -Name <string> [-UpdateServer <IUpdateServer>] [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(DefaultParameterSetName = 'Filter', SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [Alias('Type')]
        [Microsoft.UpdateServices.Administration.DynamicCategoryType]
        ${DynamicCategoryType},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'Filter')]
        [Alias('TypeFilter')]
        [System.Nullable[Microsoft.UpdateServices.Administration.DynamicCategoryType]]
        ${DynamicCategoryTypeFilter},

        [Parameter(ParameterSetName = 'Filter')]
        [System.Nullable[long]]
        ${First},

        [Parameter(ParameterSetName = 'Filter')]
        [System.Nullable[long]]
        ${Skip}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Get-WsusProduct
{
    <#
    .SYNOPSIS
        Get-WsusProduct [-UpdateServer <IUpdateServer>] [-TitleIncludes <string>] [<CommonParameters>]
    #>

    [CmdletBinding()]
    [OutputType([Microsoft.UpdateServices.Commands.WsusProduct])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [string]
        ${TitleIncludes}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Get-WsusServer
{
    <#
    .SYNOPSIS
        Get-WsusServer [<CommonParameters>]

Get-WsusServer [-Name] <string> -PortNumber <int> [-UseSsl] [<CommonParameters>]
    #>

    [CmdletBinding(DefaultParameterSetName = 'DefaultServer')]
    [OutputType([Microsoft.UpdateServices.Administration.IUpdateServer])]
    param (
        [Parameter(ParameterSetName = 'ServerSpecified', Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 256)]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ServerSpecified')]
        [switch]
        ${UseSsl},

        [Parameter(ParameterSetName = 'ServerSpecified', Mandatory = $true)]
        [int]
        ${PortNumber}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Get-WsusUpdate
{
    <#
    .SYNOPSIS
        Get-WsusUpdate -UpdateId <guid> [-UpdateServer <IUpdateServer>] [-RevisionNumber <int>] [<CommonParameters>]

Get-WsusUpdate [-UpdateServer <IUpdateServer>] [-Classification <WsusUpdateClassifications>] [-Approval <WsusApprovedState>] [-Status <WsusUpdateInstallationState>] [<CommonParameters>]
    #>

    [CmdletBinding()]
    [OutputType([Microsoft.UpdateServices.Commands.WsusUpdate])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [Parameter(ParameterSetName = 'ID', Mandatory = $true)]
        [guid]
        ${UpdateId},

        [Parameter(ParameterSetName = 'ID')]
        [int]
        ${RevisionNumber},

        [Parameter(ParameterSetName = 'Scoped')]
        [Microsoft.UpdateServices.Commands.WsusUpdateClassifications]
        ${Classification},

        [Parameter(ParameterSetName = 'Scoped')]
        [Microsoft.UpdateServices.Commands.WsusApprovedState]
        ${Approval},

        [Parameter(ParameterSetName = 'Scoped')]
        [Microsoft.UpdateServices.Commands.WsusUpdateInstallationState]
        ${Status}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Invoke-WsusServerCleanup
{
    <#
    .SYNOPSIS
        Invoke-WsusServerCleanup [-UpdateServer <IUpdateServer>] [-CleanupObsoleteComputers] [-CleanupObsoleteUpdates] [-CleanupUnneededContentFiles] [-CompressUpdates] [-DeclineExpiredUpdates] [-DeclineSupersededUpdates] [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [switch]
        ${CleanupObsoleteComputers},

        [switch]
        ${CleanupObsoleteUpdates},

        [switch]
        ${CleanupUnneededContentFiles},

        [switch]
        ${CompressUpdates},

        [switch]
        ${DeclineExpiredUpdates},

        [switch]
        ${DeclineSupersededUpdates}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Remove-WsusDynamicCategory
{
    <#
    .SYNOPSIS
        Remove-WsusDynamicCategory -InputObject <IDynamicCategory> [-UpdateServer <IUpdateServer>] [-WhatIf] [-Confirm] [<CommonParameters>]

Remove-WsusDynamicCategory -Name <string> -DynamicCategoryType <DynamicCategoryType> [-UpdateServer <IUpdateServer>] [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IDynamicCategory]
        ${InputObject},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [Alias('Type')]
        [Microsoft.UpdateServices.Administration.DynamicCategoryType]
        ${DynamicCategoryType}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Set-WsusClassification
{
    <#
    .SYNOPSIS
        Set-WsusClassification -Classification <WsusClassification> [-Disable] [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Commands.WsusClassification]
        ${Classification},

        [switch]
        ${Disable}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Set-WsusDynamicCategory
{
    <#
    .SYNOPSIS
        Set-WsusDynamicCategory -Name <string> -DynamicCategoryType <DynamicCategoryType> -Status <WsusDynamicCategoryStatus> [-UpdateServer <IUpdateServer>] [-WhatIf] [-Confirm] [<CommonParameters>]

Set-WsusDynamicCategory -InputObject <IDynamicCategory> [-UpdateServer <IUpdateServer>] [-Status <WsusDynamicCategoryStatus>] [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [string]
        ${Name},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [Alias('Type')]
        [Microsoft.UpdateServices.Administration.DynamicCategoryType]
        ${DynamicCategoryType},

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [Parameter(ParameterSetName = 'ByObject')]
        [System.Nullable[Microsoft.UpdateServices.Commands.WsusDynamicCategoryStatus]]
        ${Status},

        [Parameter(ParameterSetName = 'ByObject', Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.UpdateServices.Administration.IDynamicCategory]
        ${InputObject}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Set-WsusProduct
{
    <#
    .SYNOPSIS
        Set-WsusProduct -Product <WsusProduct> [-Disable] [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Commands.WsusProduct]
        ${Product},

        [switch]
        ${Disable}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

function Set-WsusServerSynchronization
{
    <#
    .SYNOPSIS
        Set-WsusServerSynchronization -SyncFromMU [-UpdateServer <IUpdateServer>] [-WhatIf] [-Confirm] [<CommonParameters>]

Set-WsusServerSynchronization -UssServerName <string> [-UpdateServer <IUpdateServer>] [-PortNumber <int>] [-UseSsl] [-Replica] [-WhatIf] [-Confirm] [<CommonParameters>]
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.UpdateServices.Administration.IUpdateServer]
        ${UpdateServer},

        [Parameter(ParameterSetName = 'SyncFromMU', Mandatory = $true)]
        [switch]
        ${SyncFromMU},

        [Parameter(ParameterSetName = 'Upstream', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 256)]
        [string]
        ${UssServerName},

        [Parameter(ParameterSetName = 'Upstream')]
        [int]
        ${PortNumber},

        [Parameter(ParameterSetName = 'Upstream')]
        [switch]
        ${UseSsl},

        [Parameter(ParameterSetName = 'Upstream')]
        [switch]
        ${Replica}
    )
    end
    {
        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
    }
}

