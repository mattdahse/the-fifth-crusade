--
-- Spellbook window. Database node: <character>.mc_spellbook.<spell class id>
--

--luacheck: globals title list filter levelfilter chip0 chip1 chip2 chip3 chip4 chip5 chip6 chip7 chip8 chip9

function onInit()
	local nodeBook = getDatabaseNode();
	local nodeClass = SpellbookMC.getClassNode(nodeBook);
	local nodeChar = DB.getChild(nodeClass, "...");
	title.setValue(string.format("Spellbook: %s (%s)",
		DB.getValue(nodeClass, "label", ""), DB.getValue(nodeChar, "name", "")));

	self.fillLevelFilter();
	DB.addHandler(DB.getPath(nodeBook, "levelfilter"), "onUpdate", self.onLevelFilterChanged);
	list.applyFilter();
	self.onCountsChanged();
end

-- The levels this class can cast (from its slots), then Prepared. Keeps the current choice if it
-- is still offered, else picks the lowest level.
function fillLevelFilter()
	local nodeBook = getDatabaseNode();
	local tLevels = SpellbookMC.castableLevels(nodeBook);
	levelfilter.clear();
	for _,n in ipairs(tLevels) do
		levelfilter.add(tostring(n), "Level " .. n);
	end
	levelfilter.add("prep", "Prepared");
	local sCur = DB.getValue(nodeBook, "levelfilter", "");
	if not levelfilter.hasValue(sCur) then
		sCur = tostring(tLevels[1] or "prep");
	end
	if DB.getValue(nodeBook, "levelfilter", "") ~= sCur then
		DB.setValue(nodeBook, "levelfilter", "string", sCur);
	end
	levelfilter.setValue(sCur);
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "levelfilter"), "onUpdate", self.onLevelFilterChanged);
end

function onLevelFilterChanged()
	list.applyFilter();
	self.updateChips();
end

local CHIP_COLORS = {
	full = { back = "FF2E7D32", text = "FFFFFFFF" },   -- green: every slot filled
	open = { back = "FFC77700", text = "FFFFFFFF" },   -- amber: slots left to fill
	over = { back = "FFB71C1C", text = "FFFFFFFF" },   -- red: more prepared than slots
};

function updateChips()
	local nodeBook = getDatabaseNode();
	local sCur = DB.getValue(nodeBook, "levelfilter", "");
	local tShown = {};
	for _,r in ipairs(SpellbookMC.levelStatus(nodeBook)) do
		local c = self["chip" .. r.level];
		if c then
			tShown[r.level] = true;
			local tColor = CHIP_COLORS[r.state];
			c.setValue(string.format("%d: %d/%d", r.level, r.prep, r.slots));
			c.setBackColor(tColor.back);
			c.setColor(tColor.text);
			local sTip;
			if r.state == "full" then
				sTip = string.format("Level %d: all %d slots prepared.", r.level, r.slots);
			elseif r.state == "open" then
				sTip = string.format("Level %d: %d of %d prepared, %d still to prepare.", r.level, r.prep, r.slots, r.slots - r.prep);
			else
				sTip = string.format("Level %d: %d prepared for %d slots, %d too many.", r.level, r.prep, r.slots, r.prep - r.slots);
			end
			c.setTooltipText(sTip .. " Click to show this level.");
			if tostring(r.level) == sCur then
				c.setFrame("fieldfocus", 2, 2, 2, 2);
			else
				c.setFrame(nil);
			end
			c.setVisible(true);
		end
	end
	for n = 0, 9 do
		if not tShown[n] then
			self["chip" .. n].setVisible(false);
		end
	end
end

function onChipClicked(n)
	local sValue = tostring(n);
	if levelfilter.hasValue(sValue) then
		levelfilter.setValue(sValue);
	end
end

function onFilterChanged()
	list.applyFilter();
end

function onCountsChanged()
	self.updateChips();
	if DB.getValue(getDatabaseNode(), "levelfilter", "") == "prep" then
		list.applyFilter();
	end
end

function onPrepare()
	local nodeBook = getDatabaseNode();
	local tReport = SpellbookMC.prepare(nodeBook);
	SpellbookMC.reportPrepare(nodeBook, tReport);
	self.onCountsChanged();
end

function onTidy()
	SpellbookMC.confirmTidy(getDatabaseNode());
end

function onRebuild()
	local nodeBook = getDatabaseNode();
	local nAdded, nRemoved, nTotal = SpellbookMC.rebuild(nodeBook);
	SpellbookMC.syncFromSheet(nodeBook);
	ChatManager.SystemMessage(string.format("Spellbook: %d spells (%d new, %d gone).", nTotal, nAdded, nRemoved));
	self.fillLevelFilter();
	list.applyFilter();
	self.onCountsChanged();
end
