<#
.SYNOPSIS
Publish or unpublish a HayMint item. Published items must be complete.
.EXAMPLE
.\tools\Set-HayMintStatus.ps1 -Type product -Id desk-organizer -Status draft
#>
[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('product','video','guide')][string]$Type,
[Parameter(Mandatory=$true)][string]$Id,
[Parameter(Mandatory=$true)][ValidateSet('published','draft')][string]$Status)
$ErrorActionPreference='Stop'
try {
 . (Join-Path $PSScriptRoot 'Common.ps1')
 $path=Get-DataPath $Type; $items=@(Read-Items $path)
 $key=if($Type -eq 'guide'){'slug'}else{'id'}
 $found=@($items | Where-Object { $_.$key -ceq $Id })
 if($found.Count -ne 1){throw "Expected one $Type with $key '$Id'; found $($found.Count)."}
 $found[0].status=$Status
 if($Type -ne 'video'){$found[0].updatedAt=Get-Date -Format 'yyyy-MM-dd'}
 if($Status -eq 'published'){Assert-Item $found[0] $Type -CheckFiles}
 Write-Json $path @($items)
 Write-Output "Set '$Id' to $Status."
} catch { throw "Set-HayMintStatus failed: $($_.Exception.Message)" }
