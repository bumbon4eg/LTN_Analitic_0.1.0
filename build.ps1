param(
    [string]$OutputDirectory = "dist\LTN_Analitic_0.1.1"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$output = Join-Path $root $OutputDirectory

if (Test-Path $output) {
    Remove-Item -Recurse -Force $output
}

New-Item -ItemType Directory -Path $output | Out-Null
Copy-Item (Join-Path $root "info.json") $output
Copy-Item (Join-Path $root "code\*.lua") $output

$archive = "$output.zip"
if (Test-Path $archive) {
    Remove-Item -Force $archive
}

Compress-Archive -Path $output -DestinationPath $archive
Write-Output "Built Factorio mod: $archive"
