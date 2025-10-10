function Get-WsusServerTemplate
{
    $WsusServer = [PSCustomObject] @{
        Name = 'ServerName'
        }

    $ApprovalRule = [ScriptBlock] {
        $ApprovalRule = [PSCustomObject] @{
            Name = 'ServerName'
            Enabled = $true
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
        $UpdateClassification = [PSCustomObject] @{
            Name = 'Update Classification'
            ID = [PSCustomObject] @{
                GUID = '00000000-0000-0000-0000-0000testguid'
            }
        }

        return $UpdateClassification
    }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetCategories -Value {
            $Products = [PSCustomObject] @{
                Title = 'Product'
            }

            $Products | Add-Member -MemberType ScriptMethod -Name Add -Value {}

            return $Products
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value {
            $ComputerTargetGroups = [PSCustomObject] @{
                Name = 'Computer Target Group'
            }

            $ComputerTargetGroups | Add-Member -MemberType ScriptMethod -Name Add -Value {}

            return $ComputerTargetGroups
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name Save -Value {}

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetCategories -Value {}

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetComputerTargetGroups -Value {}

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name SetUpdateClassifications -Value {}

        return $ApprovalRule
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetInstallApprovalRules -Value $ApprovalRule

    $WsusServer | Add-Member -MemberType ScriptMethod -Name CreateInstallApprovalRule -Value $ApprovalRule

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateClassification -Value {}

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value {}

    $WsusServer | Add-Member -MemberType ScriptMethod -Name DeleteInstallApprovalRule -Value {}

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetSubscription -Value {
            $Subscription = [PSCustomObject] @{
                SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                NumberOfSynchronizationsPerDay = 24
                SynchronizeAutomatically = $true
            }

            $Subscription | Add-Member -MemberType ScriptMethod -Name StartSynchronization -Value {}
            $Subscription | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
                $UpdateClassification = [PSCustomObject] @{
                    Name = 'Update Classification'
                    ID = [PSCustomObject] @{
                        GUID = '00000000-0000-0000-0000-0000testguid'
                    }
                }

                return $UpdateClassification
            }

            $Subscription | Add-Member -MemberType ScriptMethod -Name GetUpdateCategories -Value {
                $Categories = [PSCustomObject] @{
                    Title = 'Windows'
                },
                [PSCustomObject] @{
                    Title = 'Office'
                }

                return $Categories
            }

            return $Subscription
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetConfiguration -Value {
        $Configuration = @{
            ProxyName = ''
            ProxyServerPort = $null
            ProxyServerBasicAuthentication = $false
            UpstreamWsusServerName = ''
            UpstreamWsusServerPortNumber = $null
            UpStreamServerSSL =  $false
            MURollupOptin = $true
            AllUpdateLanguagesEnabled = $true
        }
        $Configuration | Add-Member -MemberType ScriptMethod -Name GetEnabledUpdateLanguages -Value {}

        return $Configuration
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
        $UpdateClassification = [PSCustomObject] @{
            Name = 'Update Classification'
            ID = [PSCustomObject] @{
                GUID = '00000000-0000-0000-0000-0000testguid'
            }
        }

        return $UpdateClassification
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateCategories -Value {
        $Categories = [PSCustomObject] @{
            Title = 'Windows'
        },
        [PSCustomObject] @{
            Title = 'Office'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2003'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2008'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2008R2'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2012'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2016'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2019'
        }

        return $Categories
    }

    return $WsusServer
}

function Get-WsusServerMockWildCardPrdt
{
    $wsusServer = Get-WsusServerTemplate

    # Override GetSubscription method
    $WsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetSubscription -Value {
        $Subscription = [PSCustomObject] @{
            SynchronizeAutomaticallyTimeOfDay = '04:00:00'
            NumberOfSynchronizationsPerDay = 24
            SynchronizeAutomatically = $true
        }

        $Subscription | Add-Member -MemberType ScriptMethod -Name StartSynchronization -Value {}
        $Subscription | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
            $UpdateClassification = [PSCustomObject] @{
                Name = 'Update Classification'
                ID = [PSCustomObject] @{
                    GUID = '00000000-0000-0000-0000-0000testguid'
                }
            }

            return $UpdateClassification
        }

        $Subscription | Add-Member -Force -MemberType ScriptMethod -Name GetUpdateCategories -Value {
            $Categories = [PSCustomObject] @{
                Title = 'Windows Server 2003'
            },
            [PSCustomObject] @{
                Title = 'Windows Server 2008'
            },
            [PSCustomObject] @{
                Title = 'Windows Server 2008R2'
            },
            [PSCustomObject] @{
                Title = 'Windows Server 2012'
            },
            [PSCustomObject] @{
                Title = 'Windows Server 2016'
            },
            [PSCustomObject] @{
                Title = 'Windows Server 2019'
            }

            return $Categories
        }

        return $Subscription
    }

    # Override GetUpdateCategories method
    $WsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetUpdateCategories -Value {
        $Categories = [PSCustomObject] @{
            Title = 'Windows'
        },
        [PSCustomObject] @{
            Title = 'Office'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2003'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2008'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2008R2'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2012'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2016'
        },
        [PSCustomObject] @{
            Title = 'Windows Server 2019'
        }

        return $Categories
    }

    return $WsusServer
}
