# Builds data.js (the site's search index) from the markdown in ./source
# Usage:  powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcdir = Join-Path $root 'source'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$em = [char]0x2014   # em-dash by code point: never type it literally in a .ps1 (PS5.1 reads as ANSI)

# Source files in reading order, with their display book titles. Chapters reset to I in each book.
$books = @(
  @{ file = 'book-1-the-worldwound-incursion.md'; title = ('Book I '   + $em + ' The Worldwound Incursion'); book = 'I'   },
  @{ file = 'book-2-the-sword-of-valor.md';        title = ('Book II '  + $em + ' The Sword of Valor');       book = 'II'  },
  @{ file = 'book-3-demons-heresy.md';             title = ('Book III ' + $em + " Demon's Heresy");           book = 'III' }
)

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
    foreach ($l in $block) {
      $t = $l.Trim()
      if ($t -match '^<!--\s*epilogue\s*-->$') { $isEpi = $true }
      elseif ($t -match '^<!--\s*date:\s*(.+?)\s*-->$') { $dateExplicit = $matches[1] }
      elseif ($sub -eq '' -and $t -match '^\*.+\*$') { $sub = $t.Trim('*').Trim() }
    }
    if ($isEpi) { $num = ''; $label = 'Epilogue' }
    else { $chapNum++; $num = To-Roman $chapNum; $label = 'Chapter ' + $num }
    # real-world play date: explicit <!-- date --> override, else parsed from the chapter text
    $date = if ($dateExplicit) { $dateExplicit } else { Get-PlayDate ($block -join "`n") }
    # md with the fathom/epilogue/date comments stripped, for rendering
    $md = (($block | Where-Object { $_ -notmatch '^\s*<!--\s*(fathom|epilogue|date)' }) -join "`n").Trim()
    $text = $md -replace '\[(.*?)\]\((.*?)\)', '$1' -replace '[#>*`_]', ' ' -replace '\s+', ' '
    $order++
    [void]$all.Add([pscustomobject]@{
      id = "ch$order"; order = $order; book = $b.book; bookTitle = $b.title
      num = $num; label = $label; isEpilogue = $isEpi; date = $date
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
    $text = $md -replace '\[(.*?)\]\((.*?)\)', '$1' -replace '[#>*`_]', ' ' -replace '\s+', ' '
    $sorder++
    [void]$secrets.Add([pscustomobject]@{
      id = "sec$sorder"; order = $sorder; title = $title; subtitle = $sub; md = $md; text = $text.Trim()
    })
  }
}

$json = ConvertTo-Json @($all) -Depth 6 -Compress
if ($secrets.Count -eq 0) { $sjson = '[]' }
else {
  $sjson = ConvertTo-Json @($secrets) -Depth 6 -Compress
  if ($sjson[0] -ne '[') { $sjson = '[' + $sjson + ']' }   # PS5.1 collapses a single-element array to an object
}
[System.IO.File]::WriteAllText((Join-Path $root 'data.js'), "window.CHAPTERS = $json;`nwindow.SECRETS = $sjson;", $utf8)
Write-Host ("Built data.js: {0} chapters ({1}), {2} secrets" -f $all.Count, (($all | Group-Object book | ForEach-Object { '{0}={1}' -f $_.Name, $_.Count }) -join ', '), $secrets.Count)
