# Packs fg-ext/item-charges into a Fantasy Grounds extension (.ext).
# Usage:  pwsh -File ./build-ext.ps1  [-Install]
#
# -Install also copies the .ext into the local Fantasy Grounds extensions folder. It does not
# enable it: tick it in the campaign's extension list at launch, and untick Advanced Item
# Actions, which this replaces. Running both gives every equipped wand two spell classes.
[CmdletBinding()]
param([switch]$Install)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$src  = Join-Path $root 'fg-ext/item-charges'
$out  = Join-Path $root 'build'
$ext  = Join-Path $out 'MC-Item-Charges.ext'

New-Item -ItemType Directory -Force $out | Out-Null
if (Test-Path $ext) { Remove-Item $ext -Force }

# FG wants extension.xml at the root of the zip. The test folder stays out.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($ext, 'Create')
try {
  Get-ChildItem $src -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/]test[\\/]' } | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length + 1).Replace('\', '/')
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel)
  }
}
finally { $zip.Dispose() }
Write-Host "Built $ext" -ForegroundColor Green

if ($Install) {
  $candidates = @(
    (Join-Path $env:APPDATA 'SmiteWorks/Fantasy Grounds/extensions'),
    (Join-Path $HOME 'Library/Application Support/SmiteWorks/Fantasy Grounds/extensions'),
    (Join-Path $HOME 'SmiteWorks/Fantasy Grounds/extensions'),
    (Join-Path $HOME '.smiteworks/fantasygrounds/extensions')
  )
  $dest = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if (-not $dest) { throw ("Could not find the Fantasy Grounds extensions folder. Looked in:`n  " + ($candidates -join "`n  ")) }
  Copy-Item $ext (Join-Path $dest ([IO.Path]::GetFileName($ext))) -Force
  Write-Host "Installed to $dest - enable it in the campaign's extension list, and disable Advanced Item Actions." -ForegroundColor Green
}
