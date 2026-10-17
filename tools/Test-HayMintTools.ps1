<#
.SYNOPSIS
Smoke-test tools in a disposable copy. Does not commit, push or modify this repo.
#>
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$source=Split-Path -Parent $PSScriptRoot
$temp=Join-Path ([IO.Path]::GetTempPath()) ('HayMint-test-'+[Guid]::NewGuid().ToString('N'))
try {
 New-Item -ItemType Directory -Path $temp -ErrorAction Stop | Out-Null
 foreach($name in @('tools','data','assets','guides')){Copy-Item -LiteralPath (Join-Path $source $name) -Destination $temp -Recurse -ErrorAction Stop}
 Get-ChildItem -LiteralPath $source -Filter '*.html' -File -ErrorAction Stop | Copy-Item -Destination $temp -ErrorAction Stop
 $new=Join-Path $temp 'tools/New-HayMintItem.ps1'
 $set=Join-Path $temp 'tools/Set-HayMintStatus.ps1'
 $publish=Join-Path $temp 'tools/Publish-HayMint.ps1'
 # Clear copied data; no real items or affiliate URLs are used.
 $utf8=New-Object Text.UTF8Encoding($false)
 foreach($file in @('products','videos','guides')){[IO.File]::WriteAllText((Join-Path $temp "data/$file.json"),'[]',$utf8)}
 $configPath=Join-Path $temp 'data/config.json'
 $config=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($configPath,[Text.Encoding]::UTF8)) -ErrorAction Stop
 $config.baseUrl='https://example.org/haymint/'
 $config.facebookPageUrl='https://www.facebook.com/example'
 [IO.File]::WriteAllText($configPath,(ConvertTo-Json -InputObject $config -Depth 10 -ErrorAction Stop),$utf8)
 $unicodeName = 'H' + [char]0x1ed9 + 'p g' + [char]0x1ea5 + 'p g' + [char]0x1ecd + 'n'
 & $new -Type product -Name $unicodeName -Category living -Subcategory luu-tru -Description $unicodeName
 $rows = @(ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $temp 'data/products.json'),[Text.Encoding]::UTF8)) -ErrorAction Stop)
 if($rows[0].name -cne $unicodeName -or $rows[0].id -cne 'hop-gap-gon'){throw 'Vietnamese Unicode round-trip or slug failed.'}
 & $new -Type product -Name 'Draft check' -Category desk -Subcategory phu-kien-ban -Description 'Draft only'
 & $new -Type video -Name 'Video draft check' -Category desk -Subcategory phu-kien-ban
 & $new -Type guide -Name 'Guide draft check' -Category desk -Subcategory phu-kien-ban -Description 'Draft guide'
 & $set -Type product -Id draft-check -Status draft
 $blocked=$false
 try{& $set -Type product -Id draft-check -Status published}catch{$blocked=$true}
 if(-not $blocked){throw 'Incomplete product was not blocked.'}
 $blocked=$false
 try{& $new -Type product -Name 'Bad category' -Category unknown -Subcategory unknown}catch{$blocked=$true}
 if(-not $blocked){throw 'Unknown taxonomy was not blocked.'}
 & $publish -ValidateOnly
 foreach($file in @('products','videos','guides')){
  $bytes=[IO.File]::ReadAllBytes((Join-Path $temp "data/$file.json"))
  if($bytes.Length -gt 2 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191){throw 'Unexpected UTF-8 BOM.'}
 }
 Write-Output 'PASS: draft creation, draft status, incomplete publish rejection, taxonomy rejection, SEO validation and BOM checks.'
}finally{if(Test-Path -LiteralPath $temp -ErrorAction Stop){Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction Stop}}
