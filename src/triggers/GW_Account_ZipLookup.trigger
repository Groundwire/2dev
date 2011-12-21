trigger GW_Account_ZipLookup on Account (before insert, before update) {
	if (GWBase.GW_TriggerSettings.ts.GWBase__Enable_Zip_Lookup__c)
		GW_ZipLookup.AccountZipLookup(trigger.new);
}