trigger GW_AccountTrigger_withDupeblocker on Account (after update, before delete, before insert, 
before update) {

	// these triggers are required when dupeblocker is installed in order to make dupeblocker's tests pass

	if (trigger.isAfter && test.isRunningTest()) {
	   // update the primary contact for the account
	   GW_AccountMaintenance_withDupeblocker am = new GW_AccountMaintenance_withDupeblocker();
	   am.SetPrimaryContactForAccounts(trigger.new, trigger.old);	
	}
	
	if (trigger.isBefore && test.isRunningTest()) {
		
		// note that the protectindividualaccount trigger does not seem to trip up dupeblocker, so we haven't bothered to override this
		// but we have to include it here because the switch that turns off the setDefaultAccount trigger (which assigns the default account to contact w/o any)
		// also turns this trigger off, so we have to re-include it in the dupeblocker testing environment
		GWBase.ONEN_DefaultAccount defAcct = new GWBase.ONEN_DefaultAccount(); 
		defAcct.ProtectIndividualAccount();
	}

}