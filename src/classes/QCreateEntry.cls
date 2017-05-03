public with sharing class QCreateEntry implements Queueable {

	private id userId;
	private id contestId;

	public QCreateEntry(id userId, id contestId) {
		this.userId = userId;
		this.contestId = contestId;
	}

	public void execute(QueueableContext context){

		entry__c e= new entry__c();
		e.User__c = userId;
		e.Contest__c = contestId;
		insert e;

	}

}