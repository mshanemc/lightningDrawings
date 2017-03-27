@isTest
private class DrawingsTest {

	@isTest static void testRandomSort(){
		list<id> testInput = new list<Id>();

		for (entry__c e:[select id from entry__c]){
			testInput.add(e.Id);
		}

		list<id> testOutput = drawings.randomSort(testInput);

		//we still have the right amount of them
		system.assertEquals(testInput.size(), testOutput.size());
		//if we convert them to sets (that is, dedupe by ID), they're still the same amount

		set<id> testInputSet = new set<id>(testInput);
		set<id> testOutputSet = new set<id>(testOutput);

		system.assertEquals(testInputSet.size(), testOutputSet.size());

	}


	@isTest static void testRandom(){
		// 	private static integer randBetween (integer lowest, integer highest){

		list<integer> from0to10List = new list<integer>();
		list<integer> from10to20List = new list<integer>();

		for (integer k = 0; k<10; k++){
			from0to10List.add(drawings.randBetween(0, 10));
			from10to20List.add(drawings.randBetween(10, 20));
		}

		for (integer k:from0to10List){
			system.assert(k >= 0);
			system.assert(k<= 10);
		}

		for (integer k:from10to20List){
			system.assert(k >= 10);
			system.assert(k <= 20);
		}
	}

	@isTest static void testSetWinner(){
  	list<prize__c> prizes = [select id, contest__c, Quantity__c from prize__c];
		list<entry__c> entries = [select id from entry__c where contest__c =: prizes[0].contest__c limit 1];

		drawings.setWinner(prizes[0].id, entries[0].id);

		entry__c winner = [select Prize_Won__c from entry__c where id =: entries[0].id];
		system.assertEquals(winner.Prize_Won__c, prizes[0].id);
	}

  @isTest static void testDrawLocalSingle(){
  	list<prize__c> prizes = [select id, contest__c, Quantity__c from prize__c];
  	integer unawarded = drawings.unawardedCount(prizes[0].contest__c);

  	list<entry__c> potentialWinners = (list<entry__c>)JSON.deserialize(drawings.drawLocallySingle(prizes[0].id), list<entry__c>.class);

  	if (unawarded>1000){
  		//no more than 1000 potential winners.  400 < unawarded < 4000
  		system.assertEquals(potentialWinners.size(), 1000);
  	} else {
  		system.assertEquals(potentialWinners.size(), unawarded);
  	}

  }

	@isTest static void testNumberingQueueable(){
		//they're already numbered, right?
		list<contest__c> contests = [select Id from Contest__c];

		//let's add 2 more entries.  These won't be sequenced.
		list<entry__c> entries = new list<entry__c>();

		for (user u:[select id from user limit 2]){
				entry__c e = new entry__c();
				e.User__c = u.Id;
				e.Contest__c = contests[0].Id;
				entries.add(e);
		}

		insert entries;

		test.startTest();
		System.enqueueJob(new DrawingsDataPrep(contests[0].id));
		test.stopTest();

		//verify that they got numbered
		list<entry__c> unsequenced = [select id from Entry__c where Sequence_Number__c = null];
		system.assertEquals(0, unsequenced.size());
	}

	@isTest static void testNumberingQueueableViaInvocableApex(){
		//they're already numbered, right?
		list<contest__c> contests = [select Id from Contest__c];

		//let's add 2 more entries.  These won't be sequenced.
		list<entry__c> entries = new list<entry__c>();

		for (user u:[select id from user limit 2]){
				entry__c e = new entry__c();
				e.User__c = u.Id;
				e.Contest__c = contests[0].Id;
				entries.add(e);
		}

		insert entries;

		//because invocable always uses a list
		list<id> contestIDs = new list<id>();
		for (contest__c c:contests){
			contestIDs.add(c.Id);
		}

		test.startTest();
		DrawingsDataPrep.numberTheEntriesInvocable(contestIDs);
		test.stopTest();

		//verify that they got numbered
		list<entry__c> unsequenced = [select id from Entry__c where Sequence_Number__c = null];
		system.assertEquals(2, unsequenced.size());
		integer Remaining = DrawingsDataPrep.numberStuff(contests[0].id);
		unsequenced = [select id from Entry__c where Sequence_Number__c = null];
		system.assertEquals(0, unsequenced.size());
		system.assertEquals(0, Remaining);

	}

	@isTest static void testIndividualDrawing() {
		// Implement test code
		list<prize__c> prizes = [select id, contest__c, Quantity__c from prize__c];
		//list<entry__c> originalEntries = [select id, entrant_name__c from entry__c where contest__c =: prizes[0].contest__c];

		for (prize__c p:prizes){
			drawings.drawThisPrize(p.Id);
			list<Entry__c> awarded = [select Id from entry__c where contest__c =: p.contest__c and Prize_Won__c =: p.Id ];
			system.assertEquals(awarded.size(), p.Quantity__c);
		}
	}

	@isTest static void testDrawAll() {
		// Implement test code
		list<prize__c> prizes = [select contest__c from prize__c limit 1];

		test.startTest();
		drawings.drawAll(prizes[0].contest__c);
		test.stopTest();
		//list<entry__c> originalEntries = [select id, entrant_name__c from entry__c where contest__c =: prizes[0].contest__c];

		prizes = [select id, Name, contest__c, Awarded__c, Quantity__c from prize__c];

		for (prize__c p:prizes){
			list<Entry__c> awarded = [select Id from entry__c where contest__c =: p.contest__c and Prize_Won__c =: p.Id ];
			system.assertEquals(awarded.size(), p.Quantity__c, 'for prize ' + p.Name + ' there were ' + awarded.size() + ' awarded but there should have been ' + p.Quantity__c); //verify that we awarded exactly the quantity allowed
			system.assertEquals(p.Awarded__c, true);
		}
	}

	@isTest static void testDrawSingle(){
		//should only pull one prize that is only awarded once.
		list<prize__c> prizes = [select id, contest__c, Quantity__c from prize__c where Quantity__c = 1];
		system.assert(prizes.size()==1);
		string winnerName = drawings.drawSinglePrize(prizes[0].id);

		list<Entry__c> awarded = [select Id, entrant_name__c from entry__c where contest__c =: prizes[0].contest__c and Prize_Won__c =: prizes[0].id ];
		system.assertEquals(awarded[0].entrant_name__c, winnerName);
		system.assertEquals(awarded.size(), 1);

		//should fail because there's no prizes left!
		try{
			winnerName = drawings.drawSinglePrize(prizes[0].id);
			} catch (exception e){
				system.debug(e.getMessage());
				System.AssertEquals(e.getMessage(), 'Script-thrown exception');
			}
	}


	@TestSetup
	public static void createData(){
		//lets create some users
		contest__c cont = new contest__c();
		cont.Name = 'The big contest';
		cont.Start_Accepting_Entries__c = system.now().addDays(-5);
		cont.Stop_Accepting_Entries__c = system.now().addDays(30);
		insert cont;

		list<prize__c> prizes = new list<prize__c>();
		for (integer k=0; k<5; k++){
			prize__c p = new prize__c();
			p.name = 'prize ' + string.valueof(k);
			p.Contest__c = cont.Id;
			p.Quantity__c = k+1;
			p.Value__c = 1000/(k+1);
			prizes.add(p);
		}

		insert prizes;

		list<user> users = createUsers(400);

		list<entry__c> entries = new list<entry__c>();
		for (user u:users){
			for (integer k = 0; k<Math.round(Math.random()*10); k++){
				entry__c e = new entry__c();
				e.User__c = u.Id;
				e.Contest__c = cont.Id;
				entries.add(e);
			}
		}
		insert entries;

		integer numberingResult = DrawingsDataPrep.numberStuff(cont.Id);
		system.assertEquals(numberingResult, 0);

	}

	public static list<user> createUsers(integer numberOfUsers){
			list<user> users = new list<user>();

			Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];


			for (integer i=0; i<numberOfUsers; i++){
				string x = string.valueOf(i);
				User u = new User(Alias = 't'+x, Email='standarduser'+x+'@testLightningSharing2017.msm',
					EmailEncodingKey='UTF-8', LastName='Testing' + x, LanguageLocaleKey='en_US',
					LocaleSidKey='en_US', ProfileId = p.Id,
					TimeZoneSidKey='America/Los_Angeles', UserName='standarduser'+x+'@testLightningSharing2017.msm');
				users.add(u);
			}

			insert users;
			return users;
		}

}