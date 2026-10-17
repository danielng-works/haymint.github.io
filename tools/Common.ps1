# Shared helpers. ASCII source works without BOM in Windows PowerShell 5.1.
$ErrorActionPreference = 'Stop'
$script:Root = Split-Path -Parent $PSScriptRoot
$script:Utf8 = New-Object System.Text.UTF8Encoding($false)
function Read-Json([string]$Path) {
    try { return ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)) -ErrorAction Stop }
    catch { throw "Cannot read JSON '$Path': $($_.Exception.Message)" }
}
function Read-Items([string]$Path) {
    $raw = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    if (-not $raw.TrimStart().StartsWith('[')) { throw "Expected a JSON array: $Path" }
    return Read-Json $Path
}
function Write-Json([string]$Path, $Value) {
    $text = ConvertTo-Json -InputObject $Value -Depth 30 -ErrorAction Stop
    [IO.File]::WriteAllText($Path, $text + [Environment]::NewLine, $script:Utf8)
}
function Get-DataPath([string]$Type) {
    $names = @{ product='products'; video='videos'; guide='guides' }
    return Join-Path $script:Root ('data/' + $names[$Type] + '.json')
}
function Get-Slug([string]$Text) {
    $normalized = $Text.Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object Text.StringBuilder
    foreach ($ch in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            if ([int]$ch -eq 273 -or [int]$ch -eq 272) { [void]$builder.Append('d') } else { [void]$builder.Append($ch) }
        }
    }
    $s = ($builder.ToString().ToLowerInvariant() -replace '[^a-z0-9]+','-').Trim('-')
    if (-not $s) { throw 'Name must contain letters or numbers.' }
    return $s
}
function Assert-Taxonomy([string]$Category,[string]$Subcategory) {
    $tax = @(Read-Items (Join-Path $script:Root 'data/taxonomy.json'))
    $cat = @($tax | Where-Object { $_.slug -ceq $Category })
    if ($cat.Count -ne 1) { throw "Unknown category slug: $Category" }
    if (@($cat[0].subcategories | Where-Object { $_.slug -ceq $Subcategory }).Count -ne 1) { throw "Unknown subcategory '$Subcategory' for '$Category'." }
}
function Assert-Https([string]$Value,[string]$Label,[switch]$Required) {
    if ([string]::IsNullOrWhiteSpace($Value)) { if ($Required) { throw "$Label is required." }; return }
    $uri = $null
    if (-not $Value.StartsWith('https://',[StringComparison]::Ordinal) -or -not [Uri]::TryCreate($Value,[UriKind]::Absolute,[ref]$uri) -or -not $uri.Host -or $uri.UserInfo) { throw "$Label must be an absolute https:// URL without credentials." }
}
function Assert-Image([string]$Value,[string]$Label,[switch]$Required,[switch]$Product) {
    if (-not $Value) { if ($Required) { throw "$Label is required for published content." }; return }
    if ($Value -notmatch '^assets/img/[a-zA-Z0-9_./-]+\.(jpg|jpeg|png|webp|avif|gif)$' -or $Value.Contains('..')) { throw "$Label must be a relative image path under assets/img/." }
    if ($Product -and -not $Value.StartsWith('assets/img/products/')) { throw "$Label must be under assets/img/products/." }
    if (-not (Test-Path -LiteralPath (Join-Path $script:Root $Value) -PathType Leaf -ErrorAction Stop)) { throw "Missing image: $Value" }
}
function Assert-Item($Item,[string]$Type,[switch]$CheckFiles) {
    if ($Item.status -cnotin @('draft','published')) { throw 'Every item needs status draft or published.' }
    Assert-Taxonomy $Item.category $Item.subcategory
    $key = if ($Type -eq 'guide') { 'slug' } else { 'id' }
    if (-not $Item.$key -or $Item.$key -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { throw "Invalid $key." }
    if ($null -eq $Item.tags -or $Item.tags -is [string]) { throw 'tags must be an array.' }
    foreach ($tag in $Item.tags) { if ($tag -isnot [string] -or -not $tag.Trim()) { throw 'Each tag must be nonempty text.' } }
    $published = $Item.status -ceq 'published'
    if ($Type -eq 'product') {
        if (-not $Item.name -or -not $Item.description -or -not $Item.updatedAt) { throw 'Product requires name, description and updatedAt.' }
        Assert-Https $Item.shopeeUrl 'shopeeUrl'
        Assert-Https $Item.videoUrl 'videoUrl'
        if ($CheckFiles) { Assert-Image $Item.image 'image' -Required:$published -Product }
    } elseif ($Type -eq 'video') {
        if (-not $Item.title -or -not $Item.publishedAt) { throw 'Video requires title and publishedAt.' }
        if ($published -and $Item.duration -notmatch '^\d{1,3}:[0-5]\d$') { throw 'Published video needs duration, e.g. 00:30.' }
        Assert-Https $Item.url 'video url' -Required:$published
        if ($Item.url) { $hostName = ([Uri]$Item.url).DnsSafeHost; if ($hostName -notmatch '(^|\.)(facebook\.com|fb\.watch)$') { throw 'Video URL must point to Facebook or fb.watch.' } }
        if ($CheckFiles) { Assert-Image $Item.thumbnail 'thumbnail' -Required:$published }
    } else {
        if (-not $Item.title -or -not $Item.intro -or -not $Item.updatedAt) { throw 'Guide requires title, intro and updatedAt.' }
        if ($null -eq $Item.sections -or $Item.sections -is [string] -or $null -eq $Item.relatedProductIds -or $Item.relatedProductIds -is [string]) { throw 'Guide sections and relatedProductIds must be arrays.' }
        if ($published -and @($Item.sections).Count -eq 0) { throw 'Published guide needs at least one section.' }
        foreach ($section in $Item.sections) {
            if ($null -eq $section.paragraphs -or $section.paragraphs -is [string]) { throw 'Each section needs a paragraphs array.' }
            if ($published -and @($section.paragraphs).Count -eq 0) { throw 'Published sections need paragraphs.' }
            foreach ($paragraph in $section.paragraphs) { if ($paragraph -isnot [string] -or -not $paragraph.Trim()) { throw 'Paragraphs must be nonempty text.' } }
        }
    }
    $date = if ($Type -eq 'video') { $Item.publishedAt } else { $Item.updatedAt }
    $parsed = [DateTime]::MinValue
    if (-not [DateTime]::TryParseExact($date,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$parsed)) { throw 'Dates must use yyyy-MM-dd.' }
}
