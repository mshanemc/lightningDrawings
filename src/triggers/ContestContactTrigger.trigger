//takes feed attachments to contacts related to a contest account and sets that community user's portal profile
trigger ContestContactTrigger on FeedItem (after insert, after update) {

	//trigger on/off switch in custom settings
	if (drawings__DrawingsSettings__c.getOrgDefaults().drawings__Copy_Chatter_Attachments_on_Contact__c){
		DrawingsEntryChatterPostHandler.handleItems(trigger.newMap);
	}

}