global virtual class GW_WEBSVC_OnlinePayment {
/*-----------------------------------------------------------------------------------------------
* Written by Evan Callahan, copyright (c) 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101 
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
* Webservice version of the GW_OnlinePayments interface
* Use this class to insert online payments from a website
-----------------------------------------------------------------------------------------------*/	

	// instantiate the Groundwire online payments class
	static GW_OnlinePayment gwop = new GW_OnlinePayment(); 
	
	// array structure to store each item
	global virtual class Item {
		WebService string name; 
		// code is a product id
		WebService string code;
		WebService string discountcode;
		WebService integer quantity;
		WebService decimal amount;
		
		
		
		public OnlinePayment.Item convertItem {
			get { return (new OnlinePayment.Item( name, code, discountcode, quantity, amount )); }
		}
	}

	// data structure to pass in and return payment data
	global virtual class PaymentInfo {

		// payer data
		WebService string payerId;
		WebService string email;
		WebService string firstName;
		WebService string lastName;
		WebService string companyName;
		WebService string street;
		WebService string city;
		WebService string state;
		WebService string zip;
		WebService string country;
		WebService string phone;
		WebService boolean companyIsPayer;		// if both contact and account are set, this determines 
												// whether opp should be org or individual
		// payment data
		WebService OnlinePayment.Processor pmtProcessor;
		WebService OnlinePayment.PaymentType pmtType;
	 	WebService OnlinePayment.PaymentStatus pmtStatus;
		WebService string priceBook;
		WebService string txnId;
		WebService string parentTxnId;   // for refund or reversal
		WebService string cardType;
		WebService string last4digits;
		WebService string currencyCode;
		WebService decimal exchangeRate;
		WebService decimal totalAmount;
		WebService decimal fee;
		WebService decimal tax;
		WebService decimal shipping;
		WebService List<Item> itemList;
		WebService string invoice;
		WebService string reasonCode;
		WebService string memo; 
		
		// use the paymentResponse field to pass along the complete response from the processor
		// this could be XML, JSON, plain text, or a set of name/value pairs
		WebService string paymentResponse;
	
		// use the custom field to pass additional details you need, such as the campaign for the opportunity
		// in our GW processor, you can pass JSON in this property to set any custom fields in Salesforce
		WebService string custom;
	
		// properties for recurring payment, pledge, or subscription
		WebService string recurringTxnId;  
		WebService OnlinePayment.RecurringPeriod pmtPeriod;
		WebService integer frequency;			// combine with period above, e.g. every 1 Month
		WebService integer occurrences;
		WebService date startDate;
	
		// you can set these to existing objects, or use the setPayer method to match or create the payer
		WebService id contactId;
		WebService id accountId;
	
		// after a successful call to one of the methods, this will be set to the associated opportunity
		WebService id opportunityId;
	
		// contains a code indicating the result of trying to match to a contact or account
		WebService OnlinePayment.MatchResult payerMatchResult;
	}

	// array structure to provide the response back
	global virtual class Response {
		WebService boolean success; 
		WebService PaymentInfo payment;
		WebService string errorMessage;
	}

	// METHODS FOR PROCESSING PAYMENTS

	// calling setPayer is always optional, becuase the other methods will each call it
	// it is exposed so that you can run separately and see the result if you need to
	WebService static Response setPayer( PaymentInfo payment ) {
		Response resp = new Response();
		try {
			setProps( payment );
			resp.success = gwop.setPayer();
			getProps( payment );
		} catch (exception e) {
			resp.success = false;
			resp.errorMessage = e.getMessage();
		}
		logNotification( payment, 'Cancel Subscription', resp.success );
		resp.payment = payment;
		return resp;
	}	

	WebService static Response processSinglePayment( PaymentInfo payment ) {
		Response resp = new Response();
		try {
			setProps( payment );
			resp.success = gwop.processSinglePayment();
			getProps( payment );
		} catch (exception e) {
			resp.success = false;
			resp.errorMessage = e.getMessage();
		}
		logNotification( payment, 'Cancel Subscription', resp.success );
		resp.payment = payment;
		return resp;
	}

	WebService static Response startRecurringPayments( PaymentInfo payment ) {
		Response resp = new Response();
		try {
			setProps( payment );
			resp.success = gwop.startRecurringPayments();
			getProps( payment );
		} catch (exception e) {
			resp.success = false;
			resp.errorMessage = e.getMessage();
		}
		logNotification( payment, 'Cancel Subscription', resp.success );
		resp.payment = payment;
		return resp;
	}	
	
	WebService static Response processRecurringPayment( PaymentInfo payment ) {
		Response resp = new Response();
		try {
			setProps( payment );
			resp.success = gwop.processRecurringPayment();
			getProps( payment );
		} catch (exception e) {
			resp.success = false;
			resp.errorMessage = e.getMessage();
		}
		logNotification( payment, 'Cancel Subscription', resp.success );
		resp.payment = payment;
		return resp;
	}

	WebService static Response cancelRecurringPayments( PaymentInfo payment ) {
		Response resp = new Response();
		try {
			setProps( payment );
			resp.success = gwop.cancelRecurringPayments();
			getProps( payment );
		} catch (exception e) {
			resp.success = false;
			resp.errorMessage = e.getMessage();
		}
		logNotification( payment, 'Cancel Subscription', resp.success );
		resp.payment = payment;
		return resp;
	}

	global static void logNotification( PaymentInfo payment, string action, boolean processed ) {

		// create a payment record for the log
		Payment_Notification__c ipn = new Payment_Notification__c (
			Name = 'Webservice Call' + ((action != null) ? '' : (' - ' + action)) + ((payment.email == null) ? '' : (' for ' + payment.email)),
			notification_type__c = 'Webservice Call',
			Payment_Status__c = ( 
				(payment.pmtStatus == OnlinePayment.PaymentStatus.COMPLETED) ? 'Completed' :
				(payment.pmtStatus == OnlinePayment.PaymentStatus.AUTHORIZED) ? 'Authorized' :
				(payment.pmtStatus == OnlinePayment.PaymentStatus.PENDING) ? 'Pending' :
				(payment.pmtStatus == OnlinePayment.PaymentStatus.DECLINED) ? 'Declined' :
				(payment.pmtStatus == OnlinePayment.PaymentStatus.REVERSED) ? 'Reversed' : 'Failed'),
			Transaction_Id__c = payment.txnId,
			IsTest__c = false,
			Recurring_Transaction_Id__c = payment.recurringTxnId,
			Payer_Email__c = payment.email,
			Payer_ID__c = payment.payerId,
			Payment_Amount__c = payment.totalAmount,
			parameters__c = payment.paymentResponse,
			IsProcessed__c = processed,
			opportunity__c = payment.opportunityId
		);

		// get the first item, if any
		if (payment.itemList != null && !payment.itemList.isEmpty()) {
			ipn.item_name__c = payment.itemList[0].name;
			ipn.item_number__c = payment.itemList[0].code;
		} 	 

		insert ipn; 
	}

	// method that sets the webservice properties on the online payment class
	global static void setProps( PaymentInfo payment ) {
		gwop.payerId = payment.payerId;
		gwop.email = payment.email;
		gwop.firstName = payment.firstName;
		gwop.lastName = payment.lastName;
		gwop.companyName = payment.companyName;
		gwop.street = payment.street;
		gwop.city = payment.city;
		gwop.state = payment.state;
		gwop.zip = payment.zip;
		gwop.country = payment.country;
		gwop.phone = payment.phone;
		if (gwop.companyIsPayer == null) gwop.companyIsPayer = payment.companyIsPayer;
		
		gwop.pmtProcessor = payment.pmtProcessor;
		gwop.pmtType = payment.pmtType;
 		gwop.pmtStatus = payment.pmtStatus; 
		gwop.txnId = payment.txnId;
		gwop.parentTxnId = payment.parentTxnId;  // for refund or reversal
		gwop.cardType = payment.cardType;
		gwop.last4digits = payment.last4digits;
		gwop.currencyCode = payment.currencyCode;
		gwop.exchangeRate = payment.exchangeRate;
		gwop.totalAmount = payment.totalAmount;
		gwop.fee = payment.fee;
		gwop.tax = payment.tax; 
		gwop.shipping = payment.shipping;
		gwop.invoice = payment.invoice;
		gwop.reasonCode = payment.reasonCode;
		gwop.memo = payment.memo;  
		
		if (gwop.itemList.isEmpty() && payment.itemList != null) {
			for (Item itm : payment.itemList)
				gwop.itemList.add(itm.convertItem);
		}
		gwop.custom = payment.custom;
		gwop.recurringTxnId = payment.recurringTxnId;
		gwop.pmtPeriod = payment.pmtPeriod;
		gwop.frequency = payment.frequency;		// combine with period above, e.g. every 1 Month
		gwop.occurrences = payment.occurrences;
		gwop.startDate = payment.startDate;
		if (gwop.contactId == null) gwop.contactId = payment.contactId;
		if (gwop.accountId == null) gwop.accountId = payment.accountId;		
	}
	
	// methods that get back properties from the class
	global static void getProps( PaymentInfo payment ) {
		payment.payerId = gwop.payerId;
		payment.companyIsPayer = gwop.companyIsPayer;
		payment.payerMatchResult = gwop.payerMatchResult;	
		payment.txnId = gwop.txnId;
		payment.parentTxnId = gwop.parentTxnId;
		payment.recurringTxnId = gwop.recurringTxnId;  
		payment.contactId = gwop.contactId;
		payment.accountId = gwop.accountId;		
		payment.opportunityId = gwop.opportunityId;		
	}

	// TESTS
	static testMethod void testSetPayer() {
		GW_WEBSVC_OnlinePayment.PaymentInfo p = new GW_WEBSVC_OnlinePayment.paymentInfo();
		p.firstname = 'EvanTest';
		p.lastname = 'CallahanTest';
		p.email = 'evantest@groundwiretest.org';
		GW_WEBSVC_OnlinePayment.Response resp = GW_WEBSVC_OnlinePayment.setPayer( p );
		system.assert(resp.success, 'setPayer returned fail');
		system.assertEquals(OnlinePayment.MatchResult.NEW_CONTACT, p.payerMatchResult);	
	}

	static testMethod void testSinglePayment() {
		insert new Contact(firstName = 'EvanTest', lastName = 'CallahanTest', 
			email = 'evantest@groundwiretest.org');
		
		test.startTest();
		
        // set default setting for matching
        gwop.opSettings.Dont_Match_Contacts_by_Email__c = false;
                
		GW_WEBSVC_OnlinePayment.PaymentInfo p = new GW_WEBSVC_OnlinePayment.PaymentInfo();
		p.firstname = 'EvanTest';
		p.lastname = 'CallahanTest';
		p.email = 'evantest@groundwiretest.org';
		p.txnId = 'X0X0X';
		p.totalAmount = 1234;
		
		GW_WEBSVC_OnlinePayment.Item i = new GW_WEBSVC_OnlinePayment.Item();
		i.name = GWBase.ONEN_Constants.OPP_DEFAULT_RECTYPE_FORTESTS;
		i.amount = 1234;
		p.itemList = new list<GW_WEBSVC_OnlinePayment.Item>{ i };
		
		GW_WEBSVC_OnlinePayment.Response resp = GW_WEBSVC_OnlinePayment.processSinglePayment( p );
		system.assertEquals(OnlinePayment.MatchResult.CONTACT_MATCH, p.payerMatchResult);	
		system.assert(resp.success, 'processSinglePayment returned fail');
		
		// look for the opp
		GWBase__oppPayment__c[] op0 = [select id, GWBase__paid__c, GWBase__amount__c, GWBase__isinstallment__c from GWBase__oppPayment__c 
			where GWBase__opportunity__r.Online_Transaction_Id__c = 'X0X0X'];
		system.assertEquals(1, op0.size(), 'no opp with the specified txnid');			
	}

	static testMethod void testRecurring() {
		insert new Contact(firstName = 'EvanTest', lastName = 'CallahanTest', 
			email = 'evantest@groundwiretest.org');
		
		test.startTest();
		
		GW_WEBSVC_OnlinePayment.PaymentInfo p = new GW_WEBSVC_OnlinePayment.PaymentInfo();
		p.firstname = 'EvanTest';
		p.lastname = 'CallahanTest';
		p.email = 'evantest@groundwiretest.org';
		p.txnId = 'X0X0X';
		p.totalAmount = 1234;
		p.pmtPeriod = OnlinePayment.RecurringPeriod.MONTH;
		p.frequency = 1;
		p.recurringTxnId = 'Y0Y0Y';
		p.phone = '(123) 555-1212';
		
		GW_WEBSVC_OnlinePayment.Item i = new GW_WEBSVC_OnlinePayment.Item();
		i.name = GWBase.ONEN_Constants.OPP_DEFAULT_RECTYPE_FORTESTS;
		i.amount = 1234;
		p.itemList = new list<GW_WEBSVC_OnlinePayment.Item>{ i };
		
		// set up the payments
		GW_WEBSVC_OnlinePayment.Response resp = GW_WEBSVC_OnlinePayment.startRecurringPayments( p );
		system.assert(resp.success, 'startRecurringPayments returned fail');
		
		string rtid = p.recurringTxnId;
		system.assert(rtid != null, 'No recurring txn id.');

		// look for the payment
		GWBase__oppPayment__c[] op0 = [select id, GWBase__paid__c, GWBase__amount__c, GWBase__isinstallment__c from GWBase__oppPayment__c 
			where GWBase__opportunity__r.GWBase__recurring_payment_profile__r.GWBase__Transaction_Id__c = 'Y0Y0Y' order by GWBase__date__c];
		system.assert(op0.size() > 0, 'no payments found');			
		system.assertEquals(false, op0[0].GWBase__paid__c, 'paid is set when it should not be');			
		
		// log an authorized payment
		p.pmtStatus = OnlinePayment.PaymentStatus.AUTHORIZED;
		resp = GW_WEBSVC_OnlinePayment.processRecurringPayment( p );
		system.assert(resp.success, 'processRecurringPayment returned fail on create/authorize');
		
		// look for the payment
		GWBase__oppPayment__c[] op2 = [select id, GWBase__paid__c, GWBase__amount__c, GWBase__isinstallment__c from GWBase__oppPayment__c 
			where GWBase__opportunity__r.GWBase__recurring_payment_profile__r.GWBase__Transaction_Id__c = 'Y0Y0Y' order by GWBase__date__c];
		system.assertEquals(false, op2[0].GWBase__paid__c, 'paid is set when it should not be');			
		
		// log actual payment success
		p.pmtStatus = OnlinePayment.PaymentStatus.COMPLETED;
		resp = GW_WEBSVC_OnlinePayment.processRecurringPayment( p );
		system.assert(resp.success, 'processRecurringPayment returned fail on fulfilled payment');
		
		// look for the payment
		GWBase__oppPayment__c[] op3 = [select id, GWBase__paid__c, GWBase__amount__c, GWBase__isinstallment__c from GWBase__oppPayment__c 
			where GWBase__opportunity__r.GWBase__recurring_payment_profile__r.GWBase__Transaction_Id__c = 'Y0Y0Y' order by GWBase__date__c];
		system.assertEquals(true, op3[0].GWBase__paid__c, 'paid is not set properly');			

		// cancel the rest
		resp = GW_WEBSVC_OnlinePayment.cancelRecurringPayments( p );
		system.assert(resp.success, 'cancelRecurringPayments returned fail');
		// look for the payment
		Opportunity[] op4 = [select id from Opportunity 
			where GWBase__recurring_payment_profile__r.GWBase__Transaction_Id__c = 'Y0Y0Y' and isClosed = false];
		system.assertEquals(0, op4.size(), 'unpaid payments exist on canceled subscr');		
	}
}