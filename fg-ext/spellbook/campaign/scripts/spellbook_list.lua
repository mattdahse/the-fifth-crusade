--
-- Spellbook list: sorted by level then name, filtered by the level drop-down and the search box.
--

function onSortCompare(w1, w2)
	local n1 = DB.getValue(w1.getDatabaseNode(), "level", 0);
	local n2 = DB.getValue(w2.getDatabaseNode(), "level", 0);
	if n1 ~= n2 then
		return n1 > n2;
	end
	return DB.getValue(w1.getDatabaseNode(), "name", ""):lower() > DB.getValue(w2.getDatabaseNode(), "name", ""):lower();
end

function onFilter(w)
	local node = w.getDatabaseNode();
	local sLevel = DB.getValue(window.getDatabaseNode(), "levelfilter", "");
	w.level.setVisible(sLevel == "prep");
	if sLevel == "prep" then
		if DB.getValue(node, "prep", 0) == 0 and DB.getValue(node, "keep", 0) == 0 then
			return false;
		end
	elseif sLevel ~= "" then
		if DB.getValue(node, "level", 0) ~= tonumber(sLevel) then
			return false;
		end
	end
	local sFilter = window.filter.getValue():lower();
	if sFilter ~= "" and not DB.getValue(node, "name", ""):lower():find(sFilter, 1, true) then
		return false;
	end
	return true;
end

-- Drop a spell from the Spells list (or any spell record) to add it by hand.
function onDrop(_, _, draginfo)
	if not draginfo.isType("shortcut") then
		return false;
	end
	local _, sRecord = draginfo.getShortcutData();
	local nodeSpell = DB.findNode(sRecord or "");
	if not nodeSpell or DB.getValue(nodeSpell, "level", nil) == nil then
		return false;
	end
	if (sRecord or ""):match("^charsheet%.") then
		ChatManager.SystemMessage("Spellbook: drop the spell from the Spells list or a module, not from a character sheet.");
		return true;
	end
	local sLevel = DB.getValue(window.getDatabaseNode(), "levelfilter", "");
	SpellbookMC.addManual(window.getDatabaseNode(), nodeSpell, tonumber(sLevel));
	applyFilter();
	return true;
end
