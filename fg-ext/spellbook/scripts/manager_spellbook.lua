--
-- Spellbook (Prepared Spells Only)
--
-- A prepared caster's Actions tab should hold the spells prepared today, not every spell the
-- class could prepare. Each spell on the tab is a full copy with parsed actions and effects,
-- and FG builds a window for every one of them, prepared or not.
--
-- The spellbook keeps the full choice somewhere cheap: on the character, in
-- mc_spellbook.<spell class id>, as one small entry per spell (name, level, a link to the library
-- record, how many to prepare). Only the Prepare button touches the Actions tab, and it adds
-- spells through the ruleset's own SpellManager.addSpell, the same path a drag from the Spells
-- list takes.
--
-- Why not under the spell class: the 3.5E ruleset puts an onChildUpdate handler on the whole
-- spellset, and every write anywhere below it refreshes every action of every spell on the
-- sheet. A book stored there froze FG for minutes on its first build (v1.0.0). For the same
-- reason Prepare and Tidy, which must write under the spellset, close the character sheet while
-- they run and reopen it after, and they skip writes that change nothing.
--
-- Rules for the Actions tab:
--   * Prepare adds what is wanted and sets its prepared count. A spell it added itself (marked
--     mc_book) and no longer wanted is deleted. Any other spell is never deleted, only set to 0.
--   * Keep, on a book entry, means "always on the Actions tab", prepared or not. Tick it for a
--     spell whose actions were edited by hand.
--   * Tidy is the one-time handover: it deletes unprepared spells the book can bring back,
--     except kept ones, and marks what is left as the book's.
--

local BOOKS = "mc_spellbook";    -- on the character: one book per spell class, by its id
local LEGACY = "mc_book";        -- v1.0.0 kept the book under the spell class; removed on open
local MARK = "mc_book";          -- on a sheet spell: 1 when the spellbook added it

-- Short class names used in the level lines of the 3.5E and PF SRD modules.
local ALIAS = {
	clr = "cleric", sor = "sorcerer", wiz = "wizard", drd = "druid", brd = "bard",
	rgr = "ranger", pal = "paladin", adp = "adept",
};

local function trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "");
end

function classKey(s)
	s = trim(s):lower():gsub("%s+", " ");
	return ALIAS[s] or s;
end

-- "Cure Light Wounds, Mass" and "Mass Cure Light Wounds" are the same spell.
function nameKey(s)
	s = trim(s):lower();
	local sBase, sMod = s:match("^(.-),%s*(.+)$");
	if sBase then
		s = sMod .. " " .. sBase;
	end
	return (s:gsub("[^%w]", ""));
end

-- "Cleric 1, Oracle 1, Sor/Wiz 2, Summoner UC 1" -> { cleric = 1, oracle = 1, sorcerer = 2,
-- wizard = 2, ["summoner uc"] = 1 }. Domains in the 3.5E level line ("Good 2") come through too.
function parseLevels(sLevel)
	local t = {};
	for sPart in (sLevel or ""):gmatch("[^,;]+") do
		local sNames, sNum = sPart:match("^%s*(.-)%s*(%d+)%s*$");
		if sNames and sNames ~= "" then
			local n = tonumber(sNum);
			for sName in sNames:gmatch("[^/]+") do
				local k = classKey(sName);
				if k ~= "" and (t[k] == nil or n < t[k]) then
					t[k] = n;
				end
			end
		end
	end
	return t;
end

-- The lowest level on the line, for a dropped spell of no listed class.
function lowestLevel(sLevel)
	local nLow;
	for _,n in pairs(parseLevels(sLevel)) do
		if not nLow or n < nLow then
			nLow = n;
		end
	end
	return nLow;
end

local function splitList(s)
	local t = {};
	for sRaw in (s or ""):gmatch("[^,]+") do
		local sItem = trim(sRaw);
		if sItem ~= "" then
			table.insert(t, sItem);
		end
	end
	return t;
end

function getClassKeys(nodeBook)
	local t = {};
	for _,s in ipairs(splitList(DB.getValue(nodeBook, "classkeys", ""))) do
		table.insert(t, classKey(s));
	end
	return t;
end

-- The level this spell has for any of the book's lists, or nil.
function levelForKeys(sLevel, tKeys)
	local tLevels = parseLevels(sLevel);
	local nBest;
	for _,k in ipairs(tKeys) do
		local n = tLevels[k];
		if n and (not nBest or n < nBest) then
			nBest = n;
		end
	end
	return nBest;
end

local function isSkipped(sModule, tSkip)
	local s = (sModule or ""):lower();
	if s == "" then
		return false;
	end
	for _,sPat in ipairs(tSkip) do
		if s:find(sPat:lower(), 1, true) then
			return true;
		end
	end
	return false;
end

local function spellDataPaths()
	if RecordDataManager and RecordDataManager.getDataPaths then
		local t = RecordDataManager.getDataPaths("spell");
		if t and #t > 0 then
			return t;
		end
	end
	return { "spell", "reference.spells", "spelldesc" };
end

local function moduleOf(node)
	return (DB.getModule and DB.getModule(node)) or "";
end

--
--	THE BOOK
--

local function charOf(nodeSpellClass)
	return DB.getParent(DB.getParent(nodeSpellClass));
end

function getClassNode(nodeBook)
	return DB.findNode(DB.getValue(nodeBook, "classpath", ""));
end

-- Only write when the value changes: under the spellset, every write costs a full refresh.
local function setNumber(node, sField, n)
	if DB.getValue(node, sField) ~= n then
		DB.setValue(node, sField, "number", n);
	end
end

-- Runs fn with the character's sheet closed here, so the ruleset's spellset handler (which
-- refreshes every spell action on each write) isn't attached while fn makes many writes.
local SHEET_CLASSES = { "charsheet", "npc" };
function withSheetClosed(nodeSpellClass, fn)
	local sPath = DB.getPath(charOf(nodeSpellClass));
	local tClosed = {};
	if Interface.findWindow then
		for _,sClass in ipairs(SHEET_CLASSES) do
			local w = Interface.findWindow(sClass, sPath);
			if w then
				table.insert(tClosed, sClass);
				w.close();
			end
		end
	end
	local tResult = { pcall(fn) };
	for _,sClass in ipairs(tClosed) do
		Interface.openWindow(sClass, sPath);
	end
	if not tResult[1] then
		error(tResult[2], 0);
	end
	local fnUnpack = unpack or table.unpack;
	return select(2, fnUnpack(tResult));
end

function getEntries(nodeBook)
	return DB.getChildList(nodeBook, "entries");
end

local function entryIndex(nodeBook)
	local t = {};
	for _,v in ipairs(getEntries(nodeBook)) do
		t[nameKey(DB.getValue(v, "name", ""))] = v;
	end
	return t;
end

function getBook(nodeSpellClass)
	local nodeLegacy = DB.getChild(nodeSpellClass, LEGACY);
	if nodeLegacy then
		DB.deleteNode(nodeLegacy);
	end
	local sName = DB.getName(nodeSpellClass);
	local nodeChar = charOf(nodeSpellClass);
	local nodeBook = DB.getChild(nodeChar, BOOKS .. "." .. sName);
	if nodeBook then
		return nodeBook;
	end
	nodeBook = DB.createChild(DB.createChild(nodeChar, BOOKS), sName);
	DB.setValue(nodeBook, "classpath", "string", DB.getPath(nodeSpellClass));
	DB.setValue(nodeBook, "classkeys", "string", classKey(DB.getValue(nodeSpellClass, "label", "")));
	DB.setValue(nodeBook, "skipsources", "string", "3.5E");
	return nodeBook;
end

local function setLink(nodeEntry, nodeSpell)
	local sRecord = DB.getPath(nodeSpell);
	DB.setValue(nodeEntry, "link", "windowreference", "spelldesc", sRecord);
	DB.setValue(nodeEntry, "recordname", "string", sRecord);
	local sModule = moduleOf(nodeSpell);
	DB.setValue(nodeEntry, "source", "string", sModule == "" and "Campaign" or sModule);
end

-- Rebuild the book from every loaded spell list. Entries keep their prepare count and Keep.
-- Returns added, removed, total.
function rebuild(nodeBook)
	local tKeys = getClassKeys(nodeBook);
	local tSkip = splitList(DB.getValue(nodeBook, "skipsources", ""));

	-- Pick one record per spell name: the campaign's own copy, else the first module's.
	local tFound = {};
	for _,sPath in ipairs(spellDataPaths()) do
		for _,v in ipairs(DB.getChildrenGlobal(sPath)) do
			local sModule = moduleOf(v);
			if not isSkipped(sModule, tSkip) then
				local nLevel = levelForKeys(DB.getValue(v, "level", ""), tKeys);
				if nLevel then
					local k = nameKey(DB.getValue(v, "name", ""));
					local tCur = tFound[k];
					if k ~= "" and (not tCur or (tCur.sModule ~= "" and sModule == "")) then
						tFound[k] = { node = v, nLevel = nLevel, sModule = sModule };
					end
				end
			end
		end
	end

	local tIndex = entryIndex(nodeBook);
	local nAdded, nRemoved = 0, 0;
	local nodeEntries = DB.createChild(nodeBook, "entries");
	for k,t in pairs(tFound) do
		local nodeEntry = tIndex[k];
		if not nodeEntry then
			nodeEntry = DB.createChild(nodeEntries);
			DB.setValue(nodeEntry, "name", "string", DB.getValue(t.node, "name", ""));
			nAdded = nAdded + 1;
		end
		if DB.getValue(nodeEntry, "manual", 0) == 0 then
			setNumber(nodeEntry, "level", t.nLevel);
		end
		if DB.getValue(nodeEntry, "recordname", "") ~= DB.getPath(t.node) then
			setLink(nodeEntry, t.node);
		end
		setNumber(nodeEntry, "missing", 0);
	end
	for k,nodeEntry in pairs(tIndex) do
		if not tFound[k] and DB.getValue(nodeEntry, "manual", 0) == 0 then
			if DB.getValue(nodeEntry, "keep", 0) == 0 and DB.getValue(nodeEntry, "prep", 0) == 0 then
				DB.deleteNode(nodeEntry);
				nRemoved = nRemoved + 1;
			else
				setNumber(nodeEntry, "missing", 1);
			end
		end
	end
	return nAdded, nRemoved, #getEntries(nodeBook);
end

-- A spell dropped on the book. Kept through rebuilds even if no list names it.
function addManual(nodeBook, nodeSpell, nLevel)
	if not nodeSpell then
		return nil;
	end
	local sLevel = DB.getValue(nodeSpell, "level", "");
	nLevel = nLevel or levelForKeys(sLevel, getClassKeys(nodeBook)) or lowestLevel(sLevel) or 0;
	local k = nameKey(DB.getValue(nodeSpell, "name", ""));
	local nodeEntry = entryIndex(nodeBook)[k];
	if not nodeEntry then
		nodeEntry = DB.createChild(DB.createChild(nodeBook, "entries"));
		DB.setValue(nodeEntry, "name", "string", DB.getValue(nodeSpell, "name", ""));
	end
	DB.setValue(nodeEntry, "manual", "number", 1);
	DB.setValue(nodeEntry, "level", "number", nLevel);
	DB.setValue(nodeEntry, "missing", "number", 0);
	setLink(nodeEntry, nodeSpell);
	return nodeEntry;
end

--
--	THE ACTIONS TAB
--

local function levelSpellsNode(nodeSpellClass, nLevel, bCreate)
	local sPath = "levels.level" .. nLevel .. ".spells";
	if bCreate then
		return DB.createChild(nodeSpellClass, sPath);
	end
	return DB.getChild(nodeSpellClass, sPath);
end

-- Sheet spells at a level, by name key: { key = { node, node, ... } }
local function sheetIndex(nodeSpellClass, nLevel)
	local t = {};
	local nodeSpells = levelSpellsNode(nodeSpellClass, nLevel, false);
	if not nodeSpells then
		return t;
	end
	for _,v in ipairs(DB.getChildList(nodeSpells)) do
		local k = nameKey(DB.getValue(v, "name", ""));
		if k ~= "" then
			t[k] = t[k] or {};
			table.insert(t[k], v);
		end
	end
	return t;
end

-- The book's counts mirror the Actions tab whenever the window opens. Edits in the window are
-- pending until Prepare.
function syncFromSheet(nodeBook)
	local nodeSpellClass = getClassNode(nodeBook);
	local tSheet = {};
	for nLevel = 0, 9 do
		tSheet[nLevel] = sheetIndex(nodeSpellClass, nLevel);
	end
	for _,v in ipairs(getEntries(nodeBook)) do
		local tNodes = (tSheet[DB.getValue(v, "level", 0)] or {})[nameKey(DB.getValue(v, "name", ""))];
		local nPrep = 0;
		for _,n in ipairs(tNodes or {}) do
			nPrep = nPrep + DB.getValue(n, "prepared", 0);
		end
		setNumber(v, "prep", nPrep);
	end
end

local function msg(s)
	if ChatManager and ChatManager.SystemMessage then
		ChatManager.SystemMessage(s);
	end
end

-- Returns a report table: added, removed, prepared, missing (names).
function prepare(nodeBook)
	return withSheetClosed(getClassNode(nodeBook), function() return prepareNow(nodeBook); end);
end

function prepareNow(nodeBook)
	local nodeSpellClass = getClassNode(nodeBook);
	local tReport = { added = 0, removed = 0, prepared = 0, missing = {} };

	local tByLevel = {};
	for _,v in ipairs(getEntries(nodeBook)) do
		local nLevel = DB.getValue(v, "level", 0);
		tByLevel[nLevel] = tByLevel[nLevel] or {};
		tByLevel[nLevel][nameKey(DB.getValue(v, "name", ""))] = v;
	end

	for nLevel = 0, 9 do
		local tWanted = tByLevel[nLevel] or {};
		local tSheet = sheetIndex(nodeSpellClass, nLevel);

		for k,nodeEntry in pairs(tWanted) do
			local nPrep = DB.getValue(nodeEntry, "prep", 0);
			local bKeep = DB.getValue(nodeEntry, "keep", 0) == 1;
			if nPrep > 0 or bKeep then
				local tNodes = tSheet[k];
				local nodeSpell = tNodes and tNodes[1];
				if not nodeSpell then
					local nodeSource = DB.findNode(DB.getValue(nodeEntry, "recordname", ""));
					if nodeSource then
						levelSpellsNode(nodeSpellClass, nLevel, true);
						nodeSpell = SpellManager.addSpell(nodeSource, nodeSpellClass, nLevel);
						if nodeSpell then
							DB.setValue(nodeSpell, MARK, "number", 1);
							tReport.added = tReport.added + 1;
						end
					end
					if not nodeSpell then
						table.insert(tReport.missing, DB.getValue(nodeEntry, "name", ""));
					end
				end
				if nodeSpell then
					setNumber(nodeSpell, "prepared", nPrep);
					tReport.prepared = tReport.prepared + nPrep;
					-- duplicates of the same spell at this level carry no count
					for i = 2, #(tNodes or {}) do
						setNumber(tNodes[i], "prepared", 0);
					end
				end
				tSheet[k] = nil;
			end
		end

		-- Whatever is left on this level is not wanted today.
		for k,tNodes in pairs(tSheet) do
			local nodeEntry = tWanted[k];
			local bKeep = nodeEntry and DB.getValue(nodeEntry, "keep", 0) == 1;
			for _,nodeSpell in ipairs(tNodes) do
				if DB.getValue(nodeSpell, MARK, 0) == 1 and not bKeep then
					DB.deleteNode(nodeSpell);
					tReport.removed = tReport.removed + 1;
				else
					setNumber(nodeSpell, "prepared", 0);
				end
			end
		end
	end

	if SpellManager.updateSpellClassCounts then
		SpellManager.updateSpellClassCounts(nodeSpellClass);
	end
	return tReport;
end

-- The one-time handover. Returns the sheet spells Tidy would delete, and the names of
-- unprepared sheet spells it must leave because the book doesn't know them (their module isn't
-- loaded, or they're on a list the book doesn't read, or they're custom).
function tidyPlan(nodeBook)
	local nodeSpellClass = getClassNode(nodeBook);
	local tIndex = entryIndex(nodeBook);
	local tDelete, tUnknown = {}, {};
	for nLevel = 0, 9 do
		for k,tNodes in pairs(sheetIndex(nodeSpellClass, nLevel)) do
			local nodeEntry = tIndex[k];
			for _,nodeSpell in ipairs(tNodes) do
				if DB.getValue(nodeSpell, "prepared", 0) == 0 then
					if not nodeEntry then
						table.insert(tUnknown, DB.getValue(nodeSpell, "name", ""));
					elseif DB.getValue(nodeEntry, "keep", 0) == 0 then
						table.insert(tDelete, nodeSpell);
					end
				end
			end
		end
	end
	table.sort(tUnknown);
	return tDelete, tUnknown;
end

-- Deletes the plan, then hands every remaining sheet spell the book knows (and is not kept) to
-- the book, so later Prepares can remove it when it is dropped. Returns deleted, handed over.
function tidy(nodeBook)
	return withSheetClosed(getClassNode(nodeBook), function() return tidyNow(nodeBook); end);
end

function tidyNow(nodeBook)
	local tDelete = tidyPlan(nodeBook);
	for _,nodeSpell in ipairs(tDelete) do
		DB.deleteNode(nodeSpell);
	end
	local nodeSpellClass = getClassNode(nodeBook);
	local tIndex = entryIndex(nodeBook);
	local nMarked = 0;
	for nLevel = 0, 9 do
		for k,tNodes in pairs(sheetIndex(nodeSpellClass, nLevel)) do
			local nodeEntry = tIndex[k];
			if nodeEntry and DB.getValue(nodeEntry, "keep", 0) == 0 then
				for _,nodeSpell in ipairs(tNodes) do
					setNumber(nodeSpell, MARK, 1);
					nMarked = nMarked + 1;
				end
			end
		end
	end
	if SpellManager.updateSpellClassCounts then
		SpellManager.updateSpellClassCounts(nodeSpellClass);
	end
	return #tDelete, nMarked;
end

-- The levels the level drop-down offers: those the class has slots for. A class with no slots
-- set yet offers the levels its book holds, else level 0.
function castableLevels(nodeBook)
	local nodeSpellClass = getClassNode(nodeBook);
	local t = {};
	for n = 0, 9 do
		if DB.getValue(nodeSpellClass, "availablelevel" .. n, 0) > 0 then
			table.insert(t, n);
		end
	end
	if #t == 0 then
		local tSeen = {};
		for _,v in ipairs(getEntries(nodeBook)) do
			tSeen[DB.getValue(v, "level", 0)] = true;
		end
		for n = 0, 9 do
			if tSeen[n] then
				table.insert(t, n);
			end
		end
	end
	if #t == 0 then
		t = { 0 };
	end
	return t;
end

-- "0: 4/4  1: 5/6  2: 7/6!" from the book's pending counts and the class's slots.
-- Per level, from the book's pending counts and the class's slots: { level, prep, slots, state },
-- for each level with slots or with something prepared. state is "full" (every slot filled),
-- "open" (slots left to fill) or "over" (more prepared than slots).
function levelStatus(nodeBook)
	local nodeSpellClass = getClassNode(nodeBook);
	local tPrep = {};
	for _,v in ipairs(getEntries(nodeBook)) do
		local n = DB.getValue(v, "level", 0);
		tPrep[n] = (tPrep[n] or 0) + DB.getValue(v, "prep", 0);
	end
	local t = {};
	for n = 0, 9 do
		local nSlots = DB.getValue(nodeSpellClass, "availablelevel" .. n, 0);
		local nPrep = tPrep[n] or 0;
		if nSlots > 0 or nPrep > 0 then
			local sState = (nPrep > nSlots and "over") or (nPrep == nSlots and "full") or "open";
			table.insert(t, { level = n, prep = nPrep, slots = nSlots, state = sState });
		end
	end
	return t;
end

function slotSummary(nodeBook)
	local t = {};
	for _,r in ipairs(levelStatus(nodeBook)) do
		table.insert(t, string.format("%d: %d/%d%s", r.level, r.prep, r.slots, r.state == "over" and "!" or ""));
	end
	return table.concat(t, "   ");
end

--
--	UI ENTRY POINTS
--

function open(nodeSpellClass)
	local nodeBook = getBook(nodeSpellClass);
	if #getEntries(nodeBook) == 0 then
		local nAdded = rebuild(nodeBook);
		if nAdded == 0 then
			msg("Spellbook: no spells found for \"" .. DB.getValue(nodeBook, "classkeys", "") ..
				"\". Set the list name at the top of the window and press Rebuild, or drop spells on the list.");
		end
	end
	syncFromSheet(nodeBook);
	return Interface.openWindow("mc_spellbook", DB.getPath(nodeBook));
end

function reportPrepare(nodeBook, tReport)
	local sClass = DB.getValue(getClassNode(nodeBook), "label", "");
	local s = string.format("Spellbook: %s has %d spells prepared (%d added to the Actions tab, %d removed).",
		sClass, tReport.prepared, tReport.added, tReport.removed);
	if #tReport.missing > 0 then
		s = s .. " Not found in any loaded module: " .. table.concat(tReport.missing, ", ") .. ".";
	end
	msg(s);
end

local function unknownNote(tUnknown)
	if #tUnknown == 0 then
		return "";
	end
	return string.format("\n\nLeft on the Actions tab because the spellbook doesn't have them (%d): %s. " ..
		"If they come from a module that isn't loaded, load it, press Rebuild, and Tidy again.",
		#tUnknown, table.concat(tUnknown, ", "));
end

function confirmTidy(nodeBook)
	local tPlan, tUnknown = tidyPlan(nodeBook);
	if #tPlan == 0 then
		local _, nMarked = tidy(nodeBook);
		msg("Spellbook: nothing to remove. " .. nMarked .. " spells on the Actions tab are now managed by the spellbook." ..
			unknownNote(tUnknown):gsub("^%s+", " "));
		return;
	end
	local tNames = {};
	for _,v in ipairs(tPlan) do
		table.insert(tNames, DB.getValue(v, "name", ""));
	end
	table.sort(tNames);
	local sText = string.format(
		"Remove %d unprepared spells from the Actions tab? The spellbook can add any of them back.\n\n" ..
		"Spells you edited by hand: cancel, tick Keep on them, and Tidy again.\n\n%s%s",
		#tPlan, table.concat(tNames, ", "), unknownNote(tUnknown));
	DialogManager.openDialog("dialog_okcancel", {
		sTitle = "Tidy the Actions tab",
		sText = sText,
		fnCallback = function(sResult)
			if sResult == "ok" then
				local nDeleted, nMarked = tidy(nodeBook);
				msg(string.format("Spellbook: removed %d spells; %d left on the Actions tab are now managed by the spellbook.", nDeleted, nMarked));
			end
		end,
	});
end
