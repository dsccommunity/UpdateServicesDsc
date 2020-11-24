# Localized Strings for UpdateServicesApprovalRule resource
ConvertFrom-StringData @'
GetWsusServerFailed                 = Get-WsusServer failed to return a WSUS Server. The server may not yet have been configured.
WSUSConfigurationFailed             = WSUS Computer Target Group configuration failed.
GetWsusServerSucceeded              = WSUS Server information has been successfully retrieved from server '{0}'.
NotFoundComputerTargetGroup         = A Computer Target Group with Name '{0}' was not found at Path '{1}'.
DuplicateComputerTargetGroup        = A Computer Target Group with Name '{0}' already exists at Path '{1}'.
FoundComputerTargetGroup            = Successfully located Computer Target Group with Name '{0}' at Path '{1}' with ID '{2}'.
ResourceInDesiredState              = The Computer Target Group '{0}' at Path '{1}' is '{2}' which is the desired state.
ResourceNotInDesiredState           = The Computer Target Group '{0}' at Path '{1}' is '{2}' which is NOT the desired state.
FoundParentComputerTargetGroup      = Successfully located Parent Computer Target Group with Name '{0}' at Path '{1}' with ID '{2}'.
NotFoundParentComputerTargetGroup   = The Parent Computer Target Group with Name '{0}' was not found at Path '{1}'. The new Computer Target Group '{2}' cannot be created.
CreateComputerTargetGroupFailed     = An error occurred creating the Computer TargetGroup '{0}' at Path '{1}'.
CreateComputerTargetGroupSuccess    = The Computer Target Group '{0}' was successfully created at Path '{1}'.
DeleteComputerTargetGroupFailed     = An error occurred deleting the Computer TargetGroup '{0}' with ID '{1}' from Path '{2}'.
DeleteComputerTargetGroupSuccess    = The Computer Target Group '{0}' with ID '{1}' was successfully deleted from Path '{2}'.
'@
