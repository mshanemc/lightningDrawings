public with sharing class QCreateUserFromContact implements Queueable{

	private contact c;
	private id contestId;

	public QCreateUserFromContact(contact c, id contestId) {
		this.c = c;
		this.contestId = contestId;
	}

	public void execute(QueueableContext context){

		user u = new user();

		u.username = c.firstName+c.lastName+math.random()+'@lightningdrawings.autogenerated';
		u.FirstName = c.firstName;
		u.lastName = c.lastName;
		u.Alias = c.firstName.substring(0,1)+c.lastName.substring(0,1)+string.valueOf(math.round(math.random()*decimal.valueof(10).pow(6)));
		u.email = u.username;
		u.CommunityNickName = c.firstName.substring(0,1)+c.lastName.substring(0,1)+string.valueOf(math.round(math.random()*decimal.valueof(10).pow(10)));
		u.ProfileId = [select id from profile where name =: drawings__DrawingsSettings__c.getInstance().drawings__Contact_Profile_Name__c].Id;
		u.TimeZoneSidKey = 'America/New_York';
    u.LocaleSidKey = 'en_US';
    u.EmailEncodingKey = 'UTF-8';
    u.LanguageLocaleKey = 'en_US';
    u.ContactID = c.Id;
    u.isactive = false;
    insert u;

		//now enqueue something for creating the entry!
		if (!Test.isRunningTest()){
			system.enqueueJob(new QCreateEntry(u.id, contestId));
		}
	}


}