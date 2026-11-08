"""Run the Spellbook extension's real Lua against a mock of Fantasy Grounds' DB.

    python fg-ext/spellbook/test/test_spellbook.py [path/to/PF-SRD-Spells/client.xml]

Needs: pip install lupa. The mock covers the DB tree with campaign and module roots
(DB.getChildrenGlobal, "path@Module" records), and a stand-in for the ruleset's
SpellManager.addSpell that copies the record and parses one action, as the real one does.

With a client.xml from an unpacked spell module, it also builds a cleric book from it.
"""
import os, sys
import xml.etree.ElementTree as ET
import lupa

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "scripts", "manager_spellbook.lua")

MOCK = r'''
local roots = { [""] = { name = "", children = {}, order = {}, parent = nil, module = "" } }
local log = {}
_G.LOG = log

local function root(m)
  m = m or ""
  if not roots[m] then roots[m] = { name = "", children = {}, order = {}, parent = nil, module = m } end
  return roots[m]
end
local function top(n) while n.parent do n = n.parent end; return n end
local function path(n)
  local t = {}
  local m = top(n).module
  while n and n.parent do table.insert(t, 1, n.name); n = n.parent end
  local s = table.concat(t, ".")
  if m ~= "" then s = s .. "@" .. m end
  return s
end
local function child(n, name, create)
  if not n.children[name] and create then
    n.children[name] = { name = name, children = {}, order = {}, parent = n }
    table.insert(n.order, name)
  end
  return n.children[name]
end
local function walk(n, p, create)
  if not p or p == "" then return n end
  local up = p:match("^(%.+)")
  if up then
    for i = 1, #up - 1 do n = n and n.parent end
    p = p:sub(#up + 1)
    if p == "" then return n end
  end
  for part in p:gmatch("[^%.]+") do
    if not n then return nil end
    n = child(n, part, create)
  end
  return n
end
local nextId = 0
DB = {}
function DB.findNode(p)
  local sPath, sMod = p:match("^(.-)@(.*)$")
  if not sPath then sPath, sMod = p, "" end
  if sPath == "" then return nil end
  return walk(root(sMod), sPath, false)
end
function DB.getChild(n, p) if type(n) == "string" then n = DB.findNode(n) end; return walk(n, p, false) end
function DB.createChild(n, p)
  if type(n) == "string" then
    local sPath, sMod = n:match("^(.-)@(.*)$")
    if not sPath then sPath, sMod = n, "" end
    n = walk(root(sMod), sPath, true)
    if not p then return n end
  end
  if not p then nextId = nextId + 1; p = string.format("id-%05d", nextId) end
  return walk(n, p, true)
end
function DB.getValue(n, p, d)
  if type(n) == "string" then n = DB.findNode(n) end
  if not n then return d end
  local c = (p and walk(n, p, false)) or (not p and n)
  if c and c.value ~= nil then return c.value end
  return d
end
_G.SHEET_OPEN = false
_G.HOT = 0      -- writes under a spellset while the sheet is open (each one refreshes every action)
local function cost(n) if _G.SHEET_OPEN and path(n):find("%.spellset%.") then _G.HOT = _G.HOT + 1 end end
function DB.setValue(n, p, t, v, v2)
  local c = walk(n, p, true)
  cost(c)
  if t == "windowreference" then c.value = v; c.record = v2 else c.value = v end
end
function DB.getChildList(n, p)
  if type(n) == "string" then n = DB.findNode(n) end
  local c = n
  if p then c = n and walk(n, p, false) end
  local t = {}
  if c then for _, k in ipairs(c.order) do if c.children[k] then table.insert(t, c.children[k]) end end end
  return t
end
function DB.getChildrenGlobal(p)
  local t = {}
  local names = {}
  for m in pairs(roots) do table.insert(names, m) end
  table.sort(names)  -- campaign ("") first, then modules by name
  for _, m in ipairs(names) do
    for _, v in ipairs(DB.getChildList(walk(roots[m], p, false))) do table.insert(t, v) end
  end
  return t
end
function DB.getModule(n) return top(n).module end
function DB.getParent(n) return n.parent end
function DB.getName(n) return n.name end
function DB.getPath(n, sub) local s = path(n); if sub then s = s .. "." .. sub end; return s end
function DB.deleteNode(n) cost(n); n.parent.children[n.name] = nil end
function DB.createChildAndCopy(dest, src)
  local function cp(s, d) d.value = s.value; for _, k in ipairs(s.order) do if s.children[k] then cp(s.children[k], child(d, k, true)) end end end
  local n = DB.createChild(dest); cp(src, n); cost(n); return n
end

ChatManager = { SystemMessage = function(s) table.insert(log, s) end }
Interface = {}
function Interface.openWindow(c, p)
  if c == "charsheet" then _G.SHEET_OPEN = true; _G.REOPENED = (_G.REOPENED or 0) + 1 end
  return { class = c, path = p }
end
function Interface.findWindow(c, p)
  if c == "charsheet" and _G.SHEET_OPEN then return { close = function() _G.SHEET_OPEN = false end } end
end
SpellManager = {}
function SpellManager.addSpell(src, cls, lvl)
  local spells = DB.getChild(cls, "levels.level" .. lvl .. ".spells")
  if not spells then return nil end
  local n = DB.createChildAndCopy(spells, src)
  local a = DB.createChild(DB.createChild(n, "actions"))
  DB.setValue(a, "type", "string", "cast")
  return n
end
function SpellManager.updateSpellClassCounts(cls) _G.COUNTS = (_G.COUNTS or 0) + 1 end

-- helpers for the test
function addSpellRecord(sModule, sName, sLevel)
  local base = root(sModule)
  local n = DB.createChild(walk(base, "spelldesc", true))
  DB.setValue(n, "name", "string", sName)
  DB.setValue(n, "level", "string", sLevel)
  DB.setValue(n, "school", "string", "x")
  return n
end
function sheetNames(cls, lvl)
  local t = {}
  for _, v in ipairs(DB.getChildList(cls, "levels.level" .. lvl .. ".spells")) do
    table.insert(t, DB.getValue(v, "name", "") .. "=" .. DB.getValue(v, "prepared", 0) .. (DB.getValue(v, "mc_book", 0) == 1 and "*" or ""))
  end
  table.sort(t)
  return table.concat(t, ",")
end
function entry(book, sName)
  for _, v in ipairs(DB.getChildList(book, "entries")) do
    if DB.getValue(v, "name", "") == sName then return v end
  end
end
function entryCount(book) return #DB.getChildList(book, "entries") end
function newRoot() for k in pairs(roots) do roots[k] = nil end; root("") end
'''

FAILS = []
def check(label, got, want):
    ok = got == want
    print(("  ok   " if ok else "  FAIL ") + label + ("" if ok else f"\n         got  {got!r}\n         want {want!r}"))
    if not ok:
        FAILS.append(label)

def runtime():
    L = lupa.LuaRuntime(unpack_returned_tuples=True)
    L.execute(MOCK)
    src = open(SRC, encoding="utf-8").read()
    # FG loads a <script name="SpellbookMC"> file as a global table of its functions.
    L.execute("SpellbookMC = setmetatable({}, {__index = _G})\nlocal f = load([==[" + src + "]==], 'manager', 't', SpellbookMC)\nf()")
    return L

def lua_table(t):
    return {k: v for k, v in t.items()}

def test_parsing(L):
    print("level lines and names")
    SB = L.globals().SpellbookMC
    p = lambda s: lua_table(SB.parseLevels(s))
    check("Paizo full names", p("Adept 1, Cleric 1, Oracle 1, Ranger 2"), {"adept": 1, "cleric": 1, "oracle": 1, "ranger": 2})
    check("SRD abbreviations and slash", p("Sor/Wiz 2, Clr 3"), {"sorcerer": 2, "wizard": 2, "cleric": 3})
    check("multi-word classes", p("Summoner UC 1, Red Mantis Assassin 1"), {"summoner uc": 1, "red mantis assassin": 1})
    check("3.5E domains", p("Clr 2, Good 2, Luck 2"), {"cleric": 2, "good": 2, "luck": 2})
    check("empty", p(""), {})
    check("lowest level", SB.lowestLevel("Sor/Wiz 3, Brd 2"), 2)
    check("comma name order", SB.nameKey("Cure Light Wounds, Mass"), SB.nameKey("Mass Cure Light Wounds"))
    check("case and punctuation", SB.nameKey("Bull's Strength"), SB.nameKey("bulls strength"))
    keys = L.table_from(["cleric", "oracle"])
    check("level for lists", SB.levelForKeys("Oracle 3, Cleric 4", keys), 3)
    check("no matching list", SB.levelForKeys("Wizard 1", keys), None)

def test_flow(L):
    print("open, tidy, prepare, rebuild")
    L.execute(r'''
      newRoot()
      PF = "PFRPG Spells"; ACG = "Pathfinder RPG - Advanced Class Guide"; OLD = "3.5E Spells"
      addSpellRecord(PF, "Bless", "Adept 1, Cleric 1, Paladin 1")
      addSpellRecord(PF, "Bane", "Cleric 1, Inquisitor 1")
      addSpellRecord(PF, "Aid", "Cleric 2, Inquisitor 2")
      addSpellRecord(PF, "Cure Light Wounds", "Bard 1, Cleric 1, Druid 1")
      addSpellRecord(PF, "Fireball", "Sorcerer 3, Wizard 3")
      addSpellRecord(ACG, "Bless", "Cleric 1, Warpriest 1")
      addSpellRecord(ACG, "Cure Light Wounds, Mass", "Cleric 5, Oracle 5")
      addSpellRecord(OLD, "Holy Smite", "Clr 4, Good 4")
      addSpellRecord(OLD, "Bless", "Clr 1, Good 1")
      AIDC = addSpellRecord("", "Aid", "Cleric 2")    -- the campaign's own copy

      CLS = DB.createChild("charsheet.id-00003.spellset.id-00002")
      DB.setValue(CLS, "label", "string", "Cleric")
      for i = 0, 9 do DB.createChild(CLS, "levels.level" .. i .. ".spells") end
      DB.setValue(CLS, "availablelevel1", "number", 3)
      DB.setValue(CLS, "availablelevel2", "number", 2)
      DB.setValue(CLS, "availablelevel5", "number", 1)
      local function sheet(lvl, name, prep)
        local n = DB.createChild(DB.getChild(CLS, "levels.level" .. lvl .. ".spells"))
        DB.setValue(n, "name", "string", name); DB.setValue(n, "prepared", "number", prep); return n
      end
      sheet(1, "Bless", 2); sheet(1, "Bane", 0); AIDS = sheet(2, "Aid", 0); sheet(1, "Custom Smite", 0)
      DB.setValue(DB.createChild(CLS, "mc_book.entries.id-00001"), "name", "string", "Old")  -- a v1.0.0 book
      SHEET_OPEN = true; HOT = 0
      W = SpellbookMC.open(CLS)
      HOT_OPEN = HOT
      BOOK = DB.findNode("charsheet.id-00003.mc_spellbook.id-00002")
    ''')
    G = L.globals()
    SB = G.SpellbookMC
    ev = L.eval
    check("window opened on the book", (G.W["class"], G.W.path), ("mc_spellbook", "charsheet.id-00003.mc_spellbook.id-00002"))
    check("book points back at its class", ev('SpellbookMC.getClassNode(BOOK) == CLS'), True)
    check("v1.0.0 book under the spell class removed", ev('DB.getChild(CLS, "mc_book")'), None)
    check("opening writes nothing under the spellset but the old book's removal", ev("HOT_OPEN"), 1)
    check("lists default from the class label", ev('DB.getValue(BOOK, "classkeys")'), "cleric")
    check("book has the cleric spells, not Fireball or the skipped 3.5E module", ev("entryCount(BOOK)"), 5)
    check("Holy Smite skipped (3.5E)", ev('entry(BOOK, "Holy Smite")'), None)
    check("campaign copy wins", ev('DB.getValue(entry(BOOK, "Aid"), "recordname")'), ev("DB.getPath(AIDC)"))
    check("source shown", ev('DB.getValue(entry(BOOK, "Aid"), "source")'), "Campaign")
    check("mass cure at 5", ev('DB.getValue(entry(BOOK, "Cure Light Wounds, Mass"), "level")'), 5)
    check("counts synced from the sheet", ev('DB.getValue(entry(BOOK, "Bless"), "prep")'), 2)
    check("slot summary", SB.slotSummary(G.BOOK), "1: 2/3   2: 0/2   5: 0/1")

    # Tidy: Aid is hand-edited, so Keep it first.
    L.execute('DB.setValue(entry(BOOK, "Aid"), "keep", "number", 1)')
    plan = SB.tidyPlan(G.BOOK)
    check("tidy would remove only Bane", sorted(L.eval("function(t) local r={} for _,v in ipairs(t) do table.insert(r, DB.getValue(v,'name')) end return table.concat(r,',') end")(plan).split(",")), ["Bane"])
    L.execute("SHEET_OPEN = true; HOT = 0")
    deleted, marked = SB.tidy(G.BOOK)
    check("tidy ran with the sheet closed", (ev("HOT"), ev("SHEET_OPEN")), (0, True))
    check("tidy counts", (deleted, marked), (1, 1))
    check("after tidy, level 1", ev("sheetNames(CLS, 1)"), "Bless=2*,Custom Smite=0")
    check("after tidy, kept Aid untouched", ev("sheetNames(CLS, 2)"), "Aid=0")

    # Today: no Bless, three Cure Light Wounds, one Mass Cure.
    L.execute(r'''
      DB.setValue(entry(BOOK, "Bless"), "prep", "number", 0)
      DB.setValue(entry(BOOK, "Cure Light Wounds"), "prep", "number", 3)
      DB.setValue(entry(BOOK, "Cure Light Wounds, Mass"), "prep", "number", 1)
      SHEET_OPEN = true; HOT = 0; REOPENED = 0
      R = SpellbookMC.prepare(BOOK)
    ''')
    check("prepare ran with the sheet closed, then reopened it", (ev("HOT"), ev("REOPENED"), ev("SHEET_OPEN")), (0, 1, True))
    check("prepare report", (G.R.added, G.R.removed, G.R.prepared, len(G.R.missing)), (2, 1, 4, 0))
    check("level 1 after prepare", ev("sheetNames(CLS, 1)"), "Cure Light Wounds=3*,Custom Smite=0")
    check("level 2: kept spell stays", ev("sheetNames(CLS, 2)"), "Aid=0")
    check("level 5 added", ev("sheetNames(CLS, 5)"), "Cure Light Wounds, Mass=1*")
    check("added spells got actions from addSpell", ev('#DB.getChildList(DB.getChildList(CLS, "levels.level1.spells")[2], "actions")'), 1)
    check("Aid keeps its hand edits (same node)", ev('DB.getChildList(CLS, "levels.level2.spells")[1] == AIDS'), True)

    L.execute("R2 = SpellbookMC.prepare(BOOK)")
    check("prepare twice changes nothing", (G.R2.added, G.R2.removed, ev("sheetNames(CLS, 1)")), (0, 0, "Cure Light Wounds=3*,Custom Smite=0"))

    # Keep on a spell not on the sheet puts it there at 0.
    L.execute('DB.setValue(entry(BOOK, "Bane"), "keep", "number", 1); R3 = SpellbookMC.prepare(BOOK)')
    check("kept spell added at 0", ev("sheetNames(CLS, 1)"), "Bane=0*,Cure Light Wounds=3*,Custom Smite=0")
    L.execute('DB.setValue(entry(BOOK, "Bane"), "keep", "number", 0); R3 = SpellbookMC.prepare(BOOK)')
    check("un-kept and unprepared is removed again", ev("sheetNames(CLS, 1)"), "Cure Light Wounds=3*,Custom Smite=0")

    # Sync after someone changes the sheet directly.
    L.execute('DB.setValue(DB.getChildList(CLS, "levels.level1.spells")[2], "prepared", "number", 1); SpellbookMC.syncFromSheet(BOOK)')
    check("sync reads the sheet's count", ev('DB.getValue(entry(BOOK, "Cure Light Wounds"), "prep")'), 1)

    # Rebuild with the 3.5E module allowed, then with lists changed.
    L.execute('DB.setValue(BOOK, "skipsources", "string", "")')
    a, r, total = SB.rebuild(G.BOOK)
    check("3.5E spells come in by abbreviation", (a, r, total), (1, 0, 6))
    check("Holy Smite at 4", ev('DB.getValue(entry(BOOK, "Holy Smite"), "level")'), 4)
    check("Bless still the campaign-or-first-module copy", ev('DB.getValue(entry(BOOK, "Bless"), "source")'), "3.5E Spells")
    L.execute('DB.setValue(BOOK, "skipsources", "string", "3.5E")')
    SB.rebuild(G.BOOK)
    check("skipping again moves Bless back to a Pathfinder module", ev('DB.getValue(entry(BOOK, "Bless"), "source")'), "PFRPG Spells")

    # A dropped spell of another list survives rebuilds.
    L.execute('FB = DB.getChildList(DB.findNode("spelldesc@PFRPG Spells"))[5]; SpellbookMC.addManual(BOOK, FB, nil)')
    check("dropped Fireball at its lowest level", ev('DB.getValue(entry(BOOK, "Fireball"), "level")'), 3)
    SB.rebuild(G.BOOK)
    check("manual entry survives rebuild", ev('entry(BOOK, "Fireball") ~= nil'), True)

    # A prepared spell whose module is gone.
    L.execute(r'''
      local n = entry(BOOK, "Fireball")
      DB.setValue(n, "recordname", "string", "spelldesc.id-99999@Gone")
      DB.setValue(n, "prep", "number", 1)
      R4 = SpellbookMC.prepare(BOOK)
    ''')
    check("missing record reported, nothing added", (G.R4.added, list(G.R4.missing.values())), (0, ["Fireball"]))
    check("over-slot warning", SB.slotSummary(G.BOOK).split("   ")[0], "1: 1/3")

    # A class with no matching list.
    L.execute(r'''
      LOG2 = #LOG
      C2 = DB.createChild("charsheet.id-00003.spellset.id-00009")
      DB.setValue(C2, "label", "string", "Mythic Power")
      SpellbookMC.open(C2)
    ''')
    check("no spells found message", "no spells found" in L.eval("LOG[#LOG]"), True)

def test_srd(L, path):
    print("real module: " + path)
    r = ET.parse(path).getroot()
    L.execute("newRoot()")
    add = L.globals().addSpellRecord
    n = 0
    for node in r.iter():
        lvl = node.find("level")
        if lvl is not None and node.find("school") is not None and node.findtext("name"):
            add("PFRPG Spells", node.findtext("name"), lvl.text or "")
            n += 1
    L.execute(r'''
      CLS = DB.createChild("charsheet.id-00001.spellset.id-00001")
      DB.setValue(CLS, "label", "string", "Cleric")
      for i = 0, 9 do DB.createChild(CLS, "levels.level" .. i .. ".spells") end
      SpellbookMC.open(CLS)
      BOOK = DB.findNode("charsheet.id-00001.mc_spellbook.id-00001")
    ''')
    total = L.eval("entryCount(BOOK)")
    print(f"  {n} spells in the module, {total} in a cleric book")
    check("cleric book is a real list", 150 < total < n, True)
    check("Cure Light Wounds at 1", L.eval('DB.getValue(entry(BOOK, "Cure Light Wounds"), "level")'), 1)

if __name__ == "__main__":
    L = runtime()
    test_parsing(L)
    test_flow(L)
    srd = sys.argv[1] if len(sys.argv) > 1 else None
    if srd and os.path.exists(srd):
        test_srd(L, srd)
    print("FAILED: " + ", ".join(FAILS) if FAILS else "all passed")
    sys.exit(1 if FAILS else 0)
