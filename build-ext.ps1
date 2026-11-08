# Packs the Fantasy Grounds extensions under fg-ext/ into .ext files in build/.
# Usage:  pwsh -File ./build-ext.ps1  [-Name item-charges|spellbook]  [-Install]
#
#   item-charges -> build/MC-Item-Charges.ext   (replaces Advanced Item Actions; never run both)
#   spellbook    -> build/MC-Spellbook.ext
#
# With no -Name, every extension is built. -Install also copies each .ext into the local
# Fantasy Grounds extensions folder. It does not enable it: tick it in the campaign's
# extension list at launch.
[CmdletBinding()]
param(
  [ValidateSet('item-charges', 'spellbook')]
  [string[]]$Name = @('item-charges', 'spellbook'),
  [switch]$Install
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out  = Join-Path $root 'build'
$files = @{ 'item-charges' = 'MC-Item-Charges.ext'; 'spellbook' = 'MC-Spellbook.ext' }

$dest = $null
if ($Install) {
  $candidates = @(
    (Join-Path $env:APPDATA 'SmiteWorks/Fantasy Grounds/extensions'),
    (Join-Path $HOME 'Library/Application Support/SmiteWorks/Fantasy Grounds/extensions'),
    (Join-Path $HOME 'SmiteWorks/Fantasy Grounds/extensions'),
    (Join-Path $HOME '.smiteworks/fantasygrounds/extensions')
  )
  $dest = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if (-not $dest) { throw ("Could not find the Fantasy Grounds extensions folder. Looked in:`n  " + ($candidates -join "`n  ")) }
}

New-Item -ItemType Directory -Force $out | Out-Null
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

foreach ($n in $Name) {
  $src = Join-Path $root "fg-ext/$n"
  $ext = Join-Path $out $files[$n]
  if (Test-Path $ext) { Remove-Item $ext -Force }

  # FG wants extension.xml at the root of the zip. The test folder stays out.
  $zip = [IO.Compression.ZipFile]::Open($ext, 'Create')
  try {
    Get-ChildItem $src -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/]test[\\/]' -and $_.Name -ne 'README.md' } | ForEach-Object {
      $rel = $_.FullName.Substring($src.Length + 1).Replace('\', '/')
      [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel)
    }
  }
  finally { $zip.Dispose() }
  Write-Host "Built $ext" -ForegroundColor Green

  if ($dest) {
    Copy-Item $ext (Join-Path $dest ([IO.Path]::GetFileName($ext))) -Force
    Write-Host "Installed to $dest - enable it in the campaign's extension list." -ForegroundColor Green
  }
}
