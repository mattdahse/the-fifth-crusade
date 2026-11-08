--
-- Spellbook: a "Spellbook..." radial menu item on prepared spell classes (Actions tab).
--

local MENU_SLOT = 5;

function registerMenuItems()
	if super and super.registerMenuItems then
		super.registerMenuItems();
	end
	local nodeClass = getDatabaseNode();
	if DB.getValue(nodeClass, "castertype", "") == "" and (Session.IsHost or DB.isOwner(nodeClass)) then
		registerMenuItem("Spellbook...", "radial_magicwand", MENU_SLOT);
	end
end

function onMenuSelection(selection, ...)
	if selection == MENU_SLOT then
		SpellbookMC.open(getDatabaseNode());
		return;
	end
	if super and super.onMenuSelection then
		super.onMenuSelection(selection, ...);
	end
end
