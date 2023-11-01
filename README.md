# CivitAi Powershell Module

CivitAi PowerShell Module

#### Table of Contents

*   [Overview](#overview)
*   [How-to-use the module](#How-to-use-module)
*   [How-to-use the custom script](#How-to-use-script)

----------

## Overview

This is a [PowerShell](https://microsoft.com/powershell) [module](https://technet.microsoft.com/en-us/library/dd901839.aspx)
that provides stateless command-line interaction and automation for the
[CivitAi v1 API](https://github.com/civitai/civitai/wiki/REST-API-Reference).

----------

## How-to-use the module

Simply copy the 'CivitAi' module's folder containing psd1 and psdm1 under:

> '...pathTo\Documents\WindowsPowerShell\Modules'

*Then, open a fresh PowerShell session and start using the module's functions.*

Alternatively, you can use Import-Module to load it up in your PowerShell session: 

`Import-Module -FullyQualifiedName "...pathTo\CivitAi.psm1"`

Once loaded, to get a list of commands or functions: 

`Get-Command -Module CivitAi`

To get help on a specific command: 

`Get-Help Download-CivitAiModel -Full`

----------

## How-to-use the custom script

Simply copy the ps1 file locally to be able to use it.

To get help on its usage:

`Get-Help "...\Download-CivitAiModels.ps1" -Full`
