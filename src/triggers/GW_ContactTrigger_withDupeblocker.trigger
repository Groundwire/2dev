trigger GW_ContactTrigger_withDupeblocker on Contact (after delete, after insert, after update, 
before insert, before update) {
	
	// this trigger needed when using dupeblocker to make DB tests pass
	
	if (trigger.isBefore) {
		GWBase.ONEN_DefaultAccount defAcct = new GW_DefaultAccount_withDupeblocker();
		defAcct.SetIndividualAccount();
	}
	
	if (trigger.isAfter) {
	   // update the primary contacts on affected accounts
	   GWBase.ONEN_AccountMaintenance am = new GW_AccountMaintenance_withDupeblocker();
	   am.SetPrimaryContacts(trigger.new, trigger.old, trigger.isInsert, trigger.isDelete);
	}	

}