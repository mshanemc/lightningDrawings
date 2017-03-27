global with sharing class DrawingsDataPrep implements Queueable{

	private id contestId;

	global DrawingsDataPrep(Id contestId) {
		this.contestId = contestId;
	}

	global void execute(QueueableContext context){

		//all the execution logic is in this method (below)
		integer unnumberedRecords = numberStuff(contestId);

		//are we done yet?  //also, is this not a test?
		if (unnumberedRecords>0 && !Test.isRunningTest()){
			//nope, we'll need to run another batch
			System.enqueueJob(new DrawingsDataPrep(contestId));
		}
	}

	@InvocableMethod(label='Number the Drawing Entries' description='Pass in the ContestId.  Run as entries are created, or after contest closes. Must run before drawing')
	global static void numberTheEntriesInvocable(list<id> contestId){
		//dedupe
		set<id> IdSet = new set<id>();
		IdSet.addAll(contestId);

		for (id i:IdSet){
			if(!Test.isRunningTest()){
				System.enqueueJob(new DrawingsDataPrep(i));
			}

		}
		//has to be omitted from test, otherwise PB will fire on testdatasetup and queue a mass of these.  Could be smart and ask if it's already queued/running for that contest, Dan Appleman style
	}

	//returns the total number of unnumbered records after this operation completes.  This is in a separate method so it can be called from a test without waiting on the async process
	global static integer numberStuff(id localContestId){
		//what's the highest number that we have?
		integer Max = integer.valueof([select max(Sequence_Number__c)theMax from Entry__c where contest__c =: localContestId][0].get('theMax'));
		//how many records are there?
		if (Max==null){
			max = 0;
		}

		integer unnumberedRecords = [select count() from Entry__c where Sequence_Number__c = null and contest__c =:localContestId];

		list<entry__c> unnumbered = [select id, Sequence_Number__c from Entry__c where contest__c =:localContestId and Sequence_Number__c = null limit 49995];

		for (entry__c e:unnumbered){
			Max = Max + 1; //we'll start with 1.
			e.Sequence_Number__c = Max;
		}

		update unnumbered;
		return unnumberedRecords - unnumbered.size();
	}
}