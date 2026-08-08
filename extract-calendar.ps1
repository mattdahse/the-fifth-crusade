# Extracts the Fantasy Grounds campaign calendar into bible/06-in-world-calendar.json.
# Usage:  pwsh -File ./extract-calendar.ps1
#
# The JSON is the raw, verbatim record and is MACHINE-WRITTEN -- never hand-edit it.
# The prose calendar in bible/06-in-world-calendar.md is hand-authored from it; this script
# reports which days are new since the last run so they can be written up.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$em = [char]0x2014   # em-dash by code point: never type it literally in a .ps1

# The FG campaign lives outside the repo and differs per station (two Macs and a PC).
$candidates = @(
  (Join-Path $env:APPDATA 'SmiteWorks/Fantasy Grounds/campaigns/Wrath of the Righteous - AZ/db.xml'),
  (Join-Path $HOME 'Library/Application Support/SmiteWorks/Fantasy Grounds/campaigns/Wrath of the Righteous - AZ/db.xml'),
  (Join-Path $HOME 'SmiteWorks/Fantasy Grounds/campaigns/Wrath of the Righteous - AZ/db.xml'),
  (Join-Path $HOME '.smiteworks/fantasygrounds/campaigns/Wrath of the Righteous - AZ/db.xml')
)
$db = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $db) { throw ("Could not find the Fantasy Grounds db.xml. Looked in:`n  " + ($candidates -join "`n  ")) }
Write-Host "Reading $db"

# Always ReadAllText (UTF-8), never Get-Content -Raw.
[xml]$x = [IO.File]::ReadAllText($db)
$cal = $x.root.calendar
if (-not $cal) { throw 'No <calendar> node in db.xml.' }

# Month names come from the calendar's own period definitions, not a hardcoded list.
$months = @{}
# NOTE: use .LocalName, never .Name -- these elements carry a child <name>, and PowerShell's
# XML adapter resolves .Name to that child instead of the element's own tag.
foreach ($p in $cal.data.periods.ChildNodes) {
  if ($p.LocalName -match '^period(\d+)$') { $months[[int]$matches[1]] = $p.name.'#text' }
}

# FG formattedtext -> plain text: take the inner text of each block, joined by blank lines.
function Get-LogText($node) {
  if (-not $node) { return '' }
  $parts = foreach ($c in $node.ChildNodes) {
    $t = ([string]$c.InnerText).Trim()
    if ($t) { $t }
  }
  return (($parts -join "`n`n").Trim())
}

$entries = New-Object System.Collections.ArrayList
foreach ($e in $cal.log.ChildNodes) {
  if ($e.LocalName -notmatch '^id-\d+$') { continue }
  $log = Get-LogText $e.logentry
  $gm  = Get-LogText $e.gmlogentry
  $mo  = [int]$e.month.'#text'
  [void]$entries.Add([pscustomobject]@{
    id        = $e.LocalName
    day       = [int]$e.day.'#text'
    month     = $mo
    monthname = $months[$mo]
    year      = [int]$e.year.'#text'
    name      = ([string]$e.name.'#text').Trim()
    log       = $log
    gmlog     = $gm
  })
}
$sorted = @($entries | Sort-Object year, month, day, id)

$monthsJson = [ordered]@{}
foreach ($k in ($months.Keys | Sort-Object)) { $monthsJson["$k"] = $months[$k] }

$out = [pscustomobject]@{
  source  = 'Fantasy Grounds campaign calendar <calendar><log>'
  current = [pscustomobject]@{
    day   = [int]$cal.current.day.'#text'
    month = [int]$cal.current.month.'#text'
    year  = [int]$cal.current.year.'#text'
  }
  months  = $monthsJson   # int keys will not serialize; emit them as strings
  entries = $sorted
}

$dest = Join-Path $root 'bible/06-in-world-calendar.json'

# Report what is new since the last run, so the prose file can be brought up to date.
$known = @{}
if (Test-Path $dest) {
  $prev = [IO.File]::ReadAllText($dest) | ConvertFrom-Json
  foreach ($p in $prev.entries) { $known[$p.id] = $true }
}
$new = @($sorted | Where-Object { -not $known.ContainsKey($_.id) -and ($_.log -or $_.gmlog) })

[IO.File]::WriteAllText($dest, (ConvertTo-Json $out -Depth 6), $utf8)

$withText = @($sorted | Where-Object { $_.log -or $_.gmlog }).Count
Write-Host ("Wrote bible/06-in-world-calendar.json: {0} log days, {1} with text" -f $sorted.Count, $withText)
if ($new.Count -eq 0) {
  Write-Host 'No new days since the last run.'
} else {
  Write-Host ("{0} NEW day(s) {1} write these into bible/06-in-world-calendar.md:" -f $new.Count, $em)
  foreach ($n in $new) {
    $body = if ($n.log) { $n.log } else { '(GM) ' + $n.gmlog }
    Write-Host ("  {0} {1}, {2}: {3}" -f $n.day, $n.monthname, $n.year, $body)
  }
}
