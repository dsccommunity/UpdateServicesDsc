# Welcome to the UpdateServicesDsc wiki

<sup>*UpdateServicesDsc v#.#.#*</sup>

Here you will find all the information you need to make use of the UpdateServicesDsc
DSC resources, including details of the resources that are available, current
capabilities and known issues, and information to help plan a DSC based
implementation of UpdateServicesDsc.

Please leave comments, feature requests, and bug reports in the
[issues section](https://github.com/dsccommunity/UpdateServicesDsc/issues) for this module.

## Getting started

To get started download UpdateServicesDsc from the [PowerShell Gallery](http://www.powershellgallery.com/packages/UpdateServicesDsc/)
and then unzip it to one of your PowerShell modules folders
(such as $env:ProgramFiles\WindowsPowerShell\Modules).

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0)
run the following command:

```powershell
Find-Module -Name UpdateServicesDsc -Repository PSGallery | Install-Module
```

To confirm installation, run the below command and ensure you see the UpdateServicesDsc
DSC resources available:

```powershell
Get-DscResource -Module UpdateServicesDsc
```

## Change Log

A full list of changes in each version can be found in the [change log](https://github.com/dsccommunity/UpdateServicesDsc/blob/main/CHANGELOG.md).
