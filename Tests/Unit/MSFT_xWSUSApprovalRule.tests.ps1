<#
.Synopsis
   Unit tests for xWSUSApprovalRule
.DESCRIPTION
   Unit tests for xWSUSApprovalRule

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>

$Global:DSCModuleName      = 'xWSUS' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xWSUSApprovalRule' # Example MSFT_xFirewall

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion


# Begin Testing
try
{

    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        $global:WsusServer = [pscustomobject] @{
            Name = 'mockedServerName'
            }
        $global:ApprovalRule = [pscustomobject] @{
            Name = 'mockedRuleName'
            Enabled = $true
            }    
        #endregion

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            
            Mock Get-WsusServer {return $global:WsusServer} -verifiable
            $resource = Get-TargetResource -Name 'mockedName' -verbose

            it "Ensure" {
                $resource.Ensure | should be 'Present'
            } 

            it "Classifications" {
                $resource.Classifications | should be 'All Classifications'
            }

            it "Products" {
                $resource.Products | should be 'All Products'
            }

            it "Computer Groups" {
                $resource.ComputerGroups | should be 'All Computers'
            }

            it "Enabled" {
                $resource.Enabled | should be true
            }

            it "all the get mocks should be called" {
                Assert-VerifiableMocks
            }
            
        }
        #endregion

    }
}

finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

}
