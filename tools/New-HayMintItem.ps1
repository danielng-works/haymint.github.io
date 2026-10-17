<#
.SYNOPSIS
Add an original HayMint product, video or guide. Defaults to draft.
.EXAMPLE
.\tools\New-HayMintItem.ps1 -Type product -Name 'Desk organizer' -Category desk -Subcategory phu-kien-ban -Description 'Neutral description'
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidateSet('product','video','guide')][string]$Type,
 [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Name,
 [Parameter(Mandatory=$true)][string]$Category,
 [Parameter(Mandatory=$true)][string]$Subcategory,
 [string[]]$Tags=@(), [string]$ShopeeUrl='', [string]$VideoUrl='',
 [string]$Image='', [string]$Description='',
 [ValidateSet('published','draft')][string]$Status='draft',
 [string]$Duration='', [object[]]$Sections=@(), [string[]]$RelatedProductIds=@()
)
$ErrorActionPreference='Stop'
try {
 . (Join-Path $PSScriptRoot 'Common.ps1')
 Assert-Taxonomy $Category $Subcategory
 $path=Get-DataPath $Type
 $items=@(Read-Items $path)
 $id=Get-Slug $Name
 $key=if($Type -eq 'guide'){'slug'}else{'id'}
 $base=$id; $number=2
 while (@($items | Where-Object { $_.$key -eq $id }).Count -gt 0) { $id="$base-$number"; $number++ }
 $today=Get-Date -Format 'yyyy-MM-dd'
 $item=[ordered]@{category=$Category;subcategory=$Subcategory;tags=@($Tags);status=$Status}
 if($Type -eq 'product') {
  $item.id=$id;$item.name=$Name;$item.image=$Image;$item.description=$Description;$item.shopeeUrl=$ShopeeUrl;$item.videoUrl=$VideoUrl;$item.updatedAt=$today
 } elseif($Type -eq 'video') {
  $item.id=$id;$item.title=$Name;$item.duration=$Duration;$item.thumbnail=$Image;$item.url=$VideoUrl;$item.publishedAt=$today
 } else {
  $item.slug=$id;$item.title=$Name;$item.intro=$Description;$item.sections=@($Sections);$item.relatedProductIds=@($RelatedProductIds);$item.updatedAt=$today
 }
 # Drafts may omit descriptions; do not silently invent editorial copy.
 if ($Status -eq 'published') { Assert-Item ([pscustomobject]$item) $Type -CheckFiles }
 Write-Json $path @($items + [pscustomobject]$item)
 Write-Output "Added $Type '$id' ($Status)."
} catch { throw "New-HayMintItem failed: $($_.Exception.Message)" }
