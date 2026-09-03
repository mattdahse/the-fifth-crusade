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
param([switch]$Install, [switch]$ResetModuleCache)

# Fantasy Grounds caches a module's records per campaign, in
# campaigns/<name>/moduledb/<Module Name>.xml, and stamps that cache with the module's
# dataversion. It re-imports only when the module's dataversion is NEWER. A build that
# ships a constant dataversion therefore reaches a campaign exactly once: after that FG
# keeps serving the cache, reloading changes nothing, and the module on disk is provably
# correct the whole time. So the dataversion is the build date, not a literal.
$dataVersion = (Get-Date).ToString('yyyyMMdd')

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

# Pixel dimensions of an image, read from its header.
#
# Occluders are authored in top-left image pixels but FG stores them relative to the
# image CENTRE, so the build has to know how big the plate is to translate them. Headers
# are parsed by hand rather than through System.Drawing: that assembly is Windows-only on
# modern .NET and this build has to run on Matt's Macs too.
function Get-ImageSize([string]$path) {
  $b = [IO.File]::ReadAllBytes($path)
  function BE2($o) { [int]$b[$o] * 256 + [int]$b[$o + 1] }
  function BE4($o) { ([int]$b[$o] -shl 24) -bor ([int]$b[$o + 1] -shl 16) -bor ([int]$b[$o + 2] -shl 8) -bor [int]$b[$o + 3] }
  function LE2($o) { [int]$b[$o + 1] * 256 + [int]$b[$o] }
  function LE4($o) { ([int]$b[$o + 3] -shl 24) -bor ([int]$b[$o + 2] -shl 16) -bor ([int]$b[$o + 1] -shl 8) -bor [int]$b[$o] }

  # PNG: IHDR width/height are the two big-endian ints at offset 16.
  if ($b.Length -gt 24 -and $b[0] -eq 0x89 -and $b[1] -eq 0x50) {
    return @{ w = (BE4 16); h = (BE4 20) }
  }
  # GIF: little-endian shorts in the logical screen descriptor.
  if ($b.Length -gt 10 -and $b[0] -eq 0x47 -and $b[1] -eq 0x49 -and $b[2] -eq 0x46) {
    return @{ w = (LE2 6); h = (LE2 8) }
  }
  # BMP
  if ($b.Length -gt 26 -and $b[0] -eq 0x42 -and $b[1] -eq 0x4D) {
    return @{ w = (LE4 18); h = [Math]::Abs((LE4 22)) }
  }
  # WebP: RIFF container, then a VP8 / VP8L / VP8X chunk, each with its own encoding.
  if ($b.Length -gt 30 -and $b[0] -eq 0x52 -and $b[8] -eq 0x57 -and $b[9] -eq 0x45) {
    $tag = [Text.Encoding]::ASCII.GetString($b, 12, 4)
    if ($tag -eq 'VP8X') { return @{ w = 1 + (([int]$b[26] -shl 16) -bor ([int]$b[25] -shl 8) -bor [int]$b[24]); h = 1 + (([int]$b[29] -shl 16) -bor ([int]$b[28] -shl 8) -bor [int]$b[27]) } }
    if ($tag -eq 'VP8L') {
      $n = ([int]$b[22] -shl 16) -bor ([int]$b[22 - 1] -shl 8) -bor [int]$b[21]
      return @{ w = 1 + ($n -band 0x3FFF); h = 1 + (((([int]$b[24] -shl 24) -bor ([int]$b[23] -shl 16) -bor ([int]$b[22] -shl 8) -bor [int]$b[21]) -shr 14) -band 0x3FFF) }
    }
    if ($tag -eq 'VP8 ') { return @{ w = (LE2 26) -band 0x3FFF; h = (LE2 28) -band 0x3FFF } }
  }
  # JPEG: walk the segment chain to a start-of-frame marker, which carries the size.
  if ($b.Length -gt 4 -and $b[0] -eq 0xFF -and $b[1] -eq 0xD8) {
    $i = 2
    while ($i -lt $b.Length - 9) {
      if ($b[$i] -ne 0xFF) { $i++; continue }
      $m = $b[$i + 1]
      if ($m -eq 0xD8 -or $m -eq 0x01 -or ($m -ge 0xD0 -and $m -le 0xD7)) { $i += 2; continue }
      $len = BE2 ($i + 2)
      # SOF0-SOF15, excluding the DHT/JPG/DAC markers that share the range.
      if ($m -ge 0xC0 -and $m -le 0xCF -and $m -ne 0xC4 -and $m -ne 0xC8 -and $m -ne 0xCC) {
        return @{ w = (BE2 ($i + 7)); h = (BE2 ($i + 5)) }
      }
      $i += 2 + $len
    }
  }
  return $null
}

# ---------------------------------------------------------------- items

# Mundane gear copied out of the SRD rather than hand-written.
#
# A parcel item that only carries a name, a cost and a weight ships an item FG cannot
# use: a longspear with no damage rolls nothing, and a chain shirt with no <ac> gives
# no armour when a player equips it. Those fields are not optional decoration, they are
# what the record is FOR. So an item is looked up by name in PF-SRD-Basic-Rules.mod and
# its real fields are copied in, exactly as spells already are.
#
# The SRD keeps this in client.xml (not db.xml) under reference.weapon / .armor /
# .equipment - three separate lists, so all three are searched.
$script:ItemIndex = $null
function Get-ItemIndex {
  if ($null -ne $script:ItemIndex) { return $script:ItemIndex }
  $idx = @{}
  $modDir = Get-ModulesDir
  foreach ($modName in @('PF-SRD-Basic-Rules.mod', '3.5E-basicrules.mod')) {
    $mod = Join-Path $modDir $modName
    if (-not (Test-Path $mod)) { continue }
    try {
      $zip = [IO.Compression.ZipFile]::OpenRead($mod)
      foreach ($entryName in @('client.xml', 'db.xml')) {
        $entry = $zip.Entries | Where-Object { $_.FullName -eq $entryName } | Select-Object -First 1
        if (-not $entry) { continue }
        $sr = New-Object IO.StreamReader($entry.Open())
        $xmlText = $sr.ReadToEnd(); $sr.Close()
        $doc = [xml]$xmlText
        $ref = $doc.root.reference
        if (-not $ref) { continue }
        foreach ($grp in @('weapon', 'armor', 'equipment')) {
          $node = $ref.$grp
          if (-not $node) { continue }
          foreach ($rec in $node.ChildNodes) {
            if ($rec.NodeType -ne 'Element') { continue }
            $nm = $rec.SelectSingleNode('name')
            if (-not $nm) { continue }
            $key = ($nm.InnerText -replace '[^a-zA-Z0-9]', '').ToLower()
            if ($key -and -not $idx.ContainsKey($key)) { $idx[$key] = $rec }
          }
        }
      }
      $zip.Dispose()
    }
    catch { Warn "could not read $modName for item lookup: $_" }
  }
  $script:ItemIndex = $idx
  return $idx
}

# Fields worth copying. Anything the markdown sets wins over the SRD value.
$itemStrFields = @('cost', 'damage', 'critical', 'damagetype', 'properties', 'type', 'subtype')
$itemNumFields = @('weight', 'ac', 'maxstatbonus', 'checkpenalty', 'spellfailure', 'speed30', 'speed20', 'range')

# ---------------------------------------------------------------- spells

# An NPC's <spellset> carries each spell's FULL text inline - description, components,
# range, save, school, and an <actions> block that makes the cast button work. Hand-writing
# that is not viable, so spells are looked up by name from the SRD spell module and copied in.
# PF-SRD-Spells.mod keeps its data in client.xml, NOT db.xml, under <spelldesc>.
$script:SpellIndex = $null

function Get-ModulesDir {
  $candidates = @(
    (Join-Path $env:APPDATA 'SmiteWorks/Fantasy Grounds/modules'),
    (Join-Path $HOME 'Library/Application Support/SmiteWorks/Fantasy Grounds/modules'),
    (Join-Path $HOME 'SmiteWorks/Fantasy Grounds/modules'),
    (Join-Path $HOME '.smiteworks/fantasygrounds/modules')
  )
  return ($candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
}

function Get-SpellIndex {
  if ($null -ne $script:SpellIndex) { return $script:SpellIndex }
  $idx = @{}
  $dir = Get-ModulesDir
  if (-not $dir) { Warn 'no Fantasy Grounds modules folder found; spells cannot be looked up' }
  else {
    try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop } catch { }
    foreach ($modName in @('PF-SRD-Spells.mod', '3.5E-spells.mod')) {
      $path = Join-Path $dir $modName
      if (-not (Test-Path $path)) { continue }
      $zip = [IO.Compression.ZipFile]::OpenRead($path)
      try {
        foreach ($entryName in @('client.xml', 'db.xml')) {
          $entry = $zip.Entries | Where-Object { $_.FullName -eq $entryName } | Select-Object -First 1
          if (-not $entry) { continue }
          $reader = New-Object IO.StreamReader($entry.Open())
          $text = $reader.ReadToEnd()
          $reader.Close()
          [xml]$doc = $text
          $bank = $doc.root.SelectSingleNode('spelldesc')
          if (-not $bank) { continue }
          foreach ($rec in $bank.ChildNodes) {
            if ($rec.NodeType -ne 'Element') { continue }
            # SelectSingleNode('name'), never .Name -- these carry a child <name> that
            # hijacks PowerShell's XML adapter.
            $nameNode = $rec.SelectSingleNode('name')
            if (-not $nameNode) { continue }
            $key = ($nameNode.InnerText -replace '[^a-zA-Z0-9]', '').ToLower()
            if (-not $idx.ContainsKey($key)) { $idx[$key] = $rec }
          }
          break
        }
      }
      finally { $zip.Dispose() }
    }
  }
  $script:SpellIndex = $idx
  return $idx
}

function Get-SpellField($rec, [string]$tag) {
  $n = $rec.SelectSingleNode($tag)
  if (-not $n) { return '' }
  return ([string]$n.InnerText).Trim()
}

# FG's own drag-and-drop writes a spellset description as a plain string with a literal \n
# between paragraphs, so match that rather than copying the source formattedtext across.
function Get-SpellDescription($rec) {
  $n = $rec.SelectSingleNode('description')
  if (-not $n) { return '' }
  $ps = $n.SelectNodes('p')
  if ($ps -and $ps.Count -gt 0) {
    return ((@($ps | ForEach-Object { ([string]$_.InnerText).Trim() }) | Where-Object { $_ }) -join '\n')
  }
  return ([string]$n.InnerText).Trim()
}

# Read a fenced spells block: caster settings plus one "N: spell, spell" line per level.
function Get-SpellPlan([string]$text) {
  $m = [regex]::Match($text, '(?ms)^```spells\s*$(.*?)^```\s*$')
  if (-not $m.Success) { return $null }
  $plan = @{ castertype = 'prepared'; cl = 1; ability = ''; label = ''; levels = @{} }
  foreach ($line in ($m.Groups[1].Value -split "`n")) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    $i = $line.IndexOf(':')
    if ($i -lt 1) { continue }
    $k = $line.Substring(0, $i).Trim().ToLower()
    $v = $line.Substring($i + 1).Trim()
    if ($k -match '^[0-9]$') { $plan.levels[[int]$k] = $v } else { $plan[$k] = $v }
  }
  return $plan
}

function Get-AbilityMod($stats, [string]$ability) {
  if (-not $ability) { return 0 }
  $score = $stats[$ability.ToLower()]
  if (-not $score) { return 0 }
  return [int][math]::Floor((([int]$score) - 10) / 2)
}

# Build a spell's <actions> block.
#
# The cast action alone only posts the spell and its save to chat. What makes a spell
# usable at the table is the damage / heal / effect actions beside it, and FG has no way
# to derive those from a spell's prose - they are hand-modelled data. So they are declared
# in the spells block, one line per spell:
#
#   burning hands: damage d4 per cl max 5 fire
#   cure light wounds: heal d8 plus 1 per cl max 5
#   touch of fatigue: effect Fatigued for 1 round per cl
#
# Clauses are separated by ";" and any number may appear on one line. "onmiss half" is
# added to the cast action automatically whenever the spell's save line says "half".
function Build-SpellActions($rec, [string]$spec, [string]$pad) {
  $out = New-Object System.Collections.ArrayList
  $save = Get-SpellField $rec 'save'
  $sr = Get-SpellField $rec 'sr'
  $order = 0

  # --- the cast action, always present
  $order++
  [void]$out.Add("$pad<id-{0:D5}>" -f $order)
  # "Will half (harmless)" on a cure spell is not a half-damage-on-save case, so only
  # carry onmissdamage across when the spell actually deals damage.
  if ($save -match '(?i)half' -and $spec -match '(?i)\bdamage\b') {
    [void]$out.Add("$pad`t<onmissdamage type=""string"">half</onmissdamage>")
  }
  [void]$out.Add("$pad`t<order type=""number"">$order</order>")
  if ($save -match '^(Reflex|Will|Fortitude)') {
    [void]$out.Add("$pad`t<savetype type=""string"">$($matches[1].ToLower())</savetype>")
  }
  if ($sr -match '^No') { [void]$out.Add("$pad`t<srnotallowed type=""number"">1</srnotallowed>") }
  [void]$out.Add("$pad`t<type type=""string"">cast</type>")
  [void]$out.Add(("$pad</id-{0:D5}>" -f $order))

  if (-not $spec) { return $out.ToArray() }

  # FG effect labels legitimately contain semicolons ("Align Weapon - Good; DMGTYPE: good"),
  # so a fragment that does not begin with a clause keyword belongs to the clause before it.
  $clauses = New-Object System.Collections.ArrayList
  foreach ($frag in ($spec -split ';')) {
    $f = $frag.Trim()
    if (-not $f) { continue }
    if ($f -match '(?i)^(damage|heal|effect|onmiss)\s' -or $clauses.Count -eq 0) {
      [void]$clauses.Add($f)
    }
    else {
      $clauses[$clauses.Count - 1] = $clauses[$clauses.Count - 1] + '; ' + $f
    }
  }

  foreach ($clause in $clauses) {
    $c = $clause.Trim()
    if (-not $c) { continue }

    # --- damage DICE [per cl] [max N] [TYPE]
    if ($c -match '(?i)^damage\s+(\d*d\d+)(?:\s+per\s+cl)?(?:\s+max\s+(\d+))?(?:\s+([a-zA-Z]+))?\s*$') {
      $dice = $matches[1]
      $max = $matches[2]
      $dtype = $matches[3]
      $perCl = $c -match '(?i)\sper\s+cl'
      $order++
      [void]$out.Add(("$pad<id-{0:D5}>" -f $order))
      [void]$out.Add("$pad`t<damagelist>")
      [void]$out.Add("$pad`t`t<id-00001>")
      [void]$out.Add("$pad`t`t`t<bonus type=""number"">0</bonus>")
      [void]$out.Add("$pad`t`t`t<dice type=""dice"">$dice</dice>")
      if ($perCl) { [void]$out.Add("$pad`t`t`t<dicestat type=""string"">cl</dicestat>") }
      if ($max) { [void]$out.Add("$pad`t`t`t<dicestatmax type=""number"">$max</dicestatmax>") }
      if ($dtype) { [void]$out.Add("$pad`t`t`t<type type=""string"">$(Esc $dtype.ToLower())</type>") }
      [void]$out.Add("$pad`t`t</id-00001>")
      [void]$out.Add("$pad`t</damagelist>")
      [void]$out.Add("$pad`t<order type=""number"">$order</order>")
      [void]$out.Add("$pad`t<type type=""string"">damage</type>")
      [void]$out.Add(("$pad</id-{0:D5}>" -f $order))
      continue
    }

    # --- heal DICE [plus N per cl] [max N] [self]
    if ($c -match '(?i)^heal\s+(\d*d\d+)(?:\s+plus\s+(\d+)\s+per\s+cl)?(?:\s+max\s+(\d+))?(\s+self)?\s*$') {
      $dice = $matches[1]
      $mult = $matches[2]
      $max = $matches[3]
      $self = $matches[4]
      $order++
      [void]$out.Add(("$pad<id-{0:D5}>" -f $order))
      [void]$out.Add("$pad`t<heallist>")
      [void]$out.Add("$pad`t`t<id-00001>")
      [void]$out.Add("$pad`t`t`t<bonus type=""number"">0</bonus>")
      [void]$out.Add("$pad`t`t`t<dice type=""dice"">$dice</dice>")
      [void]$out.Add("$pad`t`t`t<dicestatmax type=""number"">1</dicestatmax>")
      if ($max) { [void]$out.Add("$pad`t`t`t<statmax type=""number"">$max</statmax>") }
      if ($mult) { [void]$out.Add("$pad`t`t`t<statmult type=""number"">$mult</statmult>") }
      [void]$out.Add("$pad`t`t</id-00001>")
      [void]$out.Add("$pad`t</heallist>")
      if ($self) { [void]$out.Add("$pad`t<healtargeting type=""string"">self</healtargeting>") }
      [void]$out.Add("$pad`t<order type=""number"">$order</order>")
      [void]$out.Add("$pad`t<type type=""string"">heal</type>")
      [void]$out.Add(("$pad</id-{0:D5}>" -f $order))
      continue
    }

    # --- effect LABEL [for N round|minute|hour|day [per cl]]
    if ($c -match '(?i)^effect\s+(.+?)(?:\s+for\s+(\d+)\s+(round|minute|hour|day)s?(\s+per\s+cl)?)?\s*$') {
      $label = $matches[1].Trim()
      $durN = $matches[2]
      $durUnit = $matches[3]
      $perCl = $matches[4]
      $order++
      [void]$out.Add(("$pad<id-{0:D5}>" -f $order))
      [void]$out.Add("$pad`t<dmaxstat type=""number"">0</dmaxstat>")
      [void]$out.Add("$pad`t<durdice type=""dice""></durdice>")
      [void]$out.Add("$pad`t<durdicestatmax type=""number"">0</durdicestatmax>")
      if ($perCl) {
        [void]$out.Add("$pad`t<durmod type=""number"">0</durmod>")
        [void]$out.Add("$pad`t<durmult type=""number"">$(if ($durN) { $durN } else { 1 })</durmult>")
        [void]$out.Add("$pad`t<durstat type=""string"">cl</durstat>")
      }
      else {
        [void]$out.Add("$pad`t<durmod type=""number"">$(if ($durN) { $durN } else { 0 })</durmod>")
        [void]$out.Add("$pad`t<durmult type=""number"">0</durmult>")
        [void]$out.Add("$pad`t<durstat type=""string""></durstat>")
      }
      [void]$out.Add("$pad`t<durunit type=""string"">$(if ($durUnit) { $durUnit.ToLower() } else { 'minute' })</durunit>")
      [void]$out.Add("$pad`t<label type=""string"">$(Esc $label)</label>")
      [void]$out.Add("$pad`t<order type=""number"">$order</order>")
      [void]$out.Add("$pad`t<type type=""string"">effect</type>")
      [void]$out.Add(("$pad</id-{0:D5}>" -f $order))
      continue
    }

    Warn "spell action not understood: $c"
  }
  return $out.ToArray()
}

# Emit an NPC's <spellset> at the given indent. Returns lines, or nothing if the NPC has
# no spells block.
function Build-SpellSet($npc, [int]$indent) {
  $plan = Get-SpellPlan $npc.raw
  if (-not $plan) { return @() }
  $pad = "`t" * $indent
  $idx = Get-SpellIndex
  $mod = Get-AbilityMod $npc.stats ([string]$plan.ability)
  $cl = 1
  if ($plan.cl) { $cl = [int]$plan.cl }
  $label = [string]$plan.label
  if (-not $label) {
    $label = if ([string]$plan.castertype -eq 'spontaneous') { 'Spells Known' } else { 'Spells Prepared' }
  }

  # Resolve every named spell first, so the per-level counts are known before emitting.
  $byLevel = @{}
  foreach ($lvl in ($plan.levels.Keys | Sort-Object)) {
    $entries = New-Object System.Collections.ArrayList
    foreach ($raw in (([string]$plan.levels[$lvl]) -split ',')) {
      $nm = $raw.Trim()
      if (-not $nm) { continue }
      $count = 1
      if ($nm -match '^(.*?)\s*[xX]\s*(\d+)$') { $nm = $matches[1].Trim(); $count = [int]$matches[2] }
      $key = ($nm -replace '[^a-zA-Z0-9]', '').ToLower()
      if (-not $idx.ContainsKey($key)) {
        Warn "$($npc.file): no SRD spell named '$nm' -- skipped"
        continue
      }
      for ($c = 0; $c -lt $count; $c++) { [void]$entries.Add($idx[$key]) }
    }
    $byLevel[$lvl] = $entries
  }

  $out = New-Object System.Collections.ArrayList
  [void]$out.Add("$pad<spellset>")
  [void]$out.Add("$pad`t<id-00001>")
  for ($l = 0; $l -le 9; $l++) {
    $n = 0
    if ($byLevel.ContainsKey($l)) { $n = $byLevel[$l].Count }
    [void]$out.Add("$pad`t`t<availablelevel$l type=""number"">$n</availablelevel$l>")
  }
  [void]$out.Add("$pad`t`t<castertype type=""string"">$(Esc ([string]$plan.castertype))</castertype>")
  [void]$out.Add("$pad`t`t<cc>")
  [void]$out.Add("$pad`t`t`t<misc type=""number"">0</misc>")
  [void]$out.Add("$pad`t`t</cc>")
  [void]$out.Add("$pad`t`t<cl type=""number"">$cl</cl>")
  [void]$out.Add("$pad`t`t<dc>")
  if ($plan.ability) {
    [void]$out.Add("$pad`t`t`t<ability type=""string"">$(Esc ([string]$plan.ability).ToLower())</ability>")
  }
  [void]$out.Add("$pad`t`t`t<abilitymod type=""number"">$mod</abilitymod>")
  [void]$out.Add("$pad`t`t`t<misc type=""number"">0</misc>")
  [void]$out.Add("$pad`t`t`t<total type=""number"">$(10 + $mod)</total>")
  [void]$out.Add("$pad`t`t</dc>")
  [void]$out.Add("$pad`t`t<label type=""string"">$(Esc $label)</label>")
  [void]$out.Add("$pad`t`t<levels>")
  for ($l = 0; $l -le 9; $l++) {
    $entries = @()
    if ($byLevel.ContainsKey($l)) { $entries = $byLevel[$l] }
    [void]$out.Add("$pad`t`t`t<level$l>")
    [void]$out.Add("$pad`t`t`t`t<level type=""number"">$l</level>")
    [void]$out.Add("$pad`t`t`t`t<maxprepared type=""number"">$($entries.Count)</maxprepared>")
    [void]$out.Add("$pad`t`t`t`t<spells>")
    $i = 0
    foreach ($rec in $entries) {
      $i++
      $slot = 'id-{0:D5}' -f $i
      $spellName = Get-SpellField $rec 'name'
      $actionSpec = ''
      $specKey = $spellName.ToLower()
      if ($plan.ContainsKey($specKey)) { $actionSpec = [string]$plan[$specKey] }
      [void]$out.Add("$pad`t`t`t`t`t<$slot>")
      [void]$out.Add("$pad`t`t`t`t`t`t<actions>")
      foreach ($actLine in (Build-SpellActions $rec $actionSpec "$pad`t`t`t`t`t`t`t")) {
        [void]$out.Add($actLine)
      }
      [void]$out.Add("$pad`t`t`t`t`t`t</actions>")
      [void]$out.Add("$pad`t`t`t`t`t`t<cast type=""number"">0</cast>")
      foreach ($f in @('castingtime', 'components')) {
        [void]$out.Add("$pad`t`t`t`t`t`t<$f type=""string"">$(Esc (Get-SpellField $rec $f))</$f>")
      }
      [void]$out.Add("$pad`t`t`t`t`t`t<cost type=""number"">0</cost>")
      [void]$out.Add("$pad`t`t`t`t`t`t<description type=""string"">$(Esc (Get-SpellDescription $rec))</description>")
      foreach ($f in @('duration', 'effect', 'level')) {
        [void]$out.Add("$pad`t`t`t`t`t`t<$f type=""string"">$(Esc (Get-SpellField $rec $f))</$f>")
      }
      [void]$out.Add("$pad`t`t`t`t`t`t<linkedspells />")
      [void]$out.Add("$pad`t`t`t`t`t`t<name type=""string"">$(Esc $spellName)</name>")
      [void]$out.Add("$pad`t`t`t`t`t`t<prepared type=""number"">1</prepared>")
      foreach ($f in @('range', 'save', 'school', 'shortdescription', 'sr')) {
        [void]$out.Add("$pad`t`t`t`t`t`t<$f type=""string"">$(Esc (Get-SpellField $rec $f))</$f>")
      }
      [void]$out.Add("$pad`t`t`t`t`t</$slot>")
    }
    [void]$out.Add("$pad`t`t`t`t</spells>")
    [void]$out.Add("$pad`t`t`t`t<totalcast type=""number"">0</totalcast>")
    [void]$out.Add("$pad`t`t`t`t<totalprepared type=""number"">$($entries.Count)</totalprepared>")
    [void]$out.Add("$pad`t`t`t</level$l>")
  }
  [void]$out.Add("$pad`t`t</levels>")
  [void]$out.Add("$pad`t</id-00001>")
  [void]$out.Add("$pad</spellset>")
  return $out.ToArray()
}

# Strip metadata comments, the stats fence and the H1; what remains is prose.
function Get-Body([string]$text) {
  $t = [regex]::Replace($text, '(?ms)^```stats\s*$.*?^```\s*$', '')
  $t = [regex]::Replace($t, '(?ms)^```spells\s*$.*?^```\s*$', '')
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
  # FG's formattedtext renderer puts a space after every inline element, so "<b>X</b>,"
  # comes out as "X ," on screen. Pull trailing punctuation inside the tag instead - the
  # chronicle voice bolds a name in almost every sentence, so this shows up constantly.
  for ($i = 0; $i -lt 2; $i++) {
    $s = [regex]::Replace($s, '</(b|i)>([,.;:!?]+)', '$2</$1>')
  }
  return $s
}

# Record links. FG puts links in a block-level <linklist>, never inline in a <p>, so a
# link is its own block in the source. `class` is the RECORD TYPE and `recordname` is the
# NODE path - the two differ for parcels and story, exactly as in the <library> block.
# Links within one module need no @Module suffix.
$linkKinds = @{
  npc     = @{ node = 'npc';             class = 'npc';            label = 'NPC' }
  battle  = @{ node = 'battle';          class = 'battle';         label = 'Encounter' }
  parcel  = @{ node = 'treasureparcels'; class = 'treasureparcel'; label = 'Parcel' }
  map     = @{ node = 'image';           class = 'imagewindow';    label = 'Image' }
  quest   = @{ node = 'quest';           class = 'quest';          label = 'Quest' }
  story   = @{ node = 'encounter';       class = 'encounter';      label = 'Story' }
  # Poison, grab, and the rest of a monster's non-standard rules. Published bestiaries
  # ship these as their own records rather than burying them in the statblock text, so
  # the rule is one click from the creature that uses it.
  # The window class is NOT the recordtype here. data_library_35E.lua gives
  # specialability sRecordDisplayClass = "referenceclassability", and a link carrying
  # the recordtype instead simply opens nothing when clicked - no error, no window.
  # Published modules put the data under reference.specialabilities, so we do too.
  ability = @{ node = 'reference.specialabilities'; class = 'referenceclassability'; label = 'Ability' }
}
$linkTitles = @{}   # "kind:id" -> display title, filled in once the docs are loaded

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
  # A scaffold placeholder that reaches the module is a record with the word TODO on it
  # open in front of the players. new.py stamps them deliberately; this is what stops one
  # being forgotten.
  if ($md -match 'TODO') {
    $first = ($md -split "`n" | Where-Object { $_ -match 'TODO' } | Select-Object -First 1).Trim()
    Warn "unfilled scaffold placeholder $em $($first.Substring(0, [Math]::Min(80, $first.Length)))"
  }
  # Emphasis that overlaps produces crossed tags - <b>..<i>..</b> - and the XML check at
  # the end of the build then fails with the whole document as its error message, which
  # says nothing about where. `***word***` is the usual culprit. Name the file instead.
  foreach ($para in ($md -split "`n`n")) {
    $j = ($para -split "`n" | ForEach-Object { $_.Trim() }) -join ' '
    # An EVEN number of *** is a legitimate bold-italic span (***word***). An ODD one
    # means a ** and a * closed in the wrong order, which is what crosses the tags.
    if ((([regex]::Matches($j, '\*\*\*')).Count % 2) -eq 1) {
      Warn "ambiguous *** emphasis $em split the bold and the italic: $($j.Substring(0, [Math]::Min(90, $j.Length)))"
    }
  }
  # An @link only becomes a link when it is its own block - FG has no inline link, and a
  # paragraph that mentions one silently loses it. Silently is the problem, so say so.
  foreach ($ln in ($md -split "`n")) {
    if ($ln -match '@link\s' -and $ln -notmatch '^\s*@link\s') {
      Warn "an @link mid-paragraph is dropped $em put it on its own line: $($ln.Trim())"
    }
  }
  $pad = "`t" * $indent
  if (-not $md) { return "$pad<p />" }
  $out = New-Object System.Collections.ArrayList

  # Split on blank lines into blocks, keeping each block's lines together.
  foreach ($block in [regex]::Split($md.Trim(), '(?:\r?\n){2,}')) {
    $lines = @($block -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($lines.Count -eq 0) { continue }

    if ($lines[0] -match '^@link\s+') {
      [void]$out.Add("$pad<linklist>")
      foreach ($l in $lines) {
        if ($l -notmatch '^@link\s+([a-zA-Z]+)\s*:\s*([A-Za-z0-9_]+)\s*(?:\|\s*(.+?))?$') {
          Warn "link not understood: $l"
          continue
        }
        $kind = $matches[1].ToLower()
        $id = $matches[2]
        $custom = $matches[3]
        if ($kind -eq 'encounter') { $kind = 'battle' }
        if ($kind -eq 'image') { $kind = 'map' }
        if (-not $linkKinds.ContainsKey($kind)) { Warn "unknown link kind '$kind' in: $l"; continue }
        $k = $linkKinds[$kind]
        $title = $custom
        if (-not $title) {
          if ($linkTitles.ContainsKey("${kind}:$id")) { $title = $linkTitles["${kind}:$id"] }
          else { Warn "link points at nothing: $kind`:$id"; $title = $id }
        }
        [void]$out.Add("$pad`t<link class=""$($k.class)"" recordname=""$($k.node).$id""><b>$($k.label): </b>$(Esc $title)</link>")
      }
      [void]$out.Add("$pad</linklist>")
    }
    elseif ($lines[0] -match '^#{2,6}\s+') {
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
$abilities  = @(Read-Docs 'abilities')
# fg/images/ holds portrait and handout records. They are <image> records exactly like
# a battlemap - that is the only record type an @link image can point at - so they build
# through the same path and simply carry `grid: off`.
$maps       = @(Read-Docs 'maps') + @(Read-Docs 'images')
$stories    = @(Read-Docs 'story')

$npcById = @{}
foreach ($n in $npcs) { $npcById[$n.id] = $n }

foreach ($n in $npcs)       { $linkTitles["npc:$($n.id)"] = $n.title }
foreach ($e in $encounters) { $linkTitles["battle:$($e.id)"] = $e.title }
foreach ($p in $parcels)    { $linkTitles["parcel:$($p.id)"] = $p.title }
foreach ($q in $quests)     { $linkTitles["quest:$($q.id)"] = $q.title }
foreach ($a in $abilities)  { $linkTitles["ability:$($a.id)"] = $a.title }
foreach ($m in $maps)       { $linkTitles["map:$($m.id)"] = $m.title }
foreach ($t in $stories)    { $linkTitles["story:$($t.id)"] = $t.title }

$xml = New-Object System.Collections.ArrayList
[void]$xml.Add('<?xml version="1.0" encoding="utf-8"?>')
[void]$xml.Add("<root version=""4.5"" dataversion=""$dataVersion"" release=""1.1|PFRPG:18|CoreRPG:7"">")

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
    # Every NPC gets a token. FG falls back to a lettered marker without one, which is
    # unreadable the moment there is more than one kind of enemy on the map.
    if (-not $n.meta.token) { Warn "$($n.file): no token $em every NPC needs one" }
    if ($n.meta.token) {
      # A token marker pointing at a file that is not there ships a broken reference:
      # FG falls back to a default marker and says nothing, so catch it at build time.
      # A path containing @ names an asset in ANOTHER module - FG's own cross-module
      # reference - so it is not on disk here and must not be checked for or copied.
      # Standard bestiary monsters usually already have official art; use it.
      if (([string]$n.meta.token) -notmatch '@' -and
          -not (Test-Path (Join-Path (Join-Path $src 'art') ([string]$n.meta.token)))) {
        Warn "$($n.file): token art missing at fg/art/$([string]$n.meta.token)"
      }
      [void]$sec.Add((T 'token' ([string]$n.meta.token) 3))
      # <picture> is what the NPC sheet shows, so it wants the full-size portrait when
      # there is one. Falls back to the token, which is better than an empty frame.
      $pic = if ($n.meta.portrait) { [string]$n.meta.portrait } else { [string]$n.meta.token }
      if ($n.meta.portrait -and $pic -notmatch '@' -and -not (Test-Path (Join-Path (Join-Path $src 'art') $pic))) {
        Warn "$($n.file): portrait art missing at fg/art/$pic"
      }
      [void]$sec.Add((T 'picture' $pic 3))
    }
    [void]$sec.Add("`t`t`t<text type=""formattedtext"">")
    [void]$sec.Add((ConvertTo-FormattedText $n.body 4))
    [void]$sec.Add("`t`t`t</text>")
    $spellLines = Build-SpellSet $n 3
    if ($spellLines.Count) {
      # These two drive how the Spells tab renders; without them the set is stored
      # but the tab does not show a usable casting layout.
      $mode = if ((Get-SpellPlan $n.raw).castertype -eq 'spontaneous') { 'standard' } else { 'preparation' }
      [void]$sec.Add((S 'spellmode' $mode 3))
      [void]$sec.Add((S 'spelldisplaymode' 'action' 3))
      foreach ($spellLine in $spellLines) { [void]$sec.Add($spellLine) }
    }
    [void]$sec.Add("`t`t</$($n.id)>")
  }
  Add-Section 'npc' 'NPCs' $sec
}

# ---------------------------------------------------------------- <battle>

if ($encounters.Count) {
  $sec = New-Object System.Collections.ArrayList
  foreach ($e in $encounters) {
    # An FG <battle> holds only name, level, exp and npclist - there is no text field, so
    # prose in an encounter file is discarded. Say so; it belongs in a story record.
    $prose = @(($e.body -split "`n") | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*[-#>|]' -and $_ -notmatch '^\s*<!--' })
    if ($prose.Count -gt 2) {
      Warn "$($e.file): prose in an encounter is dropped $em an FG battle has no text field; move it to fg/story/"
    }
    $foes = New-Object System.Collections.ArrayList
    $totalXp = 0
    # A foe line may carry where its tokens stand on the map:
    #     - 3x labyrinth_squatter @ 250,300; 400,350; 300,620
    # in top-left pixels of that map's plate, converted below to FG's own space.
    foreach ($m in [regex]::Matches($e.raw, '(?m)^\s*[-*]\s*(\d+)\s*[xX]\s+([a-zA-Z0-9_]+)\s*(?:@\s*(.+?))?\s*$')) {
      $cnt = [int]$m.Groups[1].Value
      $ref = $m.Groups[2].Value
      if (-not $npcById.ContainsKey($ref)) { Warn "$($e.file): unknown npc '$ref'"; continue }
      $npc = $npcById[$ref]
      if ($npc.stats['xp']) { $totalXp += $cnt * [int]($npc.stats['xp'] -replace '[^0-9]', '') }
      $spots = @()
      if ($m.Groups[3].Success) {
        foreach ($pair in ($m.Groups[3].Value -split ';')) {
          $c = $pair.Trim() -split ','
          if ($c.Count -ne 2) { Warn "$($e.file): placement '$($pair.Trim())' is not x,y"; continue }
          $spots += , @([double]$c[0], [double]$c[1])
        }
        if ($spots.Count -ne $cnt) {
          Warn "$($e.file): $ref has $cnt token(s) but $($spots.Count) placement(s)"
        }
      }
      [void]$foes.Add(@{ count = $cnt; npc = $npc; spots = $spots })
    }
    if ($foes.Count -eq 0) { Warn "$($e.file): no foes resolved"; continue }
    # Placements are in the plate's pixels, so the plate has to be measured.
    $mapDim = $null
    if ($e.meta.map) {
      $mapRec = $maps | Where-Object { $_.id -eq [string]$e.meta.map } | Select-Object -First 1
      if (-not $mapRec) {
        if ($foes | Where-Object { $_.spots.Count }) { Warn "$($e.file): map '$($e.meta.map)' not found $em placements skipped" }
      }
      else {
        $mapPlate = Join-Path (Join-Path $src 'art') ([string]$mapRec.meta.image)
        if (Test-Path $mapPlate) { $mapDim = Get-ImageSize $mapPlate }
      }
    }
    elseif ($foes | Where-Object { $_.spots.Count }) {
      Warn "$($e.file): placements given but no map: marker"
    }
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
        $tk = [string]$f.npc.meta.token
        if ($tk -notmatch '@') { $tk = "$tk@$modName" }
        [void]$sec.Add((T 'token' $tk 5))
      }
      # Where the tokens stand. FG hangs this off the foe as <maplink>, one entry per
      # token, pointing at image.<map>.image - note the second ".image", which is the
      # layer inside the record and not a typo. Coordinates use the same convention as
      # occluders: origin at the plate's centre, y pointing UP.
      if ($f.spots.Count -gt 0 -and $mapDim) {
        [void]$sec.Add("`t`t`t`t`t<maplink>")
        $si = 0
        foreach ($sp in $f.spots) {
          $si++
          $sslot = 'id-{0:D5}' -f $si
          $inv = [Globalization.CultureInfo]::InvariantCulture
          # NOTE THE SIGN, AND THAT IT IS NOT THE OCCLUDER CONVENTION.
          # Occluders measure y UP from the image centre. A maplink measures y DOWN.
          # They disagree, in the same file, on the same map. Emitting the occluder
          # convention here mirrors every token about the horizontal centre line, which
          # puts the family upstairs into the shop and one child outside the building.
          $sx = ($sp[0] - $mapDim.w / 2.0).ToString($inv)
          $sy = ($sp[1] - $mapDim.h / 2.0).ToString($inv)
          [void]$sec.Add("`t`t`t`t`t`t<$sslot>")
          [void]$sec.Add("`t`t`t`t`t`t`t<imageref type=""windowreference"">")
          [void]$sec.Add("`t`t`t`t`t`t`t`t<class>imagewindow</class>")
          [void]$sec.Add("`t`t`t`t`t`t`t`t<recordname>image.$($e.meta.map).image@$(Esc $modName)</recordname>")
          [void]$sec.Add("`t`t`t`t`t`t`t</imageref>")
          [void]$sec.Add("`t`t`t`t`t`t`t<imagex type=""number"">$sx</imagex>")
          [void]$sec.Add("`t`t`t`t`t`t`t<imagey type=""number"">$sy</imagey>")
          [void]$sec.Add("`t`t`t`t`t`t</$sslot>")
        }
        [void]$sec.Add("`t`t`t`t`t</maplink>")
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

      # Copy the real SRD record's fields, then let the markdown override any of them.
      # `srd:` names the record to look up when the item is called something else in the
      # fiction; `srd: none` opts a genuinely invented item out of the lookup.
      $srdName = if ($imeta.srd) { [string]$imeta.srd } else { $iname }
      $srdRec = $null
      if ($srdName -ne 'none') {
        $key = ($srdName -replace '[^a-zA-Z0-9]', '').ToLower()
        $idx = Get-ItemIndex
        if ($idx.ContainsKey($key)) { $srdRec = $idx[$key] }
        elseif ($imeta.srd) { Warn "$($p.file): no SRD item called '$srdName' for $em $iname" }
      }
      foreach ($f in $itemStrFields) {
        $v = if ($imeta.$f) { [string]$imeta.$f } elseif ($srdRec) { $srdRec.SelectSingleNode($f).InnerText } else { $null }
        if ($v) { [void]$sec.Add((S $f $v 5)) }
      }
      foreach ($f in $itemNumFields) {
        $v = $null
        if ($imeta.$f) { $v = [double]$imeta.$f }
        elseif ($srdRec -and $srdRec.SelectSingleNode($f)) { $v = [double]$srdRec.SelectSingleNode($f).InnerText }
        if ($null -ne $v) { [void]$sec.Add((N $f $v 5)) }
      }

      # The failure this whole lookup exists to prevent: a weapon that rolls nothing and
      # armour that grants no AC when a player equips it.
      $itype = if ($imeta.type) { [string]$imeta.type } elseif ($srdRec -and $srdRec.SelectSingleNode('type')) { $srdRec.SelectSingleNode('type').InnerText } else { '' }
      if ($itype -eq 'Weapon' -and -not ($imeta.damage -or ($srdRec -and $srdRec.SelectSingleNode('damage')))) {
        Warn "$($p.file): '$iname' is a Weapon with no damage $em it will roll nothing in FG"
      }
      if ($itype -eq 'Armor' -and -not ($imeta.ac -or ($srdRec -and $srdRec.SelectSingleNode('ac')))) {
        Warn "$($p.file): '$iname' is Armor with no ac $em equipping it will do nothing"
      }
      [void]$sec.Add((S 'name' $iname 5))
      if ($imeta.nonid) {
        [void]$sec.Add((N 'isidentified' 0 5))
        [void]$sec.Add((S 'nonid_name' ([string]$imeta.nonid) 5))
      }
      else { [void]$sec.Add((N 'isidentified' 1 5)) }
      # An item's <description> is PLAYER-FACING. Anything lootable gets looted and read,
      # so a note addressed to the GM printed here is a note the table reads out. Those
      # belong in a story record. Catch the giveaway second-person-about-the-table voice.
      $ibodyText = Get-Body $ibody
      foreach ($phrase in @('the party', 'the players', 'the GM', 'show this', 'read out',
                            'read this', 'if they kill', 'put it in their hands')) {
        if ($ibodyText -match [regex]::Escape($phrase)) {
          Warn "$($p.file): '$iname' description says '$phrase' $em item descriptions are player-facing; move GM notes to fg/story/"
          break
        }
      }
      [void]$sec.Add("`t`t`t`t`t<description type=""formattedtext"">")
      [void]$sec.Add((ConvertTo-FormattedText $ibodyText 6))
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

# ---------------------------------------------------------- <specialability>

if ($abilities.Count) {
  $sec = New-Object System.Collections.ArrayList
  foreach ($ab in $abilities) {
    [void]$sec.Add("`t`t<$($ab.id)>")
    [void]$sec.Add((S 'name' $ab.title 3))
    if ($ab.meta.abilitytype) { [void]$sec.Add((S 'type' ([string]$ab.meta.abilitytype) 3)) }
    [void]$sec.Add("`t`t`t<text type=""formattedtext"">")
    [void]$sec.Add((ConvertTo-FormattedText $ab.body 4))
    [void]$sec.Add("`t`t`t</text>")
    [void]$sec.Add("`t`t</$($ab.id)>")
  }
  [void]$xml.Add("`t<reference>")
  [void]$xml.Add("`t`t<specialabilities>")
  foreach ($l in $sec) { foreach ($sub in ($l -split "`n")) { [void]$xml.Add("`t$sub") } }
  [void]$xml.Add("`t`t</specialabilities>")
  [void]$xml.Add("`t</reference>")
}

# ---------------------------------------------------------------- <image>

$mapsIncluded = 0
if ($maps.Count) {
  $rows = New-Object System.Collections.ArrayList
  # FG lists every <image> record in one window, so a portrait and a battlemap land in the
  # same list together. Categories are what separate them there: maps stay in "Maps" and a
  # portrait record declares `category: Portraits`. Sorted so each category emits as one block.
  $curCat = ''
  $maps = @($maps | Sort-Object @{ e = { if ($_.meta.category) { [string]$_.meta.category } else { 'Maps' } } }, title)
  foreach ($mp in $maps) {
    $rel = [string]$mp.meta.image
    if (-not $rel) { Warn "$($mp.file): no image marker $em map skipped"; continue }
    $plate = Join-Path (Join-Path $src 'art') $rel
    if ($rel -match '@') { $plate = $null }
    if ($plate -and -not (Test-Path $plate)) {
      Warn "$($mp.file): art missing at fg/art/$rel $em map skipped"
      continue
    }
    $dim = if ($plate) { Get-ImageSize $plate } else { $null }
    if (-not $dim) { Warn "$($mp.file): could not read the size of fg/art/$rel $em occluders left untranslated" }
    $mapsIncluded++
    $cat = if ($mp.meta.category) { [string]$mp.meta.category } else { 'Maps' }
    if ($cat -ne $curCat) {
      if ($curCat) { [void]$rows.Add("`t`t</category>") }
    [void]$rows.Add("`t`t<category name=""$(Esc $cat)"" mergeid="""">")
      $curCat = $cat
    }
    [void]$rows.Add("`t`t<$($mp.id)>")
    [void]$rows.Add("`t`t`t<image type=""image"">")
    [void]$rows.Add("`t`t`t`t<grid>$(if ($mp.meta.grid) { $mp.meta.grid } else { 'on' })</grid>")
    if ($mp.meta.gridtype) { [void]$rows.Add("`t`t`t`t<gridtype>$($mp.meta.gridtype)</gridtype>") }
    # FG stores gridsize as a PAIR, "100,100" - a bare "100" is not the same thing.
    # Written as one number in markdown, since these grids are always square.
    if ($mp.meta.gridsize) {
      $gs = [string]$mp.meta.gridsize
      if ($gs -notmatch ',') { $gs = "$gs,$gs" }
      [void]$rows.Add("`t`t`t`t<gridsize>$gs</gridsize>")
    }
    # Shifts the grid so its lines fall on the art. Only needed for a generated plate,
    # where the walls do not start at a round multiple of the square size.
    if ($mp.meta.gridoffset) { [void]$rows.Add("`t`t`t`t<gridoffset>$([string]$mp.meta.gridoffset)</gridoffset>") }
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
    # Three kinds of line-of-sight wall. FG keeps movement and vision on separate flags,
    # so "passable" and "see-through" are independent: occluder-open is terrain you can walk
    # through but not see through (a thicket, a smoke bank), NOT an open edge. Terrain that
    # blocks neither needs no occluder at all.
    if ($mp.meta.occluder) { foreach ($o in @($mp.meta.occluder)) { [void]$occ.Add(@{ pts = $o; kind = 'wall' }) } }
    if ($mp.meta.'occluder-open') { foreach ($o in @($mp.meta.'occluder-open')) { [void]$occ.Add(@{ pts = $o; kind = 'open' }) } }
    if ($mp.meta.'occluder-door') { foreach ($o in @($mp.meta.'occluder-door')) { [void]$occ.Add(@{ pts = $o; kind = 'door' }) } }
    if ($occ.Count) {
      [void]$rows.Add("`t`t`t`t`t`t<occluders>")
      $oi = 0
      foreach ($o in $occ) {
        $oi++
        # Authored in top-left image pixels. FG stores occluders relative to the image
        # CENTRE and with y pointing UP, so x shifts by half the width but y is
        # SUBTRACTED from half the height. Getting the origin right and the direction
        # wrong is the nastier failure of the two: the layer mirrors about the middle of
        # the plate, so it still looks like a floor plan and every wall is on the wrong
        # side of the room.
        $ox = 0.0; $oy = 0.0
        if ($dim) { $ox = $dim.w / 2.0; $oy = $dim.h / 2.0 }
        $xy = New-Object System.Collections.ArrayList
        foreach ($pair in (($o.pts -split '\s+') | Where-Object { $_ })) {
          $c = $pair -split ','
          if ($c.Count -ne 2) { Warn "$($mp.file): occluder point '$pair' is not x,y $em skipped"; continue }
          [void]$xy.Add((([double]$c[0] - $ox)).ToString([Globalization.CultureInfo]::InvariantCulture))
          [void]$xy.Add((($oy - [double]$c[1])).ToString([Globalization.CultureInfo]::InvariantCulture))
        }
        # FG writes its own doors as a thin quad rather than a bare segment, so a
        # two-point door is widened into one here. A door authored as a plain polyline
        # may well work, but matching the shape the client itself emits costs nothing
        # and removes the question.
        if ($o.kind -eq 'door' -and $xy.Count -eq 4) {
          $x1 = [double]$xy[0]; $y1 = [double]$xy[1]
          $x2 = [double]$xy[2]; $y2 = [double]$xy[3]
          $dx = $x2 - $x1; $dy = $y2 - $y1
          $len = [Math]::Sqrt($dx * $dx + $dy * $dy)
          if ($len -gt 0) {
            $nx = -$dy / $len * 2.5; $ny = $dx / $len * 2.5
            $inv = [Globalization.CultureInfo]::InvariantCulture
            # Each element is parenthesised: PowerShell's comma binds tighter than +,
            # so `$x1 + $nx, $y1` would add an array to a double and throw.
            $quad = @(($x1 + $nx), ($y1 + $ny), ($x2 + $nx), ($y2 + $ny),
                      ($x2 - $nx), ($y2 - $ny), ($x1 - $nx), ($y1 - $ny))
            $xy = New-Object System.Collections.ArrayList
            foreach ($v in $quad) { [void]$xy.Add(([double]$v).ToString($inv)) }
          }
        }
        $pts = $xy -join ','
        [void]$rows.Add("`t`t`t`t`t`t`t<occluder>")
        [void]$rows.Add("`t`t`t`t`t`t`t`t<id>$oi</id>")
        [void]$rows.Add("`t`t`t`t`t`t`t`t<points>$pts</points>")
        if ($o.kind -eq 'open') {
          [void]$rows.Add("`t`t`t`t`t`t`t`t<terrain />")
          [void]$rows.Add("`t`t`t`t`t`t`t`t<allow_move />")
        }
        elseif ($o.kind -eq 'door') {
          # A door ships closed, and FG gives it a click target to open. Without
          # <closed /> it loads standing open, which quietly removes the wall.
          [void]$rows.Add("`t`t`t`t`t`t`t`t<toggleable />")
          [void]$rows.Add("`t`t`t`t`t`t`t`t<closed />")
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
    if ($curCat) { [void]$rows.Add("`t`t</category>") }
    Add-Section 'image' 'Maps & Portraits' $rows
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
  abilities = @('Special Abilities', 'specialability')
  maps      = @('Maps & Portraits', 'image')
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
  "<root version=""4.5"" dataversion=""$dataVersion"" release=""1.1|PFRPG:18|CoreRPG:7"">"
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
  # Only ship actual assets. fg/art/ also holds the scripts that draw the plates, and
  # those have no business inside the module.
  $assetExt = @('.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.svg', '.ttf', '.otf')
  foreach ($f in (Get-ChildItem $artSrc -Recurse -File)) {
    if ($assetExt -notcontains $f.Extension.ToLower()) { continue }
    # trace-occluders.py drops <plate>-mask.png beside the plate it traced. That is a
    # working file for judging a threshold by eye, not art, and has no business shipping.
    if ($f.Name -like '*-mask.png') { continue }
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
Write-Host ("  abilities {0}" -f $abilities.Count)
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

  # Report every campaign holding a cached copy, and say whether FG will refresh it.
  # The cache is not purely derived: FG also keeps campaign-side additions there, such
  # as where tokens were dropped on a map, so it is never deleted without being asked.
  $fgRunning = @(Get-Process -Name 'FantasyGrounds', 'FantasyGroundsUnity' -ErrorAction SilentlyContinue).Count -gt 0
  $campRoot = Join-Path (Split-Path $dest -Parent) 'campaigns'
  if (Test-Path $campRoot) {
    foreach ($camp in (Get-ChildItem $campRoot -Directory -ErrorAction SilentlyContinue)) {
      $cache = Join-Path (Join-Path $camp.FullName 'moduledb') "$modName.xml"
      if (-not (Test-Path $cache)) { continue }
      $cv = ''
      try { $cv = ([xml][IO.File]::ReadAllText($cache)).root.dataversion } catch { }
      if ($ResetModuleCache) {
        if ($fgRunning) {
          Warn "Fantasy Grounds is running $em not touching $($camp.Name); it would be rewritten on exit. Close FG and rerun."
        }
        else {
          Remove-Item $cache -Force
          Write-Host "  cleared cached copy in campaign '$($camp.Name)' (token placements on maps are lost)" -ForegroundColor Yellow
        }
      }
      elseif ($cv -and $cv -ge $dataVersion) {
        Warn ("campaign '{0}' has a cached copy stamped {1} and the module is {2} $em FG will NOT refresh it. Close FG and rerun with -ResetModuleCache." -f $camp.Name, $cv, $dataVersion)
      }
      else {
        Write-Host "  campaign '$($camp.Name)' cached at $cv $em FG will re-import at $dataVersion" -ForegroundColor DarkGray
      }
    }
  }
  Write-Host "Close and reopen the module in FG $em it does not hot-reload."
}
