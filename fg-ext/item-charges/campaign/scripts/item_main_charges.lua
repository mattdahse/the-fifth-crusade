--
-- Item Charges (No Recharge): show the Charges box on identified wands and staves only.
--

function onStateChanged()
	if super and super.onStateChanged then
		super.onStateChanged();
	end
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = RecordDataManager.getIDState("item", nodeRecord);
	local bShow = bID and ItemChargesMC.usesChargesField(nodeRecord);
	WindowManager.callSafeControlUpdate(self, "charges", bReadOnly, not bShow);
end
