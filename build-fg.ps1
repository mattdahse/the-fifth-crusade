# Compiles fg/*.md into a loadable Fantasy Grounds module (.mod).
# Usage:  pwsh -File ./build-fg.ps1  [-Install]
#
# -Install also copies the .mod into the local Fantasy Grounds modules folder.
#
# SAFETY: this script NEVER writes to a campaign db.xml. Fantasy Grounds holds the
# campaign in memory and rewrites it wholesale on exit, so anything written under a
# running FG is silently lost. Modules load additively and are never written back,
# which is why all authoring goes here.
[CmdletBinding()]
param([switch]$Install)

$ErrorActionPreference = 'Stop'
$root  = $PSScriptRoot
$src   = Join-Path $root 'fg'
$utf8  = New-Object System.Text.UTF8Encoding($false)
$em    = [char]0x2014   # em-dash by code point: never type it literally in a .ps1
$warns = New-Object System.Collections.ArrayList

function Warn($m) { [void]$warns.Add($m); Write-Host "  ! $m" -ForegroundColor Yellow }

# ---------------------------------------------------------------- helpers

function Esc([string]$s) {
  if ($null -eq $s) { return '' }
  $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

# Read <!-- key: value --> metadata out of a markdown body.
function Get-Meta([string]$text) {
  $h = @{}
  foreach ($m in [regex]::Matches($text, '<!--\s*([a-zA-Z0-9_-]+)\s*:\s*(.*?)\s*-->')) {
    $k = $m.Groups[1].Value.ToLower()
    $v = $m.Groups[2].Value
    if ($h.ContainsKey($k)) { $h[$k] = @($h[$k]) + $v } else { $h[$k] = $v }
  }
  return $h
}

# Read a fenced stats block into an ordered hashtable.
function Get-Stats([string]$text) {
  $h = [ordered]@{}
  $m = [regex]::Match($text, '(?ms)^```stats\s*$(.*?)^```\s*$')
  if (-not $m.Success) { return $h }
  foreach ($line in ($m.Groups[1].Value -split "`n")) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    $i = $line.IndexOf(':')
    if ($i -lt 1) { continue }
    $h[$line.Substring(0, $i).Trim().ToLower()] = $line.Substring($i + 1).Trim()
  }
  return $h
}

# Strip metadata comments, the stats fence and the H1; what remains is prose.
function Get-Body([string]$text) {
  $t = [regex]::Replace($text, '(?ms)^```stats\s*$.*?^```\s*$', '')
  $t = [regex]::Replace($t, '<!--.*?-->', '')
  $t = [regex]::Replace($t, '(?m)^#\s+.*$', '')
  return $t.Trim()
}

function Format-Inline([string]$s) {
  $s = Esc $s
  $s = [regex]::Replace($s, '\*\*\*(.+?)\*\*\*', '<b><i>$1</i></b>')
  $s = [regex]::Replace($s, '\*\*(.+?)\*\*', '<b>$1</b>')
  $s = [regex]::Replace($s, '\*(.+?)\*', '<i>$1</i>')
  $s = [regex]::Replace($s, '\[(.+?)\]\((.+?)\)', '$1')
  $s = [regex]::Replace($s, '`(.+?)`', '$1')
  return $s
}

# Markdown prose -> FG <formattedtext>.
#
# Parses BLOCKS, not lines. The source is hard-wrapped for readable diffs, so a
# paragraph's wrapped lines must be rejoined before conversion - otherwise every
# wrapped line becomes its own <p>, and worse, an emphasis span that straddles a
# line break never closes.
#
#   ## heading   -> <h>
#   - item       -> <list><li>
#   > quote      -> <frame>   (FG's boxed read-aloud text)
#   anything else-> <p>
function ConvertTo-FormattedText([string]$md, [int]$indent) {
  $pad = "`t" * $indent
  if (-not $md) { return "$pad<p />" }
  $out = New-Object System.Collections.ArrayList

  # Split on blank lines into blocks, keeping each block's lines together.
  foreach ($block in [regex]::Split($md.Trim(), '(?:\r?\n){2,}')) {
    $lines = @($block -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($lines.Count -eq 0) { continue }

    if ($lines[0] -match '^#{2,6}\s+') {
      # A heading block may be followed by prose lines; emit the heading, then the rest.
      [void]$out.Add("$pad<h>$(Format-Inline ($lines[0] -replace '^#{2,6}\s+', ''))</h>")
      if ($lines.Count -gt 1) {
        [void]$out.Add("$pad<p>$(Format-Inline (($lines[1..($lines.Count - 1)]) -join ' '))</p>")
      }
    }
    elseif ($lines[0] -match '^[-*]\s+') {
      # List: a line without a bullet is a continuation of the item above it.
      $items = New-Object System.Collections.ArrayList
      foreach ($l in $lines) {
        if ($l -match '^[-*]\s+(.*)$') { [void]$items.Add($matches[1]) }
        elseif ($items.Count) { $items[$items.Count - 1] = $items[$items.Count - 1] + ' ' + $l }
      }
      [void]$out.Add("$pad<list>")
      foreach ($it in $items) { [void]$out.Add("$pad`t<li>$(Format-Inline $it)</li>") }
      [void]$out.Add("$pad</list>")
    }
    elseif ($lines[0] -match '^>') {
      $q = (($lines | ForEach-Object { $_ -replace '^>\s?', '' }) -join ' ').Trim()
      if ($q) {
        [void]$out.Add("$pad<frame>$(Format-Inline $q)</frame>")
      }
    }
    else {
      [void]$out.Add("$pad<p>$(Format-Inline ($lines -join ' '))</p>")
    }
  }
  if ($out.Count -eq 0) { return "$pad<p />" }
  return ($out -join "`n")
}

function S($tag, $val, $indent) { ("`t" * $indent) + "<$tag type=""string"">$(Esc $val)</$tag>" }
function N($tag, $val, $indent) { ("`t" * $indent) + "<$tag type=""number"">$val</$tag>" }
function T($tag, $val, $indent) { ("`t" * $indent) + "<$tag type=""token"">$(Esc $val)</$tag>" }

# Emit one top-level section. Records go directly under the section node, which is what
# a modern adventure module does (MachineFrequency.mod). An older module wraps them in
# <category>; that is a grouping label, NOT what makes a section list, so it is not used
# here. What makes a section list is the recordtype in the <library> block - see below.
#
# $category is kept as the list's display name only.
function Add-Section($tag, $category, $lines) {
  if (-not $lines -or $lines.Count -eq 0) { return }
  [void]$xml.Add("`t<$tag>")
  foreach ($l in $lines) {
    # A single element may carry embedded newlines (formattedtext); emit each line.
    foreach ($sub in ($l -split "`n")) { [void]$xml.Add($sub) }
  }
  [void]$xml.Add("`t</$tag>")
}

function Read-Docs($sub) {
  $d = Join-Path $src $sub
  if (-not (Test-Path $d)) { return @() }
  Get-ChildItem $d -Filter *.md | Sort-Object Name | ForEach-Object {
    $raw = [IO.File]::ReadAllText($_.FullName)
    $t = [regex]::Match($raw, '(?m)^#\s+(.*)$')
    $meta = Get-Meta $raw
    [pscustomobject]@{
      file  = $_.Name
      title = if ($t.Success) { $t.Groups[1].Value.Trim() } else { $_.BaseName }
      id    = if ($meta.id) { [string]$meta.id } else { $_.BaseName -replace '[^a-zA-Z0-9]+', '_' }
      meta  = $meta
      stats = Get-Stats $raw
      body  = Get-Body $raw
      raw   = $raw
    }
  }
}

# ---------------------------------------------------------------- load

Write-Host "Reading $src"
$modFile = Join-Path $src 'module.md'
if (-not (Test-Path $modFile)) { throw "fg/module.md not found $em it defines the module." }
$modRaw = [IO.File]::ReadAllText($modFile)
$modMeta = Get-Meta $modRaw
$modName = ([regex]::Match($modRaw, '(?m)^#\s+(.*)$')).Groups[1].Value.Trim()
$modId = if ($modMeta.id) { ([string]$modMeta.id) -replace '[^a-zA-Z0-9]', '' } else { 'campaignmodule' }
$ruleset = if ($modMeta.ruleset) { [string]$modMeta.ruleset } else { 'PFRPG' }

$npcs       = @(Read-Docs 'npcs')
$encounters = @(Read-Docs 'encounters')
$parcels    = @(Read-Docs 'parcels')
$quests     = @(Read-Docs 'quests')
$maps       = @(Read-Docs 'maps')
$stories    = @(Read-Docs 'story')

$npcById = @{}
foreach ($n in $npcs) { $npcById[$n.id] = $n }

$xml = New-Object System.Collections.ArrayList
[void]$xml.Add('<?xml version="1.0" encoding="utf-8"?>')
[void]$xml.Add('<root version="4.5" dataversion="20260124" release="1.1|PFRPG:18|CoreRPG:7">')

# ---------------------------------------------------------------- <npc>

if ($npcs.Count) {
  $sec = New-Object System.Collections.ArrayList
  foreach ($n in $npcs) {
    [void]$sec.Add("`t`t<$($n.id)>")
    foreach ($k in @('ac', 'alignment', 'atk', 'babgrp', 'feats', 'fullatk', 'hd', 'languages',
        'senses', 'size', 'skills', 'spacereach', 'specialattacks', 'specialqualities',
        'speed', 'subtype', 'type')) {
      if ($n.stats[$k]) { [void]$sec.Add((S $k $n.stats[$k] 3)) }
    }
    foreach ($k in @('hp', 'init', 'strength', 'dexterity', 'constitution', 'intelligence',
        'wisdom', 'charisma', 'fortitudesave', 'reflexsave', 'willsave')) {
      if ($n.stats[$k]) { [void]$sec.Add((N $k ([int]$n.stats[$k]) 3)) }
    }
    if ($n.stats['cr']) {
      $crRaw = $n.stats['cr']
      $crNum = switch -regex ($crRaw) {
        '^1/2$' { 0.5 }
        '^1/3$' { 0.33 }
        '^1/4$' { 0.25 }
        '^1/8$' { 0.125 }
        default { [double]$crRaw }
      }
      [void]$sec.Add((N 'cr' $crNum 3))
    }
    [void]$sec.Add((S 'name' $n.title 3))
    if ($n.meta.token) {
      [void]$sec.Add((T 'token' ([string]$n.meta.token) 3))
      [void]$sec.Add((T 'picture' ([string]$n.meta.token) 3))
    }
    [void]$sec.Add("`t`t`t<text type=""formattedtext"">")
    [void]$sec.Add((ConvertTo-FormattedText $n.body 4))
    [void]$sec.Add("`t`t`t</text>")
    [void]$sec.Add("`t`t</$($n.id)>")
  }
  Add-Section 'npc' 'NPCs' $sec
}

# ---------------------------------------------------------------- <battle>

if ($encounters.Count) {
  $sec = New-Object System.Collections.ArrayList
  foreach ($e in $encounters) {
    $foes = New-Object System.Collections.ArrayList
    $totalXp = 0
    foreach ($m in [regex]::Matches($e.raw, '(?m)^\s*[-*]\s*(\d+)\s*[xX]\s+([a-zA-Z0-9_]+)\s*$')) {
      $cnt = [int]$m.Groups[1].Value
      $ref = $m.Groups[2].Value
      if (-not $npcById.ContainsKey($ref)) { Warn "$($e.file): unknown npc '$ref'"; continue }
      $npc = $npcById[$ref]
      if ($npc.stats['xp']) { $totalXp += $cnt * [int]($npc.stats['xp'] -replace '[^0-9]', '') }
      [void]$foes.Add(@{ count = $cnt; npc = $npc })
    }
    if ($foes.Count -eq 0) { Warn "$($e.file): no foes resolved"; continue }
    [void]$sec.Add("`t`t<$($e.id)>")
    [void]$sec.Add((N 'exp' $totalXp 3))
    if ($e.meta.level) { [void]$sec.Add((N 'level' ([int]$e.meta.level) 3)) }
    [void]$sec.Add((S 'name' $e.title 3))
    [void]$sec.Add("`t`t`t<npclist>")
    $i = 0
    foreach ($f in $foes) {
      $i++
      $slot = 'id-{0:D5}' -f $i
      [void]$sec.Add("`t`t`t`t<$slot>")
      [void]$sec.Add((N 'count' $f.count 5))
      [void]$sec.Add((S 'faction' 'foe' 5))
      [void]$sec.Add("`t`t`t`t`t<link type=""windowreference"">")
      [void]$sec.Add("`t`t`t`t`t`t<class>npc</class>")
      [void]$sec.Add("`t`t`t`t`t`t<recordname>npc.$($f.npc.id)@$(Esc $modName)</recordname>")
      [void]$sec.Add("`t`t`t`t`t</link>")
      [void]$sec.Add((S 'name' $f.npc.title 5))
      if ($f.npc.meta.token) {
        [void]$sec.Add((T 'token' ("$([string]$f.npc.meta.token)@$modName") 5))
      }
      [void]$sec.Add("`t`t`t`t</$slot>")
    }
    [void]$sec.Add("`t`t`t</npclist>")
    [void]$sec.Add("`t`t</$($e.id)>")
  }
  Add-Section 'battle' 'Encounters' $sec
}

# ---------------------------------------------------------------- <treasureparcels>

if ($parcels.Count) {
  $sec = New-Object System.Collections.ArrayList
  foreach ($p in $parcels) {
    [void]$sec.Add("`t`t<$($p.id)>")
    [void]$sec.Add("`t`t`t<coinlist>")
    $ci = 0
    foreach ($denom in @('PP', 'GP', 'SP', 'CP')) {
      $ci++
      $amt = 0
      $m = [regex]::Match($p.raw, "(?m)^\s*[-*]\s*([\d,]+)\s+$denom\s*$")
      if ($m.Success) { $amt = [int]($m.Groups[1].Value -replace ',', '') }
      $slot = 'id-{0:D5}' -f $ci
      [void]$sec.Add("`t`t`t`t<$slot>")
      [void]$sec.Add((N 'amount' $amt 5))
      [void]$sec.Add((S 'description' $denom 5))
      [void]$sec.Add("`t`t`t`t</$slot>")
    }
    [void]$sec.Add("`t`t`t</coinlist>")
    [void]$sec.Add("`t`t`t<itemlist>")
    $ii = 0
    $itemsPart = ([regex]::Match($p.raw, '(?ms)^##\s+Items\s*$(.*)')).Groups[1].Value
    foreach ($itemSec in [regex]::Matches($itemsPart, '(?ms)^###\s+(.*?)\s*$(.*?)(?=^###\s|\z)')) {
      $ii++
      $iname = $itemSec.Groups[1].Value.Trim()
      $ibody = $itemSec.Groups[2].Value
      $imeta = Get-Meta $ibody
      $slot = 'id-{0:D5}' -f $ii
      [void]$sec.Add("`t`t`t`t<$slot>")
      [void]$sec.Add((N 'carried' 1 5))
      [void]$sec.Add((N 'count' $(if ($imeta.count) { [int]$imeta.count } else { 1 }) 5))
      if ($imeta.cost) { [void]$sec.Add((S 'cost' ([string]$imeta.cost) 5)) }
      if ($imeta.weight) { [void]$sec.Add((N 'weight' ([double]$imeta.weight) 5)) }
      if ($imeta.type) { [void]$sec.Add((S 'type' ([string]$imeta.type) 5)) }
      [void]$sec.Add((S 'name' $iname 5))
      if ($imeta.nonid) {
        [void]$sec.Add((N 'isidentified' 0 5))
        [void]$sec.Add((S 'nonid_name' ([string]$imeta.nonid) 5))
      }
      else { [void]$sec.Add((N 'isidentified' 1 5)) }
      [void]$sec.Add("`t`t`t`t`t<description type=""formattedtext"">")
      [void]$sec.Add((ConvertTo-FormattedText (Get-Body $ibody) 6))
      [void]$sec.Add("`t`t`t`t`t</description>")
      [void]$sec.Add("`t`t`t`t</$slot>")
    }
    [void]$sec.Add("`t`t`t</itemlist>")
    [void]$sec.Add((S 'name' $p.title 3))
    [void]$sec.Add("`t`t</$($p.id)>")
  }
  Add-Section 'treasureparcels' 'Treasure' $sec
}

# ---------------------------------------------------------------- <quest>

if ($quests.Count) {
  $sec = New-Object System.Collections.ArrayList
  foreach ($q in $quests) {
    # A quest's prose lives in <description>, NOT <text> -- and <level> must be present
    # or the sheet reads "Level 0". There is no field for the quest-giver, so the giver
    # goes into <gmnotes> where the GM can actually see it.
    [void]$sec.Add("`t`t<$($q.id)>")
    [void]$sec.Add("`t`t`t<description type=""formattedtext"">")
    [void]$sec.Add((ConvertTo-FormattedText $q.body 4))
    [void]$sec.Add("`t`t`t</description>")
    [void]$sec.Add("`t`t`t<gmnotes type=""formattedtext"">")
    if ($q.meta.giver) {
      [void]$sec.Add((ConvertTo-FormattedText "Given by **$([string]$q.meta.giver)**." 4))
    }
    else { [void]$sec.Add("`t`t`t`t<p />") }
    [void]$sec.Add("`t`t`t</gmnotes>")
    [void]$sec.Add((N 'level' $(if ($q.meta.level) { [int]$q.meta.level } else { 0 }) 3))
    [void]$sec.Add((S 'name' $q.title 3))
    if ($q.meta.xp) { [void]$sec.Add((N 'xp' ([int]$q.meta.xp) 3)) }
    [void]$sec.Add("`t`t</$($q.id)>")
  }
  Add-Section 'quest' 'Quests' $sec
}

# ---------------------------------------------------------------- <image>

$mapsIncluded = 0
if ($maps.Count) {
  $rows = New-Object System.Collections.ArrayList
  foreach ($mp in $maps) {
    $rel = [string]$mp.meta.image
    if (-not $rel) { Warn "$($mp.file): no image marker $em map skipped"; continue }
    if (-not (Test-Path (Join-Path (Join-Path $src 'art') $rel))) {
      Warn "$($mp.file): art missing at fg/art/$rel $em map skipped"
      continue
    }
    $mapsIncluded++
    [void]$rows.Add("`t`t<$($mp.id)>")
    [void]$rows.Add("`t`t`t<image type=""image"">")
    [void]$rows.Add("`t`t`t`t<grid>$(if ($mp.meta.grid) { $mp.meta.grid } else { 'on' })</grid>")
    if ($mp.meta.gridtype) { [void]$rows.Add("`t`t`t`t<gridtype>$($mp.meta.gridtype)</gridtype>") }
    if ($mp.meta.gridsize) { [void]$rows.Add("`t`t`t`t<gridsize>$($mp.meta.gridsize)</gridsize>") }
    [void]$rows.Add("`t`t`t`t<gridsnap>on</gridsnap>")
    [void]$rows.Add("`t`t`t`t<uselos>on</uselos>")
    [void]$rows.Add("`t`t`t`t<layers>")
    [void]$rows.Add("`t`t`t`t`t<layer>")
    [void]$rows.Add("`t`t`t`t`t`t<name>$(Esc $mp.title)</name>")
    [void]$rows.Add("`t`t`t`t`t`t<id>0</id>")
    [void]$rows.Add("`t`t`t`t`t`t<parentid>-2</parentid>")
    [void]$rows.Add("`t`t`t`t`t`t<type>image</type>")
    [void]$rows.Add("`t`t`t`t`t`t<bitmap>$(Esc $rel)</bitmap>")
    $occ = New-Object System.Collections.ArrayList
    if ($mp.meta.occluder) { foreach ($o in @($mp.meta.occluder)) { [void]$occ.Add(@{ pts = $o; open = $false }) } }
    if ($mp.meta.'occluder-open') { foreach ($o in @($mp.meta.'occluder-open')) { [void]$occ.Add(@{ pts = $o; open = $true }) } }
    if ($occ.Count) {
      [void]$rows.Add("`t`t`t`t`t`t<occluders>")
      $oi = 0
      foreach ($o in $occ) {
        $oi++
        $pts = (($o.pts -split '\s+') | Where-Object { $_ }) -join ','
        [void]$rows.Add("`t`t`t`t`t`t`t<occluder>")
        [void]$rows.Add("`t`t`t`t`t`t`t`t<id>$oi</id>")
        [void]$rows.Add("`t`t`t`t`t`t`t`t<points>$pts</points>")
        if ($o.open) {
          [void]$rows.Add("`t`t`t`t`t`t`t`t<terrain />")
          [void]$rows.Add("`t`t`t`t`t`t`t`t<allow_move />")
        }
        [void]$rows.Add("`t`t`t`t`t`t`t</occluder>")
      }
      [void]$rows.Add("`t`t`t`t`t`t</occluders>")
    }
    [void]$rows.Add("`t`t`t`t`t</layer>")
    [void]$rows.Add("`t`t`t`t</layers>")
    [void]$rows.Add("`t`t`t</image>")
    [void]$rows.Add((S 'name' $mp.title 3))
    [void]$rows.Add("`t`t</$($mp.id)>")
  }
  if ($rows.Count) {
    Add-Section 'image' 'Maps' $rows
  }
}

# ---------------------------------------------------------------- <encounter> (story text)

if ($stories.Count) {
  $sec = New-Object System.Collections.ArrayList
  $ordered = $stories | Sort-Object { if ($_.meta.order) { [int]$_.meta.order } else { 999 } }
  foreach ($s in $ordered) {
    [void]$sec.Add("`t`t<$($s.id)>")
    [void]$sec.Add((S 'name' $s.title 3))
    [void]$sec.Add("`t`t`t<text type=""formattedtext"">")
    [void]$sec.Add((ConvertTo-FormattedText $s.body 4))
    [void]$sec.Add("`t`t`t</text>")
    [void]$sec.Add("`t`t</$($s.id)>")
  }
  Add-Section 'encounter' 'Adventure' $sec
}

# ---------------------------------------------------------------- <library>

[void]$xml.Add("`t<library>")
[void]$xml.Add("`t`t<$modId static=""true"">")
[void]$xml.Add((S 'categoryname' ([string]$modMeta.category) 3))
[void]$xml.Add((S 'name' $modName 3))
[void]$xml.Add("`t`t`t<entries>")
# The library's recordtype is the ruleset's RECORD TYPE, which is not always the XML
# node name. CoreRPG's data_library.lua maps them: node <encounter> is recordtype
# "story", and node <treasureparcels> is recordtype "treasureparcel" (singular).
# npc/battle/image/quest happen to share both names, which is exactly why those four
# listed on the first build while the other two came back as empty windows.
$entries = [ordered]@{
  adventure = @('Adventure', 'story')
  quests    = @('Quests', 'quest')
  npcs      = @('NPCs', 'npc')
  battles   = @('Encounters', 'battle')
  parcels   = @('Treasure', 'treasureparcel')
  maps      = @('Maps', 'image')
}
foreach ($k in $entries.Keys) {
  [void]$xml.Add("`t`t`t`t<$k>")
  [void]$xml.Add("`t`t`t`t`t<librarylink type=""windowreference"">")
  [void]$xml.Add("`t`t`t`t`t`t<class>reference_list</class>")
  [void]$xml.Add("`t`t`t`t`t`t<recordname>..</recordname>")
  [void]$xml.Add("`t`t`t`t`t</librarylink>")
  [void]$xml.Add((S 'name' $entries[$k][0] 5))
  [void]$xml.Add((S 'recordtype' $entries[$k][1] 5))
  [void]$xml.Add("`t`t`t`t</$k>")
}
[void]$xml.Add("`t`t`t</entries>")
[void]$xml.Add("`t`t</$modId>")
[void]$xml.Add("`t</library>")
[void]$xml.Add('</root>')

# ---------------------------------------------------------------- write

$stage = Join-Path ([IO.Path]::GetTempPath()) ('fgbuild-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null

$dbText = ($xml -join "`n") + "`n"
[IO.File]::WriteAllText((Join-Path $stage 'db.xml'), $dbText, $utf8)

# Fail loudly here rather than with a silent no-op inside Fantasy Grounds.
try { $null = [xml]$dbText } catch { throw "Generated db.xml is not well-formed XML: $_" }

$def = @(
  '<?xml version="1.0" encoding="utf-8"?>'
  '<root version="4.5" dataversion="20260124" release="1.1|PFRPG:18|CoreRPG:7">'
  "`t<name>$(Esc $modName)</name>"
  "`t<category>$(Esc ([string]$modMeta.category))</category>"
  "`t<author>$(Esc ([string]$modMeta.author))</author>"
  "`t<ruleset>$(Esc $ruleset)</ruleset>"
  '</root>'
) -join "`n"
[IO.File]::WriteAllText((Join-Path $stage 'definition.xml'), $def + "`n", $utf8)

# Art travels inside the .mod under the same relative paths the records reference.
$artSrc = Join-Path $src 'art'
$artCount = 0
if (Test-Path $artSrc) {
  foreach ($f in (Get-ChildItem $artSrc -Recurse -File)) {
    $rel = $f.FullName.Substring($artSrc.Length).TrimStart('\', '/')
    $dst = Join-Path $stage $rel
    New-Item -ItemType Directory -Path (Split-Path $dst) -Force | Out-Null
    Copy-Item $f.FullName $dst -Force
    $artCount++
  }
}

$outDir = Join-Path $root 'build'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$mod = Join-Path $outDir "$modName.mod"
if (Test-Path $mod) { Remove-Item $mod -Force }
try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop } catch { }
[IO.Compression.ZipFile]::CreateFromDirectory($stage, $mod)
Remove-Item $stage -Recurse -Force

Write-Host ''
Write-Host "Built $mod" -ForegroundColor Green
Write-Host ("  npcs {0}  encounters {1}  parcels {2}  quests {3}  maps {4}/{5}  story {6}  art {7}" -f `
    $npcs.Count, $encounters.Count, $parcels.Count, $quests.Count, $mapsIncluded, $maps.Count, $stories.Count, $artCount)
if ($warns.Count) { Write-Host ("  {0} warning(s) above" -f $warns.Count) -ForegroundColor Yellow }

if ($Install) {
  $candidates = @(
    (Join-Path $env:APPDATA 'SmiteWorks/Fantasy Grounds/modules'),
    (Join-Path $HOME 'Library/Application Support/SmiteWorks/Fantasy Grounds/modules'),
    (Join-Path $HOME 'SmiteWorks/Fantasy Grounds/modules'),
    (Join-Path $HOME '.smiteworks/fantasygrounds/modules')
  )
  $dest = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if (-not $dest) { throw ("Could not find the Fantasy Grounds modules folder. Looked in:`n  " + ($candidates -join "`n  ")) }
  Copy-Item $mod (Join-Path $dest ([IO.Path]::GetFileName($mod))) -Force
  Write-Host "Installed to $dest" -ForegroundColor Green
  Write-Host "Close and reopen the module in FG $em it does not hot-reload."
}
