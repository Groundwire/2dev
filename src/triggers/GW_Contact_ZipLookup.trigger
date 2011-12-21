trigger GW_Contact_ZipLookup on Contact (before insert, before update) {
	if (GWBase.GW_TriggerSettings.ts.GWBase__Enable_Zip_Lookup__c)
		GW_ZipLookup.ContactZipLookup();
}