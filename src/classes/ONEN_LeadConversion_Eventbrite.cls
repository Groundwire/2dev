global with sharing class ONEN_LeadConversion_Eventbrite extends GWBase.ONEN_LeadConversion {
// to support eventbrite, this class overrides standard lead conversion to populate opps with Eventbrite data
// Written by Evan Callahan, copyright (c) 2010 Groundwire
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

 	global ONEN_LeadConversion_Eventbrite(integer leadLimit) {
		super(leadLimit);
	}
	
 /*
	global override void customOppProcessing (map<id, Opportunity> newOpps, map<id, Opportunity> oppFixes, map<id, contact> cMap, list<Database.leadConvertResult> lcrs) {

		// look for eventbrite data to copy to these opps
		GW_EventbriteOpportunities EO = new GW_EventbriteOpportunities();  
		EO.fillEventbriteOppDetails( newOpps, lcrs );
		EO.fillEventbriteOppDetails( oppFixes, lcrs );
	}
 */
}