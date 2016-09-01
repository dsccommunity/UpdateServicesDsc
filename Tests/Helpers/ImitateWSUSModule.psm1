function Get-WsusServer {
    $WsusServer = [pscustomobject] @{
        Name = 'ServerName'
        }

    $ApprovalRule = [scriptblock]{
        $ApprovalRule = [pscustomobject]@{
                Name = 'ServerName'
                Enabled = $true
        }
    
        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
            $UpdateClassification = [pscustomobject]@{
                Name = 'Update Classification'
                    ID = [pscustomobject]@{
                        GUID = '00000000-0000-0000-0000-0000testguid'
                }
            }
            return $UpdateClassification
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetCategories -Value {
            $Products = [pscustomobject]@{
                Title = 'Product'
            }
            $Products | Add-Member -MemberType ScriptMethod -Name Add -Value {
                return $true
            }
            return $Products
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value {
            $ComputerTargetGroups = [pscustomobject]@{
                Name = 'Computer Target Group'
            }
            $ComputerTargetGroups | Add-Member -MemberType ScriptMethod -Name Add -Value {
                return $true
            }
            return $ComputerTargetGroups
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name Save -Value {
            return $true
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetCategories -Value {
            return $true
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetComputerTargetGroups -Value {
            return $true
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetUpdateClassifications -Value {
            return $true
        }

        return $ApprovalRule
    }
    
    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetInstallApprovalRules -Value $ApprovalRule

    $WsusServer | Add-Member -MemberType ScriptMethod -Name CreateInstallApprovalRule -Value $ApprovalRule

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateClassification -Value {
            return $true
    }
    
    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value {
            return $true
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name DeleteInstallApprovalRule -Value {
            return $true
    }
    
    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetSubscription -Value {
            return $true
    }

    return $WsusServer
}

function Get-WsusClassification {
    $WsusClassification = [pscustomobject]@{
        Classification = [pscustomobject]@{
            ID = [pscustomobject]@{
                Guid = '00000000-0000-0000-0000-0000testguid'
            }
        }
    }
    return $WsusClassification
}

function Get-WsusProduct {}
