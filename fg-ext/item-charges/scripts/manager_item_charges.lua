--
-- Item Charges (No Recharge)
--
-- Equipped wands, staves, scrolls and potions get a "points" spell class on the Actions tab,
-- one class per item, holding the item's spell.
--
-- THE ITEM IS THE ONLY RECORD OF HOW MANY CHARGES ARE LEFT. The spell class is a view of it:
-- its points always equal the item's remaining charges (or count, for potions and scrolls), and
-- its points used are always 0. When a cast spends a point, the charge comes straight off the
-- item and the class is reset to the new total with nothing used.
--
-- That is what makes a long rest harmless. The ruleset's rest (SpellManager.resetSpells) sets
-- pointsused to 0 on every spell class. On an item class it is already 0, so nothing happens,
-- and there is no stored "used" count anywhere for a rest to wipe.
--
-- All of the work happens on the host. Players' clients spend points through the normal power
-- code, the change replicates to the host, and the host's handlers do the bookkeeping.
--

local SPELLSET = "spellset";
local MARK = "mc_item";          -- on a spell class: the path of the item it belongs to

local _bBusy = false;            -- guards our own writes against the handlers they trigger

--
--	ITEM CLASSIFICATION
--

local function itemKind(nodeItem)
	local s = (DB.getValue(nodeItem, "type", "") .. " " .. DB.getValue(nodeItem, "subtype", "")):lower();
	if s:find("wand", 1, true) then return "wand"; end
	if s:find("staff", 1, true) then return "staff"; end
	if s:find("scroll", 1, true) then return "scroll"; end
	if s:find("potion", 1, true) or s:find("elixir", 1, true) then return "potion"; end
	return nil;
end

-- Wands and staves keep charges; potions and scrolls are a stack and use their count.
local function chargeField(sKind)
	if sKind == "wand" or sKind == "staff" then
		return "charges";
	end
	return "count";
end

local function isEquipped(nodeItem)
	return DB.getValue(nodeItem, "carried", 0) == 2;
end

local function isIdentified(nodeItem)
	return DB.getValue(nodeItem, "isidentified", 1) ~= 0;
end

--
--	READING THE ITEM
--

-- Charges written into an item's name: "[7 charges]", "(48 charges)", "[7 charge]", or a trailing
-- " - 44" as in "Wand of Cure Serious Wounds (CL 5) - 44".
local function chargesInName(sName)
	return tonumber(sName:match("[%[%(]%s*(%d+)%s*charges?%s*[%]%)]"))
		or tonumber(sName:match("%s%-%s*(%d+)%s*$"));
end

-- Charges left on a wand or staff. If the charges field has never been set, look in the name
-- (above), then for "7 charges" in the description, and write what is found back to the field so
-- it is set from then on. Once the field exists it is the only answer, even at 0: reading the
-- name again would put a used-up wand back to full. Never invents a default.
local function readCharges(nodeItem, sKind)
	local sField = chargeField(sKind);
	if sField == "count" then
		return DB.getValue(nodeItem, "count", 0);
	end
	local nodeField = DB.getChild(nodeItem, "charges");
	if nodeField then
		return DB.getValue(nodeField) or 0;
	end
	local n = chargesInName(DB.getValue(nodeItem, "name", ""));
	if not n then
		local sDesc = DB.getText(nodeItem, "description", "") or "";
		n = tonumber(sDesc:match("(%d+)%s+charges"));
	end
	if n then
		_bBusy = true;
		DB.setValue(nodeItem, "charges", "number", n);
		_bBusy = false;
		return n;
	end
	return nil;
end

local function writeRemaining(nodeItem, sKind, n)
	_bBusy = true;
	DB.setValue(nodeItem, chargeField(sKind), "number", math.max(n, 0));
	_bBusy = false;
end

-- The spell's name, from "Wand of Magic Missile", "Wand (Magic Missile)", "Scroll of See
-- Invisibility [CL 3]" and so on.
local function spellNameFromItem(sItemName)
	local s = sItemName:gsub("%b[]", ""):gsub("%s%-%s*%d+%s*$", "");
	local sParen = s:match("%((.-)%)");
	if sParen and not sParen:match("^%s*[Cc][Ll]%s*%d+%s*$") and not sParen:match("charges?") then
		return sParen;
	end
	s = s:gsub("%b()", "");
	local sAfter = s:match("[Oo]f%s+(.+)$");
	return sAfter and StringManager.trim(sAfter) or nil;
end

local function spellKey(sName)
	return sName:lower():gsub("[^%w]", "");
end

local findSpellByKey;

-- Pathfinder files "lesser restoration" as "Restoration, Lesser", so try the flipped name too.
local function findSpell(sName)
	if not sName or sName == "" then
		return nil;
	end
	local node = findSpellByKey(spellKey(sName));
	if node then
		return node;
	end
	local sMod, sRest = sName:match("^%s*(%a+)%s+(.+)$");
	if sMod and ({ lesser = true, greater = true, mass = true, communal = true })[sMod:lower()] then
		return findSpellByKey(spellKey(sRest .. sMod));
	end
	return nil;
end

findSpellByKey = function(sKey)
	local node = DB.findNode("spelldesc." .. sKey .. "@*");
	if node then
		return node;
	end
	-- Campaign spells, then every loaded module's spell list, by name.
	for _,v in ipairs(DB.getChildList("spell")) do
		if spellKey(DB.getValue(v, "name", "")) == sKey then
			return v;
		end
	end
	for _,sModule in ipairs(Module.getModules()) do
		local tInfo = Module.getModuleInfo(sModule);
		if tInfo and tInfo.loaded then
			for _,sList in ipairs({ "spelldesc@", "reference.spells@" }) do
				for _,v in ipairs(DB.getChildList(sList .. sModule)) do
					if spellKey(DB.getValue(v, "name", "")) == sKey then
						return v;
					end
				end
			end
		end
	end
	return nil;
end

-- The lowest level the spell appears at in its "level" field ("Brd 3, Sor/Wiz 2" gives 2).
local function spellLevel(nodeSpell)
	local nLow;
	for sNum in DB.getValue(nodeSpell, "level", ""):gmatch("(%d)") do
		local n = tonumber(sNum);
		if not nLow or n < nLow then
			nLow = n;
		end
	end
	return nLow or 0;
end

-- Caster level: the item's own CL field, else "(CL 5)" in the name, else the minimum for the
-- spell's level.
local function casterLevel(nodeItem, nLevel)
	local n = DB.getValue(nodeItem, "cl", 0);
	if n > 0 then
		return n;
	end
	n = tonumber(DB.getValue(nodeItem, "name", ""):match("[Cc][Ll]%s*(%d+)"));
	if n then
		return n;
	end
	if nLevel <= 1 then
		return 1;
	end
	return (nLevel * 2) - 1;
end

--
--	THE SPELL CLASS
--

local function findClass(nodeChar, nodeItem)
	local sPath = DB.getPath(nodeItem);
	for _,v in ipairs(DB.getChildList(nodeChar, SPELLSET)) do
		if DB.getValue(v, MARK, "") == sPath then
			return v;
		end
	end
	return nil;
end

local function chat(nodeChar, sText)
	local rActor = ActorManager.resolveActor(nodeChar);
	ChatManager.SystemMessage(string.format("[Item Charges] %s: %s", ActorManager.getDisplayName(rActor) or "", sText));
end

local function createClass(nodeChar, nodeItem, sKind)
	local sItemName = DB.getValue(nodeItem, "name", "");
	local sSpellName = spellNameFromItem(sItemName);
	local nodeSpell = findSpell(sSpellName);
	if not nodeSpell then
		chat(nodeChar, string.format("could not find a spell for '%s'. Name it like 'Wand of Magic Missile' and make sure a spell module is loaded.", sItemName));
		return nil;
	end

	local nRemaining = readCharges(nodeItem, sKind);
	if not nRemaining then
		chat(nodeChar, string.format("'%s' has no charges set. Set its Charges field, or put '[7 charges]' in its name.", sItemName));
		nRemaining = 0;
	end

	local nLevel = spellLevel(nodeSpell);
	_bBusy = true;
	local nodeClass = DB.createChild(DB.createChild(nodeChar, SPELLSET));
	DB.setValue(nodeClass, MARK, "string", DB.getPath(nodeItem));
	DB.setValue(nodeClass, "label", "string", sItemName);
	DB.setValue(nodeClass, "castertype", "string", "points");
	DB.setValue(nodeClass, "points", "number", nRemaining);
	DB.setValue(nodeClass, "pointsused", "number", 0);
	DB.setValue(nodeClass, "cl", "number", casterLevel(nodeItem, nLevel));
	DB.setValue(nodeClass, "dc.ability", "string", "");
	DB.createChild(nodeClass, "levels.level" .. nLevel .. ".spells");
	DB.setValue(nodeClass, "availablelevel" .. nLevel, "number", 1);

	local nodeNew = SpellManager.addSpell(nodeSpell, nodeClass, nLevel);
	if nodeNew then
		-- One charge per use, whatever the spell's level.
		DB.setValue(nodeNew, "cost", "number", 1);
		-- Item save DC: 10 + spell level + the minimum casting modifier for that level.
		for _,nodeAction in ipairs(DB.getChildList(nodeNew, "actions")) do
			if DB.getValue(nodeAction, "type", "") == "cast" then
				DB.setValue(nodeAction, "savedctype", "string", "fixed");
				DB.setValue(nodeAction, "savedcmod", "number", 10 + nLevel + math.floor(nLevel / 2));
			end
		end
	end
	_bBusy = false;
	return nodeClass;
end

local function removeClass(nodeClass)
	_bBusy = true;
	DB.deleteNode(nodeClass);
	_bBusy = false;
end

-- Make the class match the item: points = what is left, nothing used.
local function syncClass(nodeClass, nodeItem, sKind)
	local n = readCharges(nodeItem, sKind) or 0;
	_bBusy = true;
	if DB.getValue(nodeClass, "points", 0) ~= n then
		DB.setValue(nodeClass, "points", "number", n);
	end
	if DB.getValue(nodeClass, "pointsused", 0) ~= 0 then
		DB.setValue(nodeClass, "pointsused", "number", 0);
	end
	local sName = DB.getValue(nodeItem, "name", "");
	if DB.getValue(nodeClass, "label", "") ~= sName then
		DB.setValue(nodeClass, "label", "string", sName);
	end
	_bBusy = false;
end

-- Bring one item's class into line with the item: create, sync or remove it.
local function refreshItem(nodeItem)
	local nodeChar = DB.getChild(nodeItem, "...");
	if not nodeChar or DB.getName(DB.getParent(nodeItem)) ~= "inventorylist" then
		return;
	end
	local sKind = itemKind(nodeItem);
	local nodeClass = findClass(nodeChar, nodeItem);
	local bWanted = sKind and isEquipped(nodeItem) and isIdentified(nodeItem);
	if not bWanted then
		if nodeClass then
			removeClass(nodeClass);
		end
		return;
	end
	if nodeClass then
		syncClass(nodeClass, nodeItem, sKind);
	else
		createClass(nodeChar, nodeItem, sKind);
	end
end

-- Remove item classes whose item no longer exists or is no longer equipped, and any class left
-- behind by Advanced Item Actions (it marks them with source_name = the item's path). Those
-- would otherwise sit beside this extension's class for the same item, holding the stale count.
local function sweepChar(nodeChar)
	for _,nodeClass in ipairs(DB.getChildList(nodeChar, SPELLSET)) do
		if DB.getValue(nodeClass, MARK, "") == "" and DB.getValue(nodeClass, "source_name", ""):find("%.inventorylist%.") then
			removeClass(nodeClass);
		end
	end
	for _,nodeClass in ipairs(DB.getChildList(nodeChar, SPELLSET)) do
		local sPath = DB.getValue(nodeClass, MARK, "");
		if sPath ~= "" then
			local nodeItem = DB.findNode(sPath);
			if not nodeItem then
				removeClass(nodeClass);
			else
				refreshItem(nodeItem);
			end
		end
	end
	for _,nodeItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if itemKind(nodeItem) and isEquipped(nodeItem) then
			refreshItem(nodeItem);
		end
	end
end

--
--	HANDLERS
--

local function onItemField(nodeItem, _)
	if _bBusy or not Session.IsHost then
		return;
	end
	refreshItem(nodeItem);
end

-- A cast spent points on an item class: take them off the item, then reset the class.
-- A rest setting pointsused to 0 lands here too, and does nothing, because it was already 0.
local function onPointsUsed(nodeField)
	if _bBusy or not Session.IsHost then
		return;
	end
	local nodeClass = DB.getParent(nodeField);
	local sPath = DB.getValue(nodeClass, MARK, "");
	if sPath == "" then
		return;
	end
	local nodeItem = DB.findNode(sPath);
	if not nodeItem then
		removeClass(nodeClass);
		return;
	end
	local sKind = itemKind(nodeItem) or "wand";
	local nUsed = DB.getValue(nodeField) or 0;
	if nUsed > 0 then
		local nLeft = DB.getValue(nodeClass, "points", 0) - nUsed;
		writeRemaining(nodeItem, sKind, nLeft);
		if nLeft <= 0 then
			chat(DB.getChild(nodeClass, "..."), string.format("'%s' is used up.", DB.getValue(nodeItem, "name", "")));
		end
	end
	syncClass(nodeClass, nodeItem, sKind);
end

-- Anyone typing into the class's points box is overruled by the item.
local function onPoints(nodeField)
	if _bBusy or not Session.IsHost then
		return;
	end
	local nodeClass = DB.getParent(nodeField);
	local sPath = DB.getValue(nodeClass, MARK, "");
	if sPath == "" then
		return;
	end
	local nodeItem = DB.findNode(sPath);
	if nodeItem then
		syncClass(nodeClass, nodeItem, itemKind(nodeItem) or "wand");
	end
end

local function onInventoryChildDeleted(nodeList)
	if _bBusy or not Session.IsHost then
		return;
	end
	sweepChar(DB.getParent(nodeList));
end

function onInit()
	if not Session.IsHost then
		return;
	end
	for _,sField in ipairs({ "carried", "count", "charges", "isidentified", "name", "type", "cl" }) do
		CharInventoryManager.registerFieldUpdateCallback(sField, onItemField);
	end
	DB.addHandler("charsheet.*." .. SPELLSET .. ".*.pointsused", "onUpdate", onPointsUsed);
	DB.addHandler("charsheet.*." .. SPELLSET .. ".*.points", "onUpdate", onPoints);
	DB.addHandler("charsheet.*.inventorylist", "onChildDeleted", onInventoryChildDeleted);
end

function onTabletopInit()
	if not Session.IsHost then
		return;
	end
	for _,nodeChar in ipairs(DB.getChildList("charsheet")) do
		sweepChar(nodeChar);
	end
end
