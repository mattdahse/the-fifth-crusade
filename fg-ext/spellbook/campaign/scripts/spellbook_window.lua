--
-- Spellbook window. Database node: <character>.mc_spellbook.<spell class id>
--

--luacheck: globals title slots list filter levelfilter

function onInit()
	local nodeBook = getDatabaseNode();
	local nodeClass = SpellbookMC.getClassNode(nodeBook);
	local nodeChar = DB.getChild(nodeClass, "...");
	title.setValue(string.format("Spellbook: %s (%s)",
		DB.getValue(nodeClass, "label", ""), DB.getValue(nodeChar, "name", "")));

	DB.addHandler(DB.getPath(nodeBook, "levelfilter"), "onUpdate", self.onLevelFilterChanged);
	self.onCountsChanged();
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "levelfilter"), "onUpdate", self.onLevelFilterChanged);
end

function onLevelFilterChanged()
	list.applyFilter();
end

function onFilterChanged()
	list.applyFilter();
end

function onCountsChanged()
	slots.setValue(SpellbookMC.slotSummary(getDatabaseNode()));
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
	list.applyFilter();
	self.onCountsChanged();
end
