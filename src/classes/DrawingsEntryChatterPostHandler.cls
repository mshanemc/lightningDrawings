public with sharing class DrawingsEntryChatterPostHandler {

  //pass in trigger new.map (feedItems)

 public static void handleItems (map<id, feeditem> original){
	//@future
  //public static void handleItems (string input){
  	//list<id> originalList = (list<id>)JSON.deserialize(input, list<id>.class);

  	//map<id, feedItem> original = new map<id, feedItem>([select id, ParentId from feedItem where id in: originalList]);
  	//list<feedItem> original = [select id, ParentId from FeedItem where id in: originalList];

  	List<FeedAttachment> attachments =  [SELECT RecordId, Id, Title, Type, FeedEntityId
                                         FROM FeedAttachment
                                         WHERE FeedEntityId IN : original.keySet() ];

    if (attachments.size()==0) return;

    //filter out stuff not related to the contact;
    list<relationshipTableRow> Rows = new list<relationshipTableRow>();
    list<id> contacts = new list<id>();
    list<id> documents = new list<id>();

	  for (FeedAttachment attachment : attachments) {
			FeedItem fi = original.get(attachment.FeedEntityId);
	    if (attachment.Type == 'Content' && fi.ParentId.getSobjectType()==Schema.Contact.SObjectType){
    		contacts.add(fi.ParentId);

    		documents.add(attachment.RecordId);
    		system.debug(attachment.RecordId);

    		relationshipTableRow RTR = new relationshipTableRow();

    		RTR.cvId = attachment.RecordId;
    		RTR.contactId = fi.ParentId;

    		Rows.add(RTR);
	    }
	  }
    if (Rows.size()==0) return;

	  system.assert(documents.size()>0, 'No Documents were added to the documents list!');

	  list<ContentVersion> cvs = [select Id, ContentDocumentId, VersionData, FileType from ContentVersion where Id in: documents and IsLatest = true];
	  system.assert(cvs.size()>0, 'No ContentVersion was found!');

	  map<id, ContentVersion> documentVersionMap = new map<id, ContentVersion>();
	  for (ContentVersion cv:cvs){
	  	system.debug(cv.VersionData);
	  	documentVersionMap.put(cv.Id, cv);
	  }

    //bunch of mapping work!
    list<user> users = [select id, contactid from user where contactId in: contacts];
    map<id, id> contactUserMap = new map<id, id>();

    for (user u:users){
    	contactUserMap.put(u.contactId, u.id);
    }

    for (relationshipTableRow RTR:Rows){
    	system.debug('file id:' + RTR.cvId);
    	ContentVersion CV = (ContentVersion)documentVersionMap.get(RTR.cvId);
    	system.debug(CV);
    	//system.assertNotEquals(cv.VersionData, null, 'the content version was null!');
    	ConnectApi.BinaryInput BI = new ConnectApi.BinaryInput(
	    	cv.VersionData,
	    	'image/jpg',
	    	'fakeName.jpg'
    	);
    	//public static ConnectApi.Photo setPhoto(String communityId, String userId, String fileId, Integer versionNumber)
    	ConnectApi.UserProfiles.setPhoto('internal', contactUserMap.get(RTR.contactId), BI);
    }
  }




	public class relationshipTableRow {
		public id contactId {get; set;}
		public Id cvId {get; set;}
	}


}