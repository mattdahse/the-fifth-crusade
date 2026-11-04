"""Run the Item Charges extension's real Lua against a mock of Fantasy Grounds' DB.

    python fg-ext/item-charges/test/test_charges.py      (needs: pip install lupa)

The mock reproduces the parts of FG the extension touches: the DB tree and its relative paths,
DB handlers, the inventory field callbacks, and the 3.5E ruleset's own long-rest reset
(SpellManager.resetSpells) and points spend (PowerManager35E.usePower), copied in behaviour.
"""
import lupa, os, sys
L = lupa.LuaRuntime(unpack_returned_tuples=True)

MOCK = r'''
local root = { name = "", children = {}, order = {}, parent = nil }
local handlers = {}
local invCallbacks = {}
local log = {}
_G.LOG = log

local function path(n)
  local t = {}
  while n and n.parent do table.insert(t, 1, n.name); n = n.parent end
  return table.concat(t, ".")
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
local function glob(pat, s)
  local lp = "^" .. pat:gsub("%.", "%%."):gsub("%*", "[^%%.]+") .. "$"
  return s:match(lp) ~= nil
end
local function fire(n, ev)
  local p = path(n)
  for _, h in ipairs(handlers) do
    if h.ev == ev and glob(h.pat, p) then h.fn(n) end
  end
  -- CharInventoryManager.onFieldUpdate: charsheet.*.inventorylist.*.*
  if ev == "onUpdate" and glob("charsheet.*.inventorylist.*.*", p) then
    for _, f in ipairs(invCallbacks[n.name] or {}) do f(n.parent, n.name) end
  end
end
local nextId = 0
DB = {}
function DB.findNode(p)
  p = p:gsub("@.*$", "")
  return walk(root, p, false)
end
function DB.getChild(n, p) if type(n) == "string" then n = DB.findNode(n) end; return walk(n, p, false) end
function DB.createChild(n, p)
  if type(n) == "string" then n = walk(root, n, true) end
  if n == nil then n = root end
  if not p then nextId = nextId + 1; p = string.format("id-%05d", nextId) end
  return walk(n, p, true)
end
function DB.getValue(n, p, d)
  if type(n) == "string" then n = DB.findNode(n) end
  local c = (p and walk(n, p, false)) or (not p and n)
  if c and c.value ~= nil then return c.value end
  return d
end
function DB.getText(n, p, d) return DB.getValue(n, p, d) end
function DB.setValue(n, p, t, v)
  local c = walk(n, p, true)
  local old = c.value
  c.value = v
  if old ~= v then fire(c, "onUpdate") end
end
function DB.getChildList(n, p)
  if type(n) == "string" then n = DB.findNode(n) end
  local c = p and walk(n, p, false) or n
  local t = {}
  if c then for _, k in ipairs(c.order) do if c.children[k] then table.insert(t, c.children[k]) end end end
  return t
end
function DB.getChildCount(n, p) return #DB.getChildList(n, p) end
function DB.getParent(n) return n.parent end
function DB.getName(n) return n.name end
function DB.getPath(n) return path(n) end
function DB.deleteNode(n)
  local par = n.parent
  par.children[n.name] = nil
  fire(par, "onChildDeleted")
end
function DB.addHandler(pat, ev, fn) table.insert(handlers, { pat = pat, ev = ev, fn = fn }) end
function DB.createChildAndCopy(dest, src)
  local function cp(s, d) d.value = s.value; for _, k in ipairs(s.order) do if s.children[k] then cp(s.children[k], child(d, k, true)) end end end
  local n = DB.createChild(dest); cp(src, n); return n
end

Session = { IsHost = true }
StringManager = { trim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end }
Module = { getModules = function() return {} end, getModuleInfo = function() return nil end }
ChatManager = { SystemMessage = function(s) table.insert(log, s) end }
ActorManager = { resolveActor = function(n) return n end, getCreatureNode = function(n) return n end, getDisplayName = function(n) return DB.getValue(n, "name", "?") end }
CharInventoryManager = { registerFieldUpdateCallback = function(f, fn) invCallbacks[f] = invCallbacks[f] or {}; table.insert(invCallbacks[f], fn) end }
SpellManager = {}
function SpellManager.addSpell(src, cls, lvl)
  local spells = DB.getChild(cls, "levels.level" .. lvl .. ".spells")
  local n = DB.createChildAndCopy(spells, src)
  local a = DB.createChild(DB.createChild(n, "actions"))
  DB.setValue(a, "type", "string", "cast")
  -- what the ruleset's parser makes: a save on the cast, heal or effect actions
  local nm = DB.getValue(n, "name", "")
  if nm:find("Cure") then
    DB.setValue(a, "savetype", "string", "will")
    local h = DB.createChild(DB.createChild(n, "actions")); DB.setValue(h, "type", "string", "heal")
  end
  if nm:find("Air Walk") or nm:find("Magic Weapon") then
    local e = DB.createChild(DB.createChild(n, "actions")); DB.setValue(e, "type", "string", "effect")
  end
  DB.setValue(n, "cost", "number", (lvl - 1) * 2 + 1)
  return n
end
-- the ruleset's real long-rest reset
function SpellManager.resetSpells(nodeCaster)
  for _, c in ipairs(DB.getChildList(nodeCaster, "spellset")) do
    DB.setValue(c, "pointsused", "number", 0)
    for _, l in ipairs(DB.getChildList(c, "levels")) do
      for _, s in ipairs(DB.getChildList(l, "spells")) do DB.setValue(s, "cast", "number", 0) end
    end
  end
end
-- the ruleset's real points spend (PowerManager35E.usePower), on a spell node
function usePower(nodeSpell)
  local cls = DB.getChild(nodeSpell, ".....")
  local pp, used, cost = DB.getValue(cls, "points", 0), DB.getValue(cls, "pointsused", 0), DB.getValue(nodeSpell, "cost", 0)
  if pp - used < cost then table.insert(log, "INSUFFICIENT"); return false end
  DB.setValue(cls, "pointsused", "number", used + cost); return true
end

-- The ruleset's record paths for spells, and FG's global child lookup (campaign + modules).
-- Module records are marked with .module; record keys are opaque ids, as in a real module,
-- so a spell can only be found by its name.
RecordDataManager = { getDataPaths = function(s) if s == "spell" then return { "spell", "reference.spells", "spelldesc" } end; return {} end }
function DB.getChildrenGlobal(p) return DB.getChildList(p) end
function DB.getModule(n) while n do if n.module then return n.module end; n = n.parent end; return "" end

-- spells "module" (Core Rules keeps its spells under reference.spells)
local spells = walk(root, "reference.spells", true)
spells.module = "Core Rules"
for _, v in ipairs({ { "Magic Missile", "Sor/Wiz 1" },
                     { "See Invisibility", "Brd 3, Sor/Wiz 2" },
                     { "Cure Light Wounds", "Brd 1, Clr 1, Drd 1, Pal 1, Rgr 2" },
                     { "Restoration, Lesser", "Clr 2, Drd 2, Pal 1" },
                     { "Air Walk", "Clr 4, Drd 4" },
                     { "Magic Weapon", "Clr 1, Pal 1, Sor/Wiz 1" },
                     { "Cure Serious Wounds", "Brd 3, Clr 3, Drd 4" } }) do
  local n = DB.createChild(spells)
  DB.setValue(n, "name", "string", v[1]); DB.setValue(n, "level", "string", v[2])
end
'''
L.execute(MOCK)
L.execute(open(os.path.join(os.path.dirname(__file__), '..', 'scripts', 'manager_item_charges.lua'), encoding='utf-8').read())
L.execute('onInit(); onTabletopInit()')

TEST = r'''
local fails = 0
local function check(cond, msg) if cond then print("  ok   " .. msg) else print("  FAIL " .. msg); fails = fails + 1 end end
local char = DB.createChild(DB.createChild(nil, "charsheet"), "id-00001")
DB.setValue(char, "name", "string", "Riven")
local inv = DB.createChild(char, "inventorylist")
local function item(name, typ, extra)
  local n = DB.createChild(inv)
  DB.setValue(n, "name", "string", name); DB.setValue(n, "type", "string", typ)
  for k, v in pairs(extra or {}) do DB.setValue(n, k, "number", v) end
  return n
end
local function class(n)
  for _, c in ipairs(DB.getChildList(char, "spellset")) do if DB.getValue(c, "mc_item") == DB.getPath(n) then return c end end
end
local function spellOf(c)
  for _, l in ipairs(DB.getChildList(c, "levels")) do for _, s in ipairs(DB.getChildList(l, "spells")) do return s end end
end

print("wand: charges from the description, equip, cast, rest")
local wand = item("Wand of Magic Missile", "Wand", { carried = 1 })
DB.setValue(wand, "description", "string", "A slim rod of black bog oak. 7 charges. One missile per charge.")
check(class(wand) == nil, "carried but not equipped: no class")
DB.setValue(wand, "carried", "number", 2)
local c = class(wand)
check(c ~= nil, "equipped: class created")
check(DB.getValue(wand, "charges") == 7, "charges read from the description and written to the item")
check(DB.getValue(c, "points") == 7 and DB.getValue(c, "pointsused") == 0, "class shows 7 points, 0 used")
local s = spellOf(c)
check(DB.getValue(s, "name") == "Magic Missile" and DB.getValue(s, "cost") == 1, "spell is Magic Missile, cost 1")
usePower(s); usePower(s)
check(DB.getValue(wand, "charges") == 5, "two casts: item down to 5")
check(DB.getValue(c, "points") == 5 and DB.getValue(c, "pointsused") == 0, "class shows 5 points, 0 used")
SpellManager.resetSpells(char)
check(DB.getValue(wand, "charges") == 5 and DB.getValue(c, "points") == 5, "LONG REST: still 5, no recharge")
DB.setValue(c, "points", "number", 50)
check(DB.getValue(c, "points") == 5, "typing 50 into the class's points is overruled by the item")
DB.setValue(wand, "carried", "number", 1)
check(class(wand) == nil and DB.getValue(wand, "charges") == 5, "unequip: class removed, item keeps 5")
SpellManager.resetSpells(char)
DB.setValue(wand, "carried", "number", 2)
c = class(wand)
check(DB.getValue(c, "points") == 5, "rest while unequipped, re-equip: still 5")
for i = 1, 5 do usePower(spellOf(c)) end
check(DB.getValue(wand, "charges") == 0, "used up: item at 0")
check(usePower(spellOf(c)) == false, "a sixth cast is refused for insufficient points")

print("potions: count is the charge")
local pot = item("Potion of Cure Light Wounds", "Potion", { carried = 2, count = 3 })
local pc = class(pot)
check(pc ~= nil and DB.getValue(pc, "points") == 3, "3 potions equipped: 3 points")
usePower(spellOf(pc))
check(DB.getValue(pot, "count") == 2, "drink one: count 2")
DB.setValue(pot, "count", "number", 4)
check(DB.getValue(pc, "points") == 4, "buy two more: class follows to 4")
SpellManager.resetSpells(char)
check(DB.getValue(pot, "count") == 4, "rest: still 4 potions")

print("scroll: level, caster level and fixed item DC")
local scr = item("Scroll of See Invisibility", "Scroll", { carried = 2, count = 1, cl = 3 })
local sc = class(scr)
local ss = spellOf(sc)
check(DB.getName(DB.getParent(DB.getParent(ss))) == "level2", "filed at level 2 (lowest of Brd 3, Sor/Wiz 2)")
check(DB.getValue(sc, "cl") == 3, "caster level 3 from the item")
local a = DB.getChildList(ss, "actions")[1]
check(DB.getValue(a, "savedctype") == "fixed" and DB.getValue(a, "savedcmod") == 13, "save DC fixed at 13 (10 + 2 + 1)")

print("Pathfinder's 'Restoration, Lesser' naming")
local lr = item("Potion of Lesser Restoration", "Potion", { carried = 2, count = 1 })
check(class(lr) ~= nil and DB.getValue(spellOf(class(lr)), "name") == "Restoration, Lesser", "found as 'Restoration, Lesser', at level 1")
DB.deleteNode(lr)

print("names from the crusade campaign")
local csw = item("Wand of Cure Serious Wounds (CL 5) - 44", "Wand", { carried = 2 })
check(DB.getValue(csw, "charges") == 44 and DB.getValue(class(csw), "points") == 44, "' - 44' read as 44 charges")
check(DB.getValue(spellOf(class(csw)), "name") == "Cure Serious Wounds" and DB.getValue(class(csw), "cl") == 5, "spell found despite '(CL 5) - 44'; CL 5")
local clw = item("Wand of Cure Light Wounds (48 charges)", "Wand", { carried = 2 })
check(DB.getValue(class(clw), "points") == 48, "'(48 charges)' read as 48")
usePower(spellOf(class(clw)))
DB.setValue(clw, "carried", "number", 1); DB.setValue(clw, "carried", "number", 2)
check(DB.getValue(class(clw), "points") == 47, "name still says 48, but the field (47) wins: no recharge from the name")
DB.deleteNode(csw); DB.deleteNode(clw)

print("leftovers from Advanced Item Actions are cleared")
local old = item("Wand of Cure Light Wounds", "Wand", { carried = 1 })
local stale = DB.createChild(DB.createChild(char, "spellset"))
DB.setValue(stale, "label", "string", "Wand of Cure Light Wounds"); DB.setValue(stale, "source_name", "string", DB.getPath(old))
DB.setValue(stale, "castertype", "string", "points")
onTabletopInit()
local left = 0
for _, c in ipairs(DB.getChildList(char, "spellset")) do if DB.getValue(c, "source_name") then left = left + 1 end end
check(left == 0, "the old extension's class is gone")
DB.deleteNode(old)

print("deleting the item removes its class")
DB.deleteNode(scr)
check(class(scr) == nil and #DB.getChildList(char, "spellset") == 2, "scroll's class gone, wand and potion remain")

print("no charges anywhere: warns, does not invent 50")
local bare = item("Wand of Magic Missile", "Wand", { carried = 2 })
check(DB.getValue(class(bare), "points") == 0, "class at 0 points")
check(LOG[#LOG]:find("no charges set") ~= nil, "GM warned: " .. LOG[#LOG])

print("the Charges box: an empty 0 from opening the window does not hide the name's count")
local w50 = item("Wand of Magic Missile [50 charges]", "Wand", { carried = 1, charges = 0 })
DB.setValue(w50, "carried", "number", 2)
check(DB.getValue(class(w50), "points") == 50 and DB.getValue(w50, "charges") == 50, "field at 0 without a mark: 50 read from the name")
for i = 1, 50 do usePower(spellOf(class(w50))) end
DB.setValue(w50, "carried", "number", 1); DB.setValue(w50, "carried", "number", 2)
check(DB.getValue(w50, "charges") == 0 and DB.getValue(class(w50), "points") == 0, "spent to 0 and re-equipped: stays 0, not refilled from the name")
local typed = item("Wand of Magic Missile", "Wand", { carried = 2 })
DB.setValue(typed, "charges", "number", 12)
check(DB.getValue(class(typed), "points") == 12 and DB.getValue(typed, "mc_charges_set") == 1, "typing 12 into the Charges box: class shows 12, marked as set")
check(ItemChargesMC == nil and usesChargesField(typed) == true and usesChargesField(pot) == false, "Charges box shown for wands, not potions")

print("potions act on the drinker")
local function action(cls, typ)
  for _, a in ipairs(DB.getChildList(spellOf(cls), "actions")) do if DB.getValue(a, "type") == typ then return a end end
end
local clw = item("Potion of Cure Light Wounds", "Potion", { carried = 2, count = 2 })
local clwc = class(clw)
check(DB.getValue(action(clwc, "heal"), "healtargeting") == "self", "healing targets self")
check(DB.getValue(action(clwc, "cast"), "savetype") == "" and DB.getValue(action(clwc, "cast"), "srnotallowed") == 1, "no save or SR against a target")
local pwalk = item("Potion of Air Walk", "Potion", { carried = 2, count = 1 })
check(DB.getValue(action(class(pwalk), "effect"), "targeting") == "self", "effect targets self")
local oil = item("Oil of Magic Weapon", "Potion", { carried = 2, count = 1 })
check(DB.getValue(action(class(oil), "effect"), "targeting") == nil, "an oil keeps normal targeting")
local wclw = item("Wand of Cure Light Wounds", "Wand", { carried = 2, charges = 5 })
check(DB.getValue(action(class(wclw), "heal"), "healtargeting") == nil, "a wand keeps normal targeting")

print("drinking the last potion removes it from inventory")
usePower(spellOf(clwc))
check(DB.getValue(clw, "count") == 1 and class(clw) ~= nil, "one of two drunk: count 1, still in inventory")
local nodeCls = clwc
usePower(spellOf(clwc))
local gone = true
for _, v in ipairs(DB.getChildList(inv)) do if v == clw then gone = false end end
check(gone, "last one drunk: item deleted from inventory")
check(DB.getValue(nodeCls, "mc_spent") == 1 and DB.getValue(nodeCls, "points") == 0, "its Actions entry stays, empty, so the healing can still be rolled")
check(DB.getValue(nodeCls, "label"):find("used up") ~= nil, "labelled used up")
check(LOG[#LOG]:find("removed from inventory") ~= nil, "chat says so")
DB.deleteNode(oil)
local still = false
for _, c in ipairs(DB.getChildList(char, "spellset")) do if c == nodeCls then still = true end end
check(still, "another inventory change does not clear it early")
onTurnStart(char)
still = false
for _, c in ipairs(DB.getChildList(char, "spellset")) do if c == nodeCls then still = true end end
check(not still, "cleared at the drinker's next turn")
usePower(spellOf(class(pwalk)))
local walkCls
for _, c in ipairs(DB.getChildList(char, "spellset")) do if DB.getValue(c, "mc_spent") == 1 then walkCls = c end end
check(walkCls ~= nil, "Potion of Air Walk drunk: empty entry kept")
SpellManager.resetSpells(char)
check(DB.getValue(walkCls, "mc_spent") == nil or #DB.getChildList(char, "spellset") == 0 or (function() for _, c in ipairs(DB.getChildList(char, "spellset")) do if c == walkCls then return false end end return true end)(), "cleared by a long rest")
check(DB.getValue(wclw, "charges") == 5, "the wand is untouched by all this")

print("reading the last scroll removes it too")
local lastScroll = item("Scroll of Magic Missile", "Scroll", { carried = 2, count = 1 })
usePower(spellOf(class(lastScroll)))
gone = true
for _, v in ipairs(DB.getChildList(inv)) do if v == lastScroll then gone = false end end
check(gone, "scroll deleted from inventory")

print("a module spell is found by name (the Wand of Air Walk case)")
local aw = item("Wand of Air Walk", "Wand", { carried = 2, charges = 10 })
local awc = class(aw)
check(awc ~= nil and DB.getValue(spellOf(awc), "name") == "Air Walk", "Air Walk found in Core Rules' reference.spells")
check(DB.getName(DB.getParent(DB.getParent(spellOf(awc)))) == "level4", "filed at level 4")

print("the campaign's own copy of a spell wins over the module's")
local mine = DB.createChild(DB.createChild(nil, "spell"))
DB.setValue(mine, "name", "string", "Magic Missile"); DB.setValue(mine, "level", "string", "Sor/Wiz 1")
DB.setValue(mine, "shortdescription", "string", "HOUSE COPY")
local mm2 = item("Wand of Magic Missile", "Wand", { carried = 2, charges = 3 })
check(DB.getValue(spellOf(class(mm2)), "shortdescription") == "HOUSE COPY", "campaign spell used")

print(fails == 0 and "ALL PASS" or (fails .. " FAILED"))
return fails
'''
sys.exit(L.execute(TEST))
