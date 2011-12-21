trigger GW_CampaignMember_Eventbrite on CampaignMember (after insert, after update) {
// if this is a paid event registration, copy opp fields back to the lead record 
// Written by Evan Callahan, copyright (c) 2010 Groundwire
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
/*
	list<lead> leadsWithEventPayments = new list<lead>();
	GW_EventbriteOpportunities EO;
	
	for (campaignMember cm : trigger.new) {
		if (cm.contactId == null && cm.ebConnector__Amount_Paid__c != null && cm.ebConnector__Amount_Paid__c != 0) {
			
			// instantiate the class only when we need it
			if (EO == null)	EO = new GW_EventbriteOpportunities();
			
			// build a lead record to update for this registration
			leadsWithEventPayments.add( EO.getLeadForUpdate( cm ) );
		}
	}
	
	if (!leadsWithEventPayments.isEmpty()) 
		update leadsWithEventPayments;
*/

	GW_EventbriteOpportunities gweo = new GW_EventbriteOpportunities();
	gweo.processPayments( trigger.new, ((trigger.isUpdate) ? trigger.oldMap : null) );
}