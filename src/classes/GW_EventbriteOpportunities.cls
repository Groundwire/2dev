global class GW_EventbriteOpportunities {
/*-----------------------------------------------------------------------------------------------
* Written by Evan Callahan, copyright (c) 2010 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
* 
* class that creates opportunities for eventbrite ticket payments
* uses custom settings for options
* new leads from Eventbrite get opp data populated in response to the CampaignMember 
*    insert trigger, then an extension to the lead conversion class fills the rest of the 
*    opp fields for new event registration opps
-----------------------------------------------------------------------------------------------*/

	public string oppRecTypeName;
	public id oppRecTypeId;
	public string oppContactRole;
	public string oppStageName; 
	
	// constructor - gets settings
	public GW_EventbriteOpportunities() {
        Eventbrite_Opp_Settings__c eoSettings = Eventbrite_Opp_Settings__c.getInstance();
		if (eoSettings == null || test.isRunningTest()) {
			eoSettings = new Eventbrite_Opp_Settings__c();
			eoSettings.Create_Opportunities__c = true;
			eoSettings.Create_Opportunities__c = false;
			eoSettings.Opportunity_Record_Type__c = 'Event Registration';
			eoSettings.Stage_Name__c = 'Closed Won';
			eoSettings.Contact_Role__c = 'Registrant';
		}	
		
		oppContactRole = eoSettings.Contact_Role__c;
		oppStageName = (oppStageName == null) ? 'Closed Won' : eoSettings.Stage_Name__c;
		
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.DescribeSObjectResult d = gd.get('Opportunity').getDescribe();
		Map<String,Schema.RecordTypeInfo> oppRecordTypesByName = d.getRecordTypeInfosByName();
		oppRecTypeName = 
			(oppRecordTypesByName.containsKey(eoSettings.Opportunity_Record_Type__c)) ? 
				eoSettings.Opportunity_Record_Type__c : 
			(oppRecordTypesByName.containsKey(GWBase.ONEN_Constants.OPP_DEFAULT_RECTYPE_CONTACT)) ?
				GWBase.ONEN_Constants.OPP_DEFAULT_RECTYPE_CONTACT : null;
		oppRecTypeId = (oppRecordTypesByName.containsKey(oppRecTypeName)) ?
			oppRecordTypesByName.get(oppRecTypeName).getRecordTypeId() : null;
	}	
/*	
	// when a registration is inserted, we need to update the lead record with basic info
	public lead getLeadForUpdate( campaignMember cm ) {
		return new lead(
			id = cm.leadId,
			GWBase__opportunity_amount__c = cm.ebConnector__Amount_Paid__c,
			GWBase__opportunity_date__c = (cm.ebConnector__Attendee_Created_Date__c == null) ? null : cm.ebConnector__Attendee_Created_Date__c.date(),
			GWBase__opportunity_record_type__c = oppRecTypeName,
			GWBase__opportunity_stage__c = oppStageName,			
			GWBase__opportunity_description__c = 'Eventbrite order # ' + cm.ebConnector__Order_ID__c +
				((cm.ebConnector__Event_ID__c == null) ? '' : '\nEvent ID: ' + cm.ebConnector__Event_ID__c) +
				((cm.ebConnector__Ticket_ID__c == null) ? '' : '\nTicket ID: ' + cm.ebConnector__Ticket_ID__c) +
				((cm.ebConnector__Quantity__c == null) ? '' : '\nNumber of tickets: ' + cm.ebConnector__Quantity__c) +
				((cm.ebConnector__Event_Date__c == null) ? '' : '\nEvent date: ' + cm.ebConnector__Event_Date__c) +
				((cm.ebConnector__Order_Type__c == null) ? '' : '\nPayment type: ' + cm.ebConnector__Order_Type__c) +
				((cm.ebConnector__Discount__c == null) ? '' : '\nDiscount: ' + cm.ebConnector__Discount__c) +
				((cm.ebConnector__Notes__c == null) ? '' : '\n\nNotes:\n' + cm.ebConnector__Notes__c)
		);
	}
*/	
	public void processPayments(list<campaignMember> cms, map<id, campaignMember> oldMap) {
		
		// compile the list of new eventbrite attendees
		list<campaignMember> attendees = new list<campaignMember>(); 
		set<string> orderIds = new set<string>();
		set<string> contactIds = new set<string>();
		
		for (campaignMember cm : cms) {
			// looking for those with an eventbrite order id that did not have that id before
			if (cm.contactId != null && cm.ebConnector__Order_ID__c != null &&
				cm.ebConnector__Amount_Paid__c != null && cm.ebConnector__Amount_Paid__c > 0 &&
				(oldMap == null || cm.ebConnector__Order_ID__c != oldMap.get(cm.id).ebConnector__Order_ID__c)) {
			
				orderIds.add( cm.ebConnector__Order_ID__c );
				contactIds.add( cm.contactId );
				attendees.add( cm );
			}
		}
							
		// compile the set of order/contact combinations already in the database
		set<string> orderKeyset = new set<string>();
		for (opportunityContactRole ocr : 
			[select contactId, opportunity.eventbrite_id__c
				from opportunityContactRole
				where opportunity.eventbrite_id__c in : orderIds
				and contactId in :contactIds
				and isPrimary = true limit 1000] ) {
					
			orderKeyset.add(ocr.opportunity.eventbrite_id__c + ocr.contactId);
		}

		// get the contact names to use in the opp names					
		map<id, contact> contactMap = new map<id, contact>(
			[select id, name from contact where id in :contactIds] );

		// create the opps
		list<opportunity> opps = new list<opportunity>(); 
		for (campaignMember cm : attendees) {
			// avoid duplicates
			if (!orderKeyset.contains( cm.ebConnector__Order_ID__c + cm.contactId )) {
					
				// add this one to the set
				orderKeyset.add( cm.ebConnector__Order_ID__c + cm.contactId );
					
				opportunity o = new Opportunity(
					campaignId = cm.campaignId,
					stagename = oppStageName,
					GWBase__cr_contact_id__c = cm.contactId,
					GWBase__CR_Contact_Role__c = OppContactRole,
					Type = cm.ebConnector__Order_Type__c,
					eventbrite_id__c = cm.ebConnector__Order_ID__c,
					event_date__c = (cm.ebConnector__Event_Date__c == null) ? null : cm.ebConnector__Event_Date__c.date(),
					number_of_tickets__c = cm.ebConnector__Quantity__c,
					eventbrite_link__c = cm.ebConnector__Order_URL__c,
					amount = cm.ebConnector__Amount_Paid__c,
					closeDate = (cm.ebConnector__Attendee_Created_Date__c == null) ? system.today() : cm.ebConnector__Attendee_Created_Date__c.date(),
					recordTypeId = oppRecTypeId,
					description = 'Eventbrite order # ' + cm.ebConnector__Order_ID__c +
						((cm.ebConnector__Event_ID__c == null) ? '' : '\nEvent ID: ' + cm.ebConnector__Event_ID__c) +
						((cm.ebConnector__Ticket_ID__c == null) ? '' : '\nTicket ID: ' + cm.ebConnector__Ticket_ID__c) +
						((cm.ebConnector__Quantity__c == null) ? '' : '\nNumber of tickets: ' + cm.ebConnector__Quantity__c) +
						((cm.ebConnector__Event_Date__c == null) ? '' : '\nEvent date: ' + cm.ebConnector__Event_Date__c) +
						((cm.ebConnector__Order_Type__c == null) ? '' : '\nPayment type: ' + cm.ebConnector__Order_Type__c) +
						((cm.ebConnector__Discount__c == null) ? '' : '\nDiscount: ' + cm.ebConnector__Discount__c) +
						((cm.ebConnector__Notes__c == null) ? '' : '\n\nNotes:\n' + cm.ebConnector__Notes__c)
				);

				// add the opp name
				o.name = GWBase.ONEN_OpportunityMaintenance.oppName(o, contactMap.get(cm.contactId).Name, false);

				// optional multicurrency support
				try { 
					o.put('CurrencyISOCode', cm.ebConnector__Currency__c);
				} catch (exception e) {}

				opps.add(o);
			}
		}
		if (!opps.isEmpty()) insert opps;
	}
/*
	// method to walk through a set of lead converted opps and add eventbrite details
	public void fillEventbriteOppDetails(map<id, opportunity> oppMap, list<Database.leadConvertResult> lcrs) {
		
		// get the set of campaign ids for these opps
		set<id> cmpIds = new set<id>();
		set<id> conIds = new set<id>();
		
		// also map the campaign/contact id combos to their opps
		map<string, opportunity> newOppMap = new map<string, opportunity>();
		
		// walk through all leads looking for an opp and grab its campaign
		for (Database.leadConvertResult lcr : lcrs) { 		
			if (lcr.isSuccess() && oppMap.containsKey(lcr.getLeadId())) {
				
				// get this campaign id into the list
				opportunity o = oppMap.get(lcr.getLeadId());

			system.debug(logginglevel.warn, o.recordtypeid);
				
				//system.assertequals( oppRecTypeId, o.recordTypeId);
				system.assert(o.campaignId != null);
				system.assert(o.GWBase__cr_contact_Id__c != null);
				if (o.recordTypeId == oppRecTypeId && o.campaignId != null && o.GWBase__cr_contact_Id__c != null) {
					cmpIds.add(o.campaignId);
					conIds.add(o.GWBase__cr_contact_Id__c);
					
					// map this new opp for update
					newOppMap.put(o.campaignId + o.GWBase__cr_contact_Id__c, o);
				}
			}
		}
		//system.debug(lcrs);
		//system.debug(oppMap);
		//system.debug(newOppMap);
		//system.debug(cmpIds);
		//system.debug(conIds);
		
		// query for all the campaign member data that we might need 						
		for (campaignMember cm:  
				[select id, campaignId, contactId, ebConnector__Quantity__c,
					ebConnector__Order_ID__c, ebConnector__Event_Date__c,
					ebConnector__Order_URL__c, ebConnector__Event_ID__c,
					ebConnector__Ticket_ID__c, ebConnector__Discount__c, 
					ebConnector__Order_Type__c,  ebConnector__Notes__c
					from campaignMember
					where campaignId in : cmpIds
					and contactId in :conIds
					and ebConnector__Amount_Paid__c != null 
					limit 1000] ) {
			
			string memberCode = ((string)(cm.campaignId)) + ((string)(cm.contactId));
			
			if (newOppMap.containsKey(memberCode)) {
		
				opportunity o = newOppMap.get(memberCode);
				o.stagename = oppStageName;
				o.Type = cm.ebConnector__Order_Type__c;
				o.eventbrite_id__c = cm.ebConnector__Order_ID__c;
				o.event_date__c = (cm.ebConnector__Event_Date__c == null) ? null : cm.ebConnector__Event_Date__c.date();
				o.number_of_tickets__c = cm.ebConnector__Quantity__c;
				o.eventbrite_link__c = cm.ebConnector__Order_URL__c;
				if (OppContactRole != null && o.GWBase__CR_Contact_ID__c != null) o.GWBase__CR_Contact_Role__c = OppContactRole;
				// optional multicurrency support
				try { 
					o.put('CurrencyISOCode', cm.ebConnector__Currency__c);
				} catch (exception e) {}
			} 
		}
	}

    static testMethod void testEventbriteLeadOpps() {
	
		// create and convert leads with EB payment data
		Campaign c1 = new Campaign(name='Test Eventbrite Campaign 1');
		insert c1;
		Lead[] TestLeads = new Lead[] {
			new Lead(LastName='Test Lead 1', leadsource='Eventbrite'),
			new Lead(LastName='Test Lead 2', firstname='Bob', leadsource='Eventbrite'),
			new Lead(LastName='Test Lead 3', firstname='Joe', email='joe_test@testlead.org', leadsource='Eventbrite')
		};
		insert TestLeads;
		CampaignMember[] TestCMs = new CampaignMember[] {
			new CampaignMember(
				campaignId = c1.id,
				status = 'Sent', 
				LeadId = TestLeads[0].id,
				ebConnector__Amount_Paid__c = 50,
				ebConnector__Attendee_Created_Date__c = system.now().adddays(-7),
				ebConnector__Order_Type__c = 'Paypal',
				ebConnector__Event_ID__c = '123456',
				ebConnector__Ticket_ID__c = '123456',
				ebConnector__Order_ID__c = '123456',
				ebConnector__Event_Date__c = system.today().adddays(7),
				ebConnector__Quantity__c = 1
			),
			new CampaignMember(
				campaignId = c1.id, 
				status = 'Sent', 
				LeadId = TestLeads[1].id,
				ebConnector__Amount_Paid__c = 50,
				ebConnector__Attendee_Created_Date__c = system.now().adddays(-7),
				ebConnector__Order_Type__c = 'Paypal',
				ebConnector__Event_ID__c = '123456',
				ebConnector__Ticket_ID__c = '123456',
				ebConnector__Order_ID__c = '123456',
				ebConnector__Event_Date__c = system.today().adddays(7),
				ebConnector__Quantity__c = 1
			),
			new CampaignMember(
				campaignId = c1.id, 
				status = 'Sent', 
				LeadId = TestLeads[2].id,
				ebConnector__Amount_Paid__c = 7272.89,
				ebConnector__Attendee_Created_Date__c = system.now().adddays(-7),
				ebConnector__Order_Type__c = 'Paypal',
				ebConnector__Event_ID__c = '123456',
				ebConnector__Ticket_ID__c = '123456',
				ebConnector__Order_ID__c = '123456',
				ebConnector__Event_Date__c = system.today().adddays(7),
				ebConnector__Quantity__c = 10
			)
		};
				
		// prepare to convert leads
		// insert a contact
		contact tc = new contact(lastname = 'Test Contact', email='joe_test@testlead.org'); 
		insert tc;

		// simulate the EB connector, which creates campaign memberships
		insert testCMs;
		
		// did they get the donation data?
		system.assertEquals(1, [select count() from lead where GWBase__opportunity_amount__c = 7272.89 and GWBase__opportunity_date__c = : system.today().adddays(-7)]);
		Test.StartTest();		
		
		// load the page
		Test.setCurrentPageReference( Page.LeadConverterEB );
		ONEN_CTRL_LeadConverter_Eventbrite controller = new ONEN_CTRL_LeadConverter_Eventbrite();
		
		// get the leads
		controller.leadsource = 'Eventbrite';
		List<GWBase.ONEN_CTRL_LeadConverter.LeadResult> leadList = controller.getResults();
		List<SelectOption> cMatches = leadList[0].getMatches();
		List<SelectOption> oMatches = leadList[0].getOMatches();
		List<SelectOption> oRTs = leadList[0].getORecTypes();
		List<SelectOption> aMatches = leadList[0].getAMatches();

		// do the conversions
		for (GWBase.ONEN_CTRL_LeadConverter.LeadResult lr : leadList)
			if (lr.getLead().lastName.startsWith('Test Lead ')) 
				lr.selected = true;
		controller.convertLeads();
		list<GWBase.ONEN_CTRL_LeadConverter.ConvertedLead> cvns = controller.getConversions();
		
		// did they work?		
		system.assert(cvns != null && !cvns.isEmpty());
		system.assertEquals(cvns[0].success, true); 
		system.assert(cvns[0].oppid != null);
		test.stoptest();
		
		// did we get opps with roles and eventbrite data?
		opportunityContactRole[] ocrs = 
			[select contactId, opportunity.eventbrite_id__c, opportunity.name, opportunity.recordtype.name, 
					opportunity.description, opportunity.closedate 
					from opportunityContactRole
					where opportunity.campaignid = : c1.id
					and isPrimary = true limit 1000];
		
		system.debug(ocrs);
		System.AssertEquals ( 3 , ocrs.size() );
		system.assertequals ( system.today().adddays(-7), ocrs[0].opportunity.closedate );
		system.assertEquals ( 'Event Registration', ocrs[0].opportunity.recordtype.name);
		system.assertequals ( '123456', ocrs[0].opportunity.eventbrite_id__c );
		
	}
*/
    static testMethod void testEventbriteCampaignMemberOpps() {
	
		// create and convert leads with EB payment data
		Campaign c1 = new Campaign(name='Test Eventbrite Campaign 1');
		insert c1;
		contact[] TestCons = new contact[] {
			new contact(LastName='Test Contact 1'),
			new contact(LastName='Test Contact 2', firstname='Bob'),
			new contact(LastName='Test Contact 3', firstname='Joe', email='joe_test@testcon.org')
		};
		insert TestCons;
		CampaignMember[] TestCMs = new CampaignMember[] {
			new CampaignMember(
				campaignId = c1.id,
				status = 'Sent', 
				ContactId = TestCons[0].id,
				ebConnector__Amount_Paid__c = 50,
				ebConnector__Attendee_Created_Date__c = system.now().adddays(-7),
				ebConnector__Order_Type__c = 'Paypal',
				ebConnector__Event_ID__c = '123456',
				ebConnector__Ticket_ID__c = '123456',
				ebConnector__Order_ID__c = '123456',
				ebConnector__Event_Date__c = system.today().adddays(7),
				ebConnector__Quantity__c = 1
			),
			new CampaignMember(
				campaignId = c1.id, 
				status = 'Sent', 
				ContactId = TestCons[1].id,
				ebConnector__Amount_Paid__c = 50,
				ebConnector__Attendee_Created_Date__c = system.now().adddays(-7),
				ebConnector__Order_Type__c = 'Paypal',
				ebConnector__Event_ID__c = '123456',
				ebConnector__Ticket_ID__c = '123456',
				ebConnector__Order_ID__c = '123456',
				ebConnector__Event_Date__c = system.today().adddays(7),
				ebConnector__Quantity__c = 1
			),
			new CampaignMember(
				campaignId = c1.id, 
				status = 'Sent', 
				ContactId = TestCons[2].id
			)
		};
				
		// simulate the EB connector, which creates campaign memberships
		Test.StartTest();				
		insert testCMs;

		// it also updates existing ones if it finds a matching contact
		update(	new CampaignMember(
			id = testCMs[2].id, 
			ebConnector__Amount_Paid__c = 7272.89,
			ebConnector__Attendee_Created_Date__c = system.now().adddays(-7),
			ebConnector__Order_Type__c = 'Paypal',
			ebConnector__Event_ID__c = '123456',
			ebConnector__Ticket_ID__c = '123456',
			ebConnector__Order_ID__c = '123456',
			ebConnector__Event_Date__c = system.today().adddays(7),
			ebConnector__Quantity__c = 10
		));
		
		test.stoptest();
		
		// did we get opps with roles and eventbrite data?
		opportunityContactRole[] ocrs = 
			[select contactId, role, opportunity.eventbrite_id__c, opportunity.name, opportunity.recordtype.name, 
					opportunity.description, opportunity.closedate, opportunity.amount 
					from opportunityContactRole
					where opportunity.campaignid = : c1.id
					and isPrimary = true order by opportunity.amount limit 1000];
		
		system.debug(ocrs);
		System.AssertEquals ( 3 , ocrs.size() );
		system.assertequals ( system.today().adddays(-7), ocrs[0].opportunity.closedate );
		system.assertEquals ( 'Event Registration', ocrs[0].opportunity.recordtype.name);
		system.assertequals ( '123456', ocrs[0].opportunity.eventbrite_id__c );
		system.assertequals ( 'Registrant', ocrs[0].role );
		system.assertequals ( 7272.89, ocrs[2].opportunity.amount );
		
	}

}