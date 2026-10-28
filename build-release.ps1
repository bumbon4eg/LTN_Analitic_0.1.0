param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "_release")
)

$ErrorActionPreference = "Stop"

function Get-RequiredManifestValue {
    param(
        [object]$Manifest,
        [string]$PropertyName
    )

    $property = $Manifest.PSObject.Properties[$PropertyName]
    if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
        throw "info.json must define a non-empty '$PropertyName' field."
    }

    return [string]$property.Value
}

$manifestPath = Join-Path $PSScriptRoot "info.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Required mod manifest not found: $manifestPath"
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -ErrorAction Stop
}
catch {
    throw "Could not parse info.json: $($_.Exception.Message)"
}

$modName = Get-RequiredManifestValue -Manifest $manifest -PropertyName "name"
$version = Get-RequiredManifestValue -Manifest $manifest -PropertyName "version"
$null = Get-RequiredManifestValue -Manifest $manifest -PropertyName "title"
$null = Get-RequiredManifestValue -Manifest $manifest -PropertyName "author"
$factorioVersion = Get-RequiredManifestValue -Manifest $manifest -PropertyName "factorio_version"

if ($modName -notmatch '^[A-Za-z0-9_-]{4,49}$') {
    throw "Mod Portal names must be 4-49 characters and contain only letters, numbers, underscores, or hyphens."
}

if ($version -notmatch '^(\d{1,5})\.(\d{1,5})\.(\d{1,5})$') {
    throw "Mod version must use the number.number.number format, for example 0.1.1."
}
foreach ($component in $Matches[1..3]) {
    if ([int]$component -gt 65535) {
        throw "Each mod version component must be between 0 and 65535."
    }
}

if ($factorioVersion -notmatch '^\d+\.\d+$') {
    throw "factorio_version must contain exactly a major and minor number, for example 2.0."
}

$title = [string]$manifest.title
if ($title.Length -gt 100) {
    throw "The mod title in info.json must not exceed 100 characters."
}

$codeDirectory = Join-Path $PSScriptRoot "code"
$luaFiles = @(Get-ChildItem -LiteralPath $codeDirectory -File -Filter "*.lua" | Sort-Object Name)
if ($luaFiles.Count -eq 0) {
    throw "No runtime Lua files found in: $codeDirectory"
}
foreach ($requiredFile in @("control.lua", "settings.lua")) {
    if (-not (Test-Path -LiteralPath (Join-Path $codeDirectory $requiredFile) -PathType Leaf)) {
        throw "Required runtime file not found: code\$requiredFile"
    }
}

$localeDirectory = Join-Path $PSScriptRoot "locale"
if (-not (Test-Path -LiteralPath $localeDirectory -PathType Container)) {
    throw "Required locale directory not found: $localeDirectory"
}
$localeFiles = @(Get-ChildItem -LiteralPath $localeDirectory -Recurse -File -Filter "*.cfg")
if ($localeFiles.Count -eq 0) {
    throw "No localization .cfg files found under: $localeDirectory"
}

$thumbnailPath = Join-Path $PSScriptRoot "thumbnail.png"
if (-not (Test-Path -LiteralPath $thumbnailPath -PathType Leaf)) {
    throw "Required Mod Portal thumbnail not found: $thumbnailPath"
}

$licensePath = Join-Path $PSScriptRoot "LICENSE"
if (-not (Test-Path -LiteralPath $licensePath -PathType Leaf)) {
    throw "Project LICENSE file not found: $licensePath"
}

$archiveName = "${modName}_${version}"
$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
$null = New-Item -ItemType Directory -Path $outputPath -Force
$archivePath = Join-Path $outputPath "$archiveName.zip"

$tempRoot = [System.IO.Path]::GetTempPath()
$workRoot = Join-Path $tempRoot ("factorio-mod-release-" + [Guid]::NewGuid().ToString("N"))
$modRoot = Join-Path $workRoot $archiveName
$tempArchive = Join-Path $tempRoot ($archiveName + "." + [Guid]::NewGuid().ToString("N") + ".zip")

try {
    $null = New-Item -ItemType Directory -Path $modRoot -Force

    Copy-Item -LiteralPath $manifestPath -Destination $modRoot
    Copy-Item -LiteralPath $thumbnailPath -Destination $modRoot
    Copy-Item -LiteralPath $licensePath -Destination $modRoot
    foreach ($luaFile in $luaFiles) {
        Copy-Item -LiteralPath $luaFile.FullName -Destination $modRoot
    }
    Copy-Item -LiteralPath $localeDirectory -Destination $modRoot -Recurse

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::Open(
        $tempArchive,
        [System.IO.Compression.ZipArchiveMode]::Create
    )
    try {
        $packageFiles = @(Get-ChildItem -LiteralPath $workRoot -Recurse -File)
        foreach ($packageFile in $packageFiles) {
            $relativePath = $packageFile.FullName.Substring($workRoot.Length + 1)
            $entryName = $relativePath.Replace([char]'\', [char]'/')
            $entry = $archive.CreateEntry(
                $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal
            )
            $inputStream = [System.IO.File]::OpenRead($packageFile.FullName)
            try {
                $entryStream = $entry.Open()
                try {
                    $inputStream.CopyTo($entryStream)
                }
                finally {
                    $entryStream.Dispose()
                }
            }
            finally {
                $inputStream.Dispose()
            }
        }
    }
    finally {
        $archive.Dispose()
    }
    Move-Item -LiteralPath $tempArchive -Destination $archivePath -Force
}
finally {
    if (Test-Path -LiteralPath $workRoot) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $tempArchive) {
        Remove-Item -LiteralPath $tempArchive -Force
    }
}

Write-Output "Release archive created: $archivePath"
