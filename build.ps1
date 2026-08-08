# Builds data.js (the site's search index) from the markdown in ./source
# Usage:  powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$srcdir = Join-Path $root 'source'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$em = [char]0x2014   # em-dash by code point: never type it literally in a .ps1 (PS5.1 reads as ANSI)

# Source files in reading order, with their display book titles. Chapters reset to I in each book.
$books = @(
  @{ file = 'book-1-the-worldwound-incursion.md'; title = ('Book I '   + $em + ' The Worldwound Incursion'); book = 'I'   },
  @{ file = 'book-2-the-sword-of-valor.md';        title = ('Book II '  + $em + ' The Sword of Valor');       book = 'II'  },
  @{ file = 'book-3-demons-heresy.md';             title = ('Book III ' + $em + " Demon's Heresy");           book = 'III' }
)

# --- The in-world calendar (Golarion reckoning) ---
# Month lengths follow the Gregorian year; the weekday cycle is anchored on a day the
# chronicle names outright (Fire Day, the 13th of Rova, 4713 AR -- book 2, "The Sword of
# Valor Reclaimed"), and checks out against Oath Day, the 31st of Lamashan, in book 3.
$CAL_MONTHS  = @('Abadius','Calistril','Pharast','Gozran','Desnus','Sarenith','Erastus','Arodus','Rova','Lamashan','Neth','Kuthona')
$CAL_LENS    = @(31,28,31,30,31,30,31,31,30,31,30,31)
$CAL_WEEK    = @('Moon Day','Toil Day','Weal Day','Oath Day','Fire Day','Star Day','Sun Day')
$CAL_YEAR    = 4713          # the crusade's year; ordinals are reckoned from its 1st of Abadius
$CAL_WD_ORD  = 256           # ordinal of 13 Rova 4713
$CAL_WD_IDX  = 4             # ...which was a Fire Day

# Day-of-year -> a single ordinal number, so a span is just two integers.
function Get-Ordinal([int]$day, [string]$monthName, [int]$year) {
  $mi = [array]::IndexOf($CAL_MONTHS, $monthName)
  if ($mi -lt 0) { throw "Unknown in-world month: $monthName" }
  $doy = $day
  for ($k = 0; $k -lt $mi; $k++) { $doy += $CAL_LENS[$k] }
  return ($year - $CAL_YEAR) * 365 + $doy
}

function To-Roman([int]$n){
  $map = @(@(1000,'M'),@(900,'CM'),@(500,'D'),@(400,'CD'),@(100,'C'),@(90,'XC'),@(50,'L'),@(40,'XL'),@(10,'X'),@(9,'IX'),@(5,'V'),@(4,'IV'),@(1,'I'))
  $r=''; foreach($p in $map){ while($n -ge $p[0]){ $r += $p[1]; $n -= $p[0] } }
  return $r
}

# Real-world play date parsed from a chapter's text (subtitle or "Session of" line).
$months = @('January','February','March','April','May','June','July','August','September','October','November','December')
function Get-PlayDate($text) {
  $mo = ($months -join '|')
  $m = [regex]::Match($text, "\b($mo)\s+(\d{1,2}),\s+(\d{4})\b")
  if ($m.Success) { return ('{0} {1}, {2}' -f $m.Groups[1].Value, [int]$m.Groups[2].Value, $m.Groups[3].Value) }
  $m = [regex]::Match($text, "\b(\d{1,2})(?:st|nd|rd|th)?\s+($mo)\s+(\d{4})\b")
  if ($m.Success) { return ('{0} {1}, {2}' -f $m.Groups[2].Value, [int]$m.Groups[1].Value, $m.Groups[3].Value) }
  return ''
}

$all = New-Object System.Collections.ArrayList
$order = 0
foreach ($b in $books) {
  $path = Join-Path $srcdir $b.file
  if (-not (Test-Path $path)) { throw "Missing source file: $path" }
  $lines = ([System.IO.File]::ReadAllText($path)) -split "`r?`n"
  $idx = @()
  for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^##\s+\S') { $idx += $i } }
  $chapNum = 0
  for ($j = 0; $j -lt $idx.Count; $j++) {
    $start = $idx[$j]
    $end = if ($j + 1 -lt $idx.Count) { $idx[$j + 1] - 1 } else { $lines.Count - 1 }
    $block = $lines[$start..$end]
    $title = ($lines[$start] -replace '^##\s*', '' -replace '\*\*', '').Trim()
    # per-chapter markers: epilogue flag, explicit date override, and the first italic subtitle
    $sub = ''
    $isEpi = $false
    $dateExplicit = ''
    $inFrom = 0; $inTo = 0; $inApprox = $false
    foreach ($l in $block) {
      $t = $l.Trim()
      if ($t -match '^<!--\s*epilogue\s*-->$') { $isEpi = $true }
      elseif ($t -match '^<!--\s*date:\s*(.+?)\s*-->$') { $dateExplicit = $matches[1] }
      elseif ($t -match '^<!--\s*inworld:\s*(approx\s+)?(\d+)\s+([A-Za-z]+)\s+(\d+)(?:\s+to\s+(\d+)\s+([A-Za-z]+)\s+(\d+))?\s*-->$') {
        $inApprox = [bool]("$($matches[1])".Trim())
        $inFrom = Get-Ordinal ([int]$matches[2]) $matches[3] ([int]$matches[4])
        $inTo = if ($matches[5]) { Get-Ordinal ([int]$matches[5]) $matches[6] ([int]$matches[7]) } else { $inFrom }
        if ($inTo -lt $inFrom) { throw "Chapter '$title': in-world span ends before it begins." }
      }
      elseif ($sub -eq '' -and $t -match '^\*.+\*$') { $sub = $t.Trim('*').Trim() }
    }
    if ($inFrom -eq 0) { Write-Warning ("No <!-- inworld: --> marker on '{0}' -- it will not appear on the Timeline." -f $title) }
    if ($isEpi) { $num = ''; $label = 'Epilogue' }
    else { $chapNum++; $num = To-Roman $chapNum; $label = 'Chapter ' + $num }
    # real-world play date: explicit <!-- date --> override, else parsed from the chapter text
    $date = if ($dateExplicit) { $dateExplicit } else { Get-PlayDate ($block -join "`n") }
    # md with the fathom/epilogue/date/inworld comments stripped, for rendering
    $md = (($block | Where-Object { $_ -notmatch '^\s*<!--\s*(fathom|epilogue|date|inworld)' }) -join "`n").Trim()
    $text = $md -replace '!\[(.*?)\]\((.*?)\)', '$1' -replace '\[(.*?)\]\((.*?)\)', '$1' -replace '[#>*`_]', ' ' -replace '\s+', ' '
    $order++
    [void]$all.Add([pscustomobject]@{
      id = "ch$order"; order = $order; book = $b.book; bookTitle = $b.title
      num = $num; label = $label; isEpilogue = $isEpi; date = $date
      inFrom = $inFrom; inTo = $inTo; inApprox = $inApprox
      title = $title; subtitle = $sub; md = $md; text = $text.Trim()
    })
  }
}

# --- Secrets: a parallel corpus of in-world documents (secrets/*.md) ---
$secrets = New-Object System.Collections.ArrayList
$secdir = Join-Path $root 'secrets'
if (Test-Path $secdir) {
  $sorder = 0
  Get-ChildItem -Path $secdir -Filter '*.md' | Sort-Object Name | ForEach-Object {
    $lines = ([System.IO.File]::ReadAllText($_.FullName)) -split "`r?`n"
    $title = ''; $sub = ''
    foreach ($l in $lines) {
      $t = $l.Trim()
      if ($title -eq '' -and $t -match '^#\s+(.+)$') { $title = ($matches[1] -replace '\*\*', '').Trim() }
      elseif ($title -ne '' -and $sub -eq '' -and $t -match '^\*.+\*$') { $sub = ($t.Trim('*') -replace '\*\*', '').Trim() }
    }
    $md = (($lines) -join "`n").Trim()
    $text = $md -replace '!\[(.*?)\]\((.*?)\)', '$1' -replace '\[(.*?)\]\((.*?)\)', '$1' -replace '[#>*`_]', ' ' -replace '\s+', ' '
    $sorder++
    [void]$secrets.Add([pscustomobject]@{
      id = "sec$sorder"; order = $sorder; title = $title; subtitle = $sub; md = $md; text = $text.Trim()
    })
  }
}

# --- The journal: the crusade's days, from bible/06-in-world-calendar.md ---
# The prose calendar is hand-authored in the chronicle's voice from the Fantasy Grounds
# extraction beside it. Only its month sections are read; the trailing notes after the
# horizontal rule (silent days, open discrepancies) are authoring matter and stay behind.
$journal = New-Object System.Collections.ArrayList
$calpath = Join-Path $root 'bible/06-in-world-calendar.md'
if (Test-Path $calpath) {
  $clines = ([System.IO.File]::ReadAllText($calpath)) -split "`r?`n"
  $curMonth = ''; $curYear = 0; $cur = $null
  foreach ($l in $clines) {
    if ($l -match '^##\s+([A-Za-z]+),\s*(\d+)\s*AR\s*$' -and ([array]::IndexOf($CAL_MONTHS, $matches[1]) -ge 0)) {
      $curMonth = $matches[1]; $curYear = [int]$matches[2]; $cur = $null; continue
    }
    if ($l -match '^(##\s|---\s*$)') { $curMonth = ''; $cur = $null; continue }
    if ($curMonth -eq '') { continue }
    if ($l -match '^-\s+\*\*(\d+)(?:st|nd|rd|th)\*\*\s*\u2014\s*(.+)$') {   # em-dash by escape, never literal
      $cur = [pscustomobject]@{ ord = (Get-Ordinal ([int]$matches[1]) $curMonth $curYear); md = $matches[2].Trim() }
      [void]$journal.Add($cur); continue
    }
    # a wrapped continuation of the bullet above it
    if ($cur -and $l -match '^\s+\S') { $cur.md = $cur.md + ' ' + $l.Trim(); continue }
    $cur = $null
  }
}

$calendar = [pscustomobject]@{
  months = $CAL_MONTHS; lens = $CAL_LENS; weekdays = $CAL_WEEK
  year = $CAL_YEAR; wdOrd = $CAL_WD_ORD; wdIdx = $CAL_WD_IDX
}

function To-JsonArray($items) {
  if (@($items).Count -eq 0) { return '[]' }
  $j = ConvertTo-Json @($items) -Depth 6 -Compress
  if ($j[0] -ne '[') { $j = '[' + $j + ']' }   # PS5.1 collapses a single-element array to an object
  return $j
}

$json  = To-JsonArray $all
$sjson = To-JsonArray $secrets
$jjson = To-JsonArray $journal
$cjson = ConvertTo-Json $calendar -Depth 4 -Compress
[System.IO.File]::WriteAllText((Join-Path $root 'data.js'),
  "window.CHAPTERS = $json;`nwindow.SECRETS = $sjson;`nwindow.CALENDAR = $cjson;`nwindow.JOURNAL = $jjson;", $utf8)
Write-Host ("Built data.js: {0} chapters ({1}), {2} secrets, {3} journal days" -f $all.Count, (($all | Group-Object book | ForEach-Object { '{0}={1}' -f $_.Name, $_.Count }) -join ', '), $secrets.Count, $journal.Count)
