# Localized Strings for UpdateServicesComputerTargetGroup resource
ConvertFrom-StringData @'
GetWsusServerFailed                 = Get-WsusServer failed to return a WSUS Server. The server may not yet have been configured. (USCTG0001)
WSUSConfigurationFailed             = WSUS Computer Target Group configuration failed. (USCTG0002)
GetWsusServerSucceeded              = WSUS Server information has been successfully retrieved from server '{0}'. (USCTG0003)
NotFoundComputerTargetGroup         = A Computer Target Group with Name '{0}' was not found at Path '{1}'. (USCTG0004)
DuplicateComputerTargetGroup        = A Computer Target Group with Name '{0}' already exists at Path '{1}'. (USCTG0005)
FoundComputerTargetGroup            = Successfully located Computer Target Group with Name '{0}' at Path '{1}' with ID '{2}'. (USCTG0006)
ResourceInDesiredState              = The Computer Target Group '{0}' at Path '{1}' is '{2}' which is the desired state. (USCTG0007)
ResourceNotInDesiredState           = The Computer Target Group '{0}' at Path '{1}' is '{2}' which is NOT the desired state. (USCTG0008)
FoundParentComputerTargetGroup      = Successfully located Parent Computer Target Group with Name '{0}' at Path '{1}' with ID '{2}'. (USCTG0009)
NotFoundParentComputerTargetGroup   = The Parent Computer Target Group with Name '{0}' was not found at Path '{1}'. The new Computer Target Group '{2}' cannot be created. (USCTG0010)
CreateComputerTargetGroupFailed     = An error occurred creating the Computer Target Group '{0}' at Path '{1}'. (USCTG0011)
CreateComputerTargetGroupSuccess    = The Computer Target Group '{0}' was successfully created at Path '{1}'. (USCTG0012)
DeleteComputerTargetGroupFailed     = An error occurred deleting the Computer Target Group '{0}' with ID '{1}' from Path '{2}'. (USCTG0013)
DeleteComputerTargetGroupSuccess    = The Computer Target Group '{0}' with ID '{1}' was successfully deleted from Path '{2}'. (USCTG0014)
'@
