global class GW_AccountMaintenance_withDupeblocker extends GWBase.ONEN_AccountMaintenance {
   
   // overrides a key class in AccountMaintenance to avoid conflicts with dupeblocker
   // this class can and should only be installed when you have dupeblocker already installed	
   global override void  UpdateAccounts(list<Account> listAccts) { 
     CRMfusionDBR101.DB_Globals.triggersDisabled = true; 
     update listAccts; 
     CRMfusionDBR101.DB_Globals.triggersDisabled = false;
   }
   
   
   	global override id getIndAcctId() {
		// when dupeblocker is installed, we need to call the extension of the DefaultAccount class from this class
		//  so that the triggers get disabled when IndividualAccountForTests gets created
		GWBase.ONEN_DefaultAccount defAcct = new GW_DefaultAccount_withDupeblocker();
		return defAcct.getIndividualAccountIdNonStatic();
	}
   
   
    // this is part of the test that's in ONEN_AccountMaintenance
    // and included here only for the sake of test coverage, so we can package this class
	static testMethod void testAcctPrimaryContact() {
		
		Account testAcct;
	
		// try the function with no accts 
		GWBase.ONEN_AccountMaintenance am = new GW_AccountMaintenance_withDupeblocker();
		am.SetPrimaryContact(new Set<ID>());
	
		// first create two test accounts
		Id secondAcctId;
		Account firstAcct = new Account(Name='Blammo Corp');
		insert firstAcct;
		system.debug('Created account: ' + firstAcct.Id);
		Account secondAcct = new Account(Name='Funny Foundation');
		insert secondAcct;
		system.debug('Created account: ' + secondAcct.Id);
		
		// add a contact with a title in that account -- primary fields should get set
		Contact firstContact = new Contact (
			FirstName='Joe',
			LastName='Johanssen',
			Title='Head Honcho',
			AccountId=firstAcct.Id
		);
		insert firstContact;
		testAcct = [select id, name, GWBase__primary_contact__c from account where id=:firstAcct.Id];
		//SWA: that contact should now be the primary contact on the Account
		system.assertEquals(testAcct.GWBase__primary_contact__c, firstContact.id);
		//SWA: the Account should also show the title
			// MMS: deprecated
		// system.assertEquals(testAcct.primary_contact_title__c, 'Head Honcho');

		// add a contact without a title -- primary stays the same
		Contact secondContact = new Contact (
			FirstName='Cindy',
			LastName='LooHoo',
			AccountId=firstAcct.Id
		);
		insert secondContact;
		testAcct = [select id, name, GWBase__primary_contact__c from account where id=:firstAcct.Id];
		//SWA: first contact should still be primary contact
		system.assertEquals(testAcct.GWBase__primary_contact__c, firstContact.id);
		// MMS: deprecated
		//system.assertEquals(testAcct.primary_contact_title__c, 'Head Honcho');
				
		// delete the first contact -- primary changes to the second, title gets cleared
		delete firstContact;
		testAcct = [select id, name, GWBase__primary_contact__c from account where id=:firstAcct.Id];
		//SWA: second contact should now be primary on that Account, has no title
		system.assertEquals(testAcct.GWBase__primary_contact__c, secondContact.id);
		// MMS: deprecated
		// system.assertEquals(testAcct.primary_contact_title__c, null);
		
		// add a third contact -- primary stays the same
		Contact thirdContact = new Contact (
			FirstName='John',
			LastName='Baptist',
			AccountId=firstAcct.Id
		);
		insert thirdContact;
		testAcct = [select id, name, GWBase__primary_contact__c from account where id=:firstAcct.Id];
		//SWA: primary contact shouldn't change
		system.assertEquals(testAcct.GWBase__primary_contact__c, secondContact.id);
		
	
	}   
}