<#
.SYNOPSIS
Validate content, refresh SEO files, then git add, commit and push.
.EXAMPLE
.\tools\Publish-HayMint.ps1 -Message 'Add video'
.EXAMPLE
.\tools\Publish-HayMint.ps1 -ValidateOnly
#>
[CmdletBinding()]
param([string]$Message='Update HayMint',[switch]$ValidateOnly)
$ErrorActionPreference='Stop'
try {
 . (Join-Path $PSScriptRoot 'Common.ps1')
 # Validate all JSON, including examples, without publishing examples.
 Get-ChildItem -LiteralPath (Join-Path $script:Root 'data') -Filter '*.json' -File -ErrorAction Stop | ForEach-Object { $null=Read-Json $_.FullName }
 $config=Read-Json (Join-Path $script:Root 'data/config.json')
 Assert-Https $config.baseUrl 'config.baseUrl' -Required
 Assert-Https $config.facebookPageUrl 'config.facebookPageUrl' -Required
 foreach($social in @('tiktokUrl','youtubeUrl','instagramUrl')){Assert-Https $config.$social $social}
 $base=$config.baseUrl.TrimEnd('/')+'/'
 $baseUri=[Uri]$base
 if($baseUri.Query -or $baseUri.Fragment){throw 'baseUrl cannot contain query parameters or fragments.'}
 $tax=@(Read-Items (Join-Path $script:Root 'data/taxonomy.json'))
 $seen=@{}
 foreach($cat in $tax){
  if(-not $cat.label -or $cat.slug -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or $seen.ContainsKey($cat.slug)){throw 'Taxonomy requires unique category slugs and labels.'}
  $seen[$cat.slug]=$true;$subSeen=@{}
  foreach($sub in $cat.subcategories){if(-not $sub.label -or $sub.slug -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or $subSeen.ContainsKey($sub.slug)){throw "Invalid subcategory in $($cat.slug)."};$subSeen[$sub.slug]=$true}
 }
 $content=@{}
 foreach($type in @('product','video','guide')){
  $items=@(Read-Items (Get-DataPath $type));$ids=@{}
  foreach($item in $items){
   $key=if($type -eq 'guide'){'slug'}else{'id'}
   if($ids.ContainsKey([string]$item.$key)){throw "Duplicate $key in $type data."};$ids[[string]$item.$key]=$true
   # Drafts can be unfinished, but their taxonomy, status and any image references must be valid.
   Assert-Taxonomy $item.category $item.subcategory
   if($item.status -cnotin @('draft','published')){throw "Invalid status for $($item.$key)."}
   if($type -eq 'product'){Assert-Image $item.image 'image' -Product}
   if($type -eq 'video'){Assert-Image $item.thumbnail 'thumbnail'}
   if($item.status -ceq 'published'){Assert-Item $item $type -CheckFiles}
  }
  $content[$type]=@($items | Where-Object {$_.status -ceq 'published'})
 }
 foreach($guide in $content.guide){foreach($id in $guide.relatedProductIds){if(@($content.product | Where-Object {$_.id -ceq $id}).Count -ne 1){throw "Guide '$($guide.slug)' references missing or draft product '$id'."}}}
 $urls=New-Object 'System.Collections.Generic.List[string]'
 foreach($path in @('index.html','category.html','reels.html','guides/index.html','about.html','disclosure.html')){[void]$urls.Add($base+$path)}
 foreach($cat in $tax){if(@(@($content.product)+@($content.video)+@($content.guide) | Where-Object {$_.category -ceq $cat.slug}).Count -gt 0){[void]$urls.Add($base+'category.html?cat='+[Uri]::EscapeDataString($cat.slug))}}
 foreach($guide in $content.guide){[void]$urls.Add($base+'guides/guide.html?slug='+[Uri]::EscapeDataString($guide.slug))}
 $xml='<?xml version="1.0" encoding="UTF-8"?>'+"`n"+'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'+"`n"
 foreach($url in $urls){$xml+='  <url><loc>'+[Security.SecurityElement]::Escape($url)+"</loc></url>`n"};$xml+='</urlset>'
 [IO.File]::WriteAllText((Join-Path $script:Root 'sitemap.xml'),$xml+"`n",$script:Utf8)
 [IO.File]::WriteAllText((Join-Path $script:Root 'robots.txt'),"User-agent: *`nAllow: /`nSitemap: ${base}sitemap.xml`n",$script:Utf8)
 # Stamp static canonical/OG URLs so sharing crawlers need not run JavaScript.
 Get-ChildItem -LiteralPath $script:Root -Filter '*.html' -Recurse -File -ErrorAction Stop | ForEach-Object {
  $relative=$_.FullName.Substring($script:Root.Length+1).Replace('\','/')
  $url=[Security.SecurityElement]::Escape($base+$relative)
  $html=[IO.File]::ReadAllText($_.FullName,[Text.Encoding]::UTF8)
  $html=[regex]::Replace($html,'<link rel="canonical" href="[^"]*">',('<link rel="canonical" href="'+$url+'">'))
  $html=[regex]::Replace($html,'<meta property="og:url" content="[^"]*">',('<meta property="og:url" content="'+$url+'">'))
  # Rebuild category navigation from taxonomy for no-JS navigation too.
  $prefix=if($relative.StartsWith('guides/')){'../'}else{'./'}
  $nav='<details class="dropdown"><summary>Danh m'+[char]0x1ee5+'c</summary><div>'
  foreach($cat in $tax){$label=if($cat.name){$cat.name}else{$cat.label};$nav+='<a href="'+$prefix+'category.html?cat='+$cat.slug+'">'+[Security.SecurityElement]::Escape($label+' - '+$cat.label)+'</a>'}
  $nav+='</div></details>'
  $html=[regex]::Replace($html,'<details class="dropdown">.*?</details>',$nav)
  # Organization schema is homepage-only, including for non-JS crawlers.
  if($relative -eq 'index.html'){
   $html=[regex]::Replace($html,'<script id="organization-schema" type="application/ld\+json">.*?</script>','')
   $sameAs=@(@($config.facebookPageUrl,$config.tiktokUrl,$config.youtubeUrl,$config.instagramUrl) | Where-Object {$_})
   $schema=ConvertTo-Json -InputObject ([ordered]@{'@context'='https://schema.org';'@type'='Organization';name=$config.siteName;url=$base;sameAs=$sameAs}) -Compress -Depth 5 -ErrorAction Stop
   $schema=$schema.Replace('<','\u003c')
   $html=$html.Replace('</head>',('<script id="organization-schema" type="application/ld+json">'+$schema+'</script></head>'))
  }
  [IO.File]::WriteAllText($_.FullName,$html,$script:Utf8)
 }
 Write-Output 'Validation and SEO refresh passed.'
 if($ValidateOnly){return}
 if(-not (Get-Command git -ErrorAction SilentlyContinue)){throw 'Git is not installed or not in PATH.'}
 Push-Location $script:Root -ErrorAction Stop
 try{
  & git add --all; if($LASTEXITCODE -ne 0){throw 'git add failed.'}
  & git diff --cached --quiet
  if($LASTEXITCODE -eq 1){& git commit -m $Message; if($LASTEXITCODE -ne 0){throw 'git commit failed.'}}elseif($LASTEXITCODE -ne 0){throw 'git diff failed.'}else{Write-Output 'No staged changes; skipping commit.'}
  & git push; if($LASTEXITCODE -ne 0){throw 'git push failed. Check remote, branch and authentication.'}
 }finally{Pop-Location -ErrorAction Stop}
}catch{throw "Publish-HayMint failed: $($_.Exception.Message)"}
