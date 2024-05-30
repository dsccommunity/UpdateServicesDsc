function Get-WsusServerTemplate
{
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

            $Products | Add-Member -MemberType ScriptMethod -Name Add -Value {}

            return $Products
        }

        $ApprovalRule | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value {
            $ComputerTargetGroups = [pscustomobject]@{
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

    $ComputerTargetGroups = [scriptblock]{
        $ComputerTargetGroups = @(
            [pscustomobject] @{
                Name = 'All Computers'
                Id = [pscustomobject] @{
                    GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                }
            },
            [pscustomobject] @{
                Name = 'Servers'
                Id = [pscustomobject] @{
                    GUID = '14adceba-ddf3-4299-9c1a-e4cf8bd56c47'
                }
                ParentTargetGroup = [pscustomobject] @{
                    Name = 'All Computers'
                    Id = [pscustomobject] @{
                        GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                    }
                }
                ChildTargetGroup = [pscustomobject] @{
                    Name = 'Web'
                    Id = [pscustomobject] @{
                        GUID = 'f4aa59c7-e6a0-4e6d-97b0-293d00a0dc60'
                    }
                }
            },
            [pscustomobject] @{
                Name = 'Web'
                Id = [pscustomobject] @{
                    GUID = 'f4aa59c7-e6a0-4e6d-97b0-293d00a0dc60'
                }
                ParentTargetGroup = [pscustomobject] @{
                    Name = 'Servers'
                    Id = [pscustomobject] @{
                        GUID = '14adceba-ddf3-4299-9c1a-e4cf8bd56c47'
                    }
                    ParentTargetGroup = [pscustomobject] @{
                        Name = 'All Computers'
                        Id = [pscustomobject] @{
                            GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                        }
                    }
                }
            },
            [pscustomobject] @{
                Name = 'Workstations'
                Id = [pscustomobject] @{
                    GUID = '31742fd8-df6f-4836-82b4-b2e52ee4ba1b'
                }
                ParentTargetGroup = [pscustomobject] @{
                    Name = 'All Computers'
                    Id = [pscustomobject] @{
                        GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                    }
                }
            },
            [pscustomobject] @{
                Name = 'Desktops'
                Id = [pscustomobject] @{
                    GUID = '2b77a9ce-f320-41c7-bec7-9b22f67ae5b1'
                }
                ParentTargetGroup = [pscustomobject] @{
                    Name = 'Workstations'
                    Id = [pscustomobject] @{
                        GUID = '31742fd8-df6f-4836-82b4-b2e52ee4ba1b'
                    }
                    ParentTargetGroup = [pscustomobject] @{
                        Name = 'All Computers'
                        Id = [pscustomobject] @{
                            GUID = '4be27a8d-b969-4a8a-9cae-ec6b3a282b0b'
                        }
                    }
                }
            }
        )

        foreach ($ComputerTargetGroup in $ComputerTargetGroups)
        {
            Add-Member -InputObject $ComputerTargetGroup -MemberType ScriptMethod -Name Delete -Value {}

            Add-Member -InputObject $ComputerTargetGroup -MemberType ScriptMethod -Name GetParentTargetGroup -Value {
                return $this.ParentTargetGroup
            }

            if ($null -ne $ComputerTargetGroup.ParentTargetGroup)
            {
                Add-Member -InputObject $ComputerTargetGroup.ParentTargetGroup -MemberType ScriptMethod -Name GetParentTargetGroup -Value {
                    return $this.ParentTargetGroup
                }
            }

            if ($null -ne $ComputerTargetGroup.ChildTargetGroup)
            {
                Add-Member -InputObject $ComputerTargetGroup -MemberType ScriptMethod -Name GetChildTargetGroups -Value {
                    return $this.ChildTargetGroup
                }

                Add-Member -InputObject $ComputerTargetGroup.ChildTargetGroup -MemberType ScriptMethod -Name Delete -Value {}
            }
        }

        return $ComputerTargetGroups
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name CreateComputerTargetGroup -Value {
        param
        (
            [Parameter(Mandatory = $true)]
            [string]
            $Name,

            [Parameter(Mandatory = $true)]
            [object]
            $ComputerTargetGroup
        )
        {
            Write-Output $Name
            Write-Output $ComputerTargetGroup
        }
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetInstallApprovalRules -Value $ApprovalRule

    $WsusServer | Add-Member -MemberType ScriptMethod -Name CreateInstallApprovalRule -Value $ApprovalRule

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateClassification -Value {}

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value {}

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetComputerTargetGroups -Value $ComputerTargetGroups

    $WsusServer | Add-Member -MemberType ScriptMethod -Name DeleteInstallApprovalRule -Value {}

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetSubscription -Value {
            $Subscription = [pscustomobject]@{
                SynchronizeAutomaticallyTimeOfDay = '04:00:00'
                NumberOfSynchronizationsPerDay = 24
                SynchronizeAutomatically = $true
            }

            $Subscription | Add-Member -MemberType ScriptMethod -Name StartSynchronization -Value {}
            $Subscription | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
                $UpdateClassification = [pscustomobject]@{
                    Name = 'Update Classification'
                    ID = [pscustomobject]@{
                        GUID = '00000000-0000-0000-0000-0000testguid'
                    }
                }

                return $UpdateClassification
            }

            $Subscription | Add-Member -MemberType ScriptMethod -Name GetUpdateCategories -Value {
                $Categories = [pscustomobject]@{
                    Title = 'Windows'
                },
                [pscustomobject]@{
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
        $UpdateClassification = [pscustomobject]@{
            Name = 'Update Classification'
            ID = [pscustomobject]@{
                GUID = '00000000-0000-0000-0000-0000testguid'
            }
        }

        return $UpdateClassification
    }

    $WsusServer | Add-Member -MemberType ScriptMethod -Name GetUpdateCategories -Value {
        $Categories = [pscustomobject]@{
            Title = 'Windows'
        },
        [pscustomobject]@{
            Title = 'Office'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2003'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2008'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2008R2'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2012'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2016'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2019'
        }

        return $Categories
    }

    return $WsusServer
}

function Get-WsusServer
{
    return $(Get-WsusServerTemplate)
}

function Get-WsusServerMockWildCardPrdt
{
    $wsusServer = Get-WsusServerTemplate

    # Override GetSubscription method
    $WsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetSubscription -Value {
        $Subscription = [pscustomobject]@{
            SynchronizeAutomaticallyTimeOfDay = '04:00:00'
            NumberOfSynchronizationsPerDay = 24
            SynchronizeAutomatically = $true
        }

        $Subscription | Add-Member -MemberType ScriptMethod -Name StartSynchronization -Value {}
        $Subscription | Add-Member -MemberType ScriptMethod -Name GetUpdateClassifications -Value {
            $UpdateClassification = [pscustomobject]@{
                Name = 'Update Classification'
                ID = [pscustomobject]@{
                    GUID = '00000000-0000-0000-0000-0000testguid'
                }
            }

            return $UpdateClassification
        }

        $Subscription | Add-Member -Force -MemberType ScriptMethod -Name GetUpdateCategories -Value {
            $Categories = [pscustomobject]@{
                Title = 'Windows Server 2003'
            },
            [pscustomobject]@{
                Title = 'Windows Server 2008'
            },
            [pscustomobject]@{
                Title = 'Windows Server 2008R2'
            },
            [pscustomobject]@{
                Title = 'Windows Server 2012'
            },
            [pscustomobject]@{
                Title = 'Windows Server 2016'
            },
            [pscustomobject]@{
                Title = 'Windows Server 2019'
            }

            return $Categories
        }

        return $Subscription
    }

    # Override GetUpdateCategories method
    $WsusServer | Add-Member -Force -MemberType ScriptMethod -Name GetUpdateCategories -Value {
        $Categories = [pscustomobject]@{
            Title = 'Windows'
        },
        [pscustomobject]@{
            Title = 'Office'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2003'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2008'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2008R2'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2012'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2016'
        },
        [pscustomobject]@{
            Title = 'Windows Server 2019'
        }

        return $Categories
    }

    return $WsusServer
}
function Get-WsusClassification
{
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
