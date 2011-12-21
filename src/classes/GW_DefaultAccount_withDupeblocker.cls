global class GW_DefaultAccount_withDupeblocker extends GWBase.ONEN_DefaultAccount {

    global virtual override id newAcct() {
    	// the dupeblocker triggers here need to be turned off when dupeblocker is installed
    	// otherwise dupeblocker's tests cause recursion when this fires which leads to test failures
    	
    	account a = new Account( name = individualAcctName );
    	CRMfusionDBR101.DB_Globals.triggersDisabled = true;
	    insert a;
	    CRMfusionDBR101.DB_Globals.triggersDisabled = false;
    	return a.id;
    }


	// copied from ONEN_DefaultAccount & only here for the sake of test coverage so we can package this
	static testMethod void TestAccountAdd() {	
				 
		Contact firstContact = new Contact (
			FirstName='Joe',
			LastName='Johanssen_for_tests'			
		);
		insert firstContact;
		
		//the default Account should have been added to the contact
		Contact createdFirstContact = [select Account.Name from Contact where Id =:firstContact.id];
		System.assertEquals('IndividualAccountForTests', createdFirstContact.Account.Name);
	}
	

}