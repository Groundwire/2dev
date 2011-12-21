public with sharing class GW_CTRL_viewAttachments {

	public list<Attachment> attachmentList { get; set; }
	public boolean sortDescending { get; private set; }
	private string lastSort;
	public string sortField { get; set; }
	
	public GW_CTRL_viewAttachments() {
		sortDescending=true;
		sortfield='LastModifiedDate';
		attachmentList = [ SELECT Id, IsDeleted, ParentId, Name, IsPrivate, ContentType, 
			BodyLength, OwnerId, CreatedDate, CreatedById, LastModifiedDate, 
			LastModifiedById, SystemModstamp, Description, CreatedBy.Name, Parent.Type, Parent.Name
			FROM Attachment ORDER BY LastModifiedDate DESC LIMIT 1000 ];
	} 
	
	public pagereference sort(){
		sortDescending = (sortField==lastSort) && !sortDescending;
		lastSort = sortField;
		
		attachmentList = database.query('SELECT Id, IsDeleted, ParentId, Name, IsPrivate, ContentType,'+
		'BodyLength, OwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp,'+
		'Description, CreatedBy.Name, Parent.Type, Parent.Name FROM Attachment ORDER BY '+
		sortField + (sortDescending?' DESC ':' ') + 'LIMIT 1000');
		return null;
	}
	
	 public static testmethod void testAttachments(){
	 	GW_CTRL_viewAttachments va = new GW_CTRL_viewAttachments();
	 	va.sort();
	 }
}