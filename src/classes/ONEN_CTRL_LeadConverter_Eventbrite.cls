global with sharing class ONEN_CTRL_LeadConverter_Eventbrite extends GWBase.ONEN_CTRL_LeadConverter {
// to support eventbrite, use this class in the lead converter page instead of the usual one
// Written by Evan Callahan, copyright (c) 2010 Groundwire
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

	global ONEN_CTRL_LeadConverter_Eventbrite() {
		super();
	}
	
/*
	global override GWBase.ONEN_LeadConversion getLeadConversionHelperClass(integer maxLeads) {
		return (new ONEN_LeadConversion_Eventbrite(maxLeads));
	}
*/
}