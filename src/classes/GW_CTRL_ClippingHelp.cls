/*-----------------------------------------------------------------------------------------------
* Written by Nicolas Campbell, copyright (c) 2011 Groundwire
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
*/
public with sharing class GW_CTRL_ClippingHelp {

	public Clipping_Settings__c clipsetting { get; set; }
	public string bookmarklink { get; set; }
	
	//consctuctor
	public GW_CTRL_ClippingHelp() { 
		clipsetting = Clipping_Settings__c.getInstance();
		if (clipsetting!=null) {
			bookmarklink = getBookmarkLink();
		} else {
			clipsetting = new Clipping_Settings__c();
		}
	}
	
	public PageReference save() {
		if (clipsetting.Clipping_Content_Field_Id__c.length() != 15 || clipsetting.Clipping_URL_Field_Id__c.length() != 15) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Field IDs must be 15 characters in length and are case sensitive.'));
		} else try {	
			upsert clipsetting;
			bookmarklink = getBookmarkLink();
		} catch(DmlException ex) {
			ApexPages.AddMessages(ex);
		}
		return null;
	}
	
	public string getBookmarkLink() {
		string link = 'javascript:location.href=\'' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + Clipping__c.SObjectType.getDescribe().getKeyPrefix() + '/e?retURL=%2F' + Clipping__c.SObjectType.getDescribe().getKeyPrefix() + '%2Fo&' + clipsetting.Clipping_URL_Field_ID__c + '=\'+encodeURIComponent(location.href)+\'&' + clipsetting.Clipping_Content_Field_ID__c + '=\'+encodeURIComponent((window.getSelection%20?%20window.getSelection()%20:%20document.getSelection%20?%20document.getSelection()%20:%20document.selection.createRange().text))+\'&Name=\'+encodeURIComponent(document.title)';
		return link;
	}
	
	/*------------------------------------------------------------------------------------
	* TESTS
	-------------------------------------------------------------------------------------*/	
	
	static testMethod void testClipping() {
		
		PageReference pageRef=Page.ClippingHelp;
		Test.setCurrentPage(pageRef);
        GW_CTRL_ClippingHelp controller = new GW_CTRL_ClippingHelp();
        
        //Salesforce ID must be 15 characters.
		controller.clipsetting.Clipping_URL_Field_Id__c = '123456789012345';
        controller.clipsetting.Clipping_Content_Field_ID__c = 'a';
        controller.save();
        system.assertEquals(1,ApexPages.getMEssages().size());
        
        controller.clipsetting.Clipping_Content_Field_ID__c = 'abcdefghijklmno';
        controller.save();
		
		//settings should be created, bookmark link should exist
		Clipping_Settings__c settinginstance = Clipping_Settings__c.getInstance();
        system.assert(settinginstance!=null);
        system.assert(controller.bookmarklink!=null);
	} 
}