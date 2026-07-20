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
    # per-chapter markers: fathom recording ids, epilogue flag, and the first italic subtitle
    $fathom = @()
    $sub = ''
    $isEpi = $false
    foreach ($l in $block) {
      $t = $l.Trim()
      if ($t -match '^<!--\s*fathom:\s*(.+?)\s*-->$') { $fathom = ($matches[1] -split '\s*,\s*') }
      elseif ($t -match '^<!--\s*epilogue\s*-->$') { $isEpi = $true }
      elseif ($sub -eq '' -and $t -match '^\*.+\*$') { $sub = $t.Trim('*').Trim() }
    }
    if ($isEpi) { $num = ''; $label = 'Epilogue' }
    else { $chapNum++; $num = To-Roman $chapNum; $label = 'Chapter ' + $num }
    # md with the fathom/epilogue comments stripped, for rendering
    $md = (($block | Where-Object { $_ -notmatch '^\s*<!--\s*(fathom|epilogue)' }) -join "`n").Trim()
    $text = $md -replace '\[(.*?)\]\((.*?)\)', '$1' -replace '[#>*`_]', ' ' -replace '\s+', ' '
    $order++
    [void]$all.Add([pscustomobject]@{
      id = "ch$order"; order = $order; book = $b.book; bookTitle = $b.title
      num = $num; label = $label; isEpilogue = $isEpi
      title = $title; subtitle = $sub; fathom = @($fathom); md = $md; text = $text.Trim()
    })
  }
}

$json = ConvertTo-Json @($all) -Depth 6 -Compress
[System.IO.File]::WriteAllText((Join-Path $root 'data.js'), "window.CHAPTERS = $json;", $utf8)
Write-Host ("Built data.js: {0} chapters ({1})" -f $all.Count, (($all | Group-Object book | ForEach-Object { '{0}={1}' -f $_.Name, $_.Count }) -join ', '))
