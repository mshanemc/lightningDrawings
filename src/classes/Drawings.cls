global with sharing class Drawings {

	@AuraEnabled
	global static integer manualSequence (string contestId){
		//	global static integer numberStuff(id localContestId){

		return DrawingsDataPrep.numberStuff(contestId);
	}

	@AuraEnabled
	global static void setWinner (string prizeId, string entryId){
		entry__c winner = [select id, Prize_Won__c from entry__c where id=:entryId];
		winner.Prize_Won__c = prizeId;
		try {
			update winner;
			checkRemoteAwarded(prizeId);
		} catch (exception e){
			throw new AuraHandledException(e.getMessage());
		}
	}

	@future
	global static void checkRemoteAwarded (string prizeId){
		prize__c prize = getPrize(prizeId);
		integer left = remainingPrizes(prize.Id, integer.valueOf(prize.Quantity__c), prize.Contest__c);
		if (left==0){ //this is the last one!!
			prize.Awarded__c = true;
			update prize;
		}
	}

	//pulls down max of 1000 random entries to the client, where the component will manage the selection.  For dramatic effect
	@AuraEnabled
	global static prize__c getLocalPrize(string prizeId){
		return [select Name, Prize_Image__c from prize__c where id =: prizeId];
	}

	@AuraEnabled
	global static string drawLocallySingle(string prizeId){
		prize__c prize = getPrize(prizeId);

		integer prizesLeft = remainingPrizes(prize.Id, integer.valueOf(prize.Quantity__c), prize.Contest__c);

		if (prizesLeft==0){
			throw new AuraHandledException('all of this prize have been awarded!');
		}

		integer entryCount = unawardedCount(prize.contest__c);
		set<integer> winnerKeys = new set<integer>();

		integer targetEntries = math.Min(1000, entryCount);
		system.debug(targetEntries);

		set<integer> existingWinners = getExistingWinnerKeys(prize.Contest__c);

		do {
			winnerKeys.add(getWinnerKey(entryCount, existingWinners));
		} while (winnerKeys.size()<targetEntries);

		system.debug('winner key count :' + winnerKeys.size());

		list<entry__c> winnersWithPics = [select id, Entrant_Name__c, User__r.SmallPhotoUrl, User__r.MediumPhotoUrl, Prize_Won__c from entry__c where contest__c =: prize.contest__c and Sequence_Number__c in: winnerKeys and Prize_Won__c = null and User__c != null and isDeleted=false];
		list<entry__c> winnersWithoutPics = [select id, Entrant_Name__c, Prize_Won__c from entry__c where contest__c =: prize.contest__c and Sequence_Number__c in: winnerKeys and Prize_Won__c = null and User__c = null and isDeleted=false] ;

		list<entry__c> potentialWinners = new list<entry__c>();
		potentialWinners.addAll(winnersWithoutPics);
		potentialWinners.addAll(winnersWithPics);

		//system.assertEquals(targetEntries, potentialWinners.size());
		if (targetEntries != potentialWinners.size()){
			throw new AuraHandledException('There is a problem with the sequence numbers on the entries.  Did you delete one?');
		}
		return JSON.serialize(potentialWinners);

	}


	//award all the prizes for the entire contest
	@AuraEnabled
	global static void drawAll(string contestId){
		//first, get all the prizes
		integer totalPrizeCount = 0;
		list<prize__c> prizes = [select id, Awarded__c, Quantity__c from prize__c where contest__c =: contestId];
		if (prizes.size()==0){
			throw new AuraHandledException('This contest has no prizes!');
		}
		for (prize__c p:prizes){
			totalPrizeCount = totalPrizeCount + integer.valueOf(p.Quantity__c);
		}

		set<integer> existingWinners = getExistingWinnerKeys(contestId);
		if (existingWinners.size()!=0){
			throw new AuraHandledException('Some of the prizes have already been awarded!');
		}

		integer entryCount = unawardedCount(contestId);
		if (entryCount==0){
			throw new AuraHandledException('There are no entries with sequence numbers that haven\'t already won a prize');
		}

		if (entryCount<totalPrizeCount){
			throw new AuraHandledException('There aren\'t enough entries with sequence numbers that haven\'t already won a prize for the amount of prizes you want to award');
		}

		set<integer> winnerKeys = new set<integer>();

		do {
			winnerKeys.add(getWinnerKey(entryCount, existingWinners));
		} while (winnerKeys.size()<totalPrizeCount);

		system.assertEquals(winnerKeys.size(), totalPrizeCount, 'An error occured creating the winner keys');

		list<entry__c> winners = [select id, Prize_Won__c from entry__c where contest__c =: contestId and Sequence_Number__c in: winnerKeys and Prize_Won__c = null];

		system.assertEquals(winners.size(), totalPrizeCount);

		//we now have the winners picked.  Just not sure which prize they get
		list<id> prizeKeys = new list<id>();
		//integer prizesAwarded = 0; //tracker for how many we've given away
		//list<id> prize

		for (prize__c p:prizes){
			for (integer thisPrize = 0; thisPrize < p.Quantity__c; thisPrize++){
				prizeKeys.add(p.Id);
				//winners[prizesAwarded].Prize_Won__c = p.Id;
				//prizesAwarded = prizesAwarded + 1;
			}
			p.Awarded__c = true;
		}
		system.assertEquals(prizeKeys.size(), totalPrizeCount);

		list<id> randomizedPrizes = randomSort(prizeKeys);

		update prizes;

		for (integer k=0; k<winners.size(); k++){
			winners[k].Prize_Won__c = randomizedPrizes[k];
		}

		update winners;

	}

	//draw one instance of a prize
	@AuraEnabled
	global static string drawSinglePrize(string prizeId){
		prize__c prize = getPrize(prizeId);

		integer prizesLeft = remainingPrizes(prize.Id, integer.valueOf(prize.Quantity__c), prize.Contest__c);

		//do we have any left?
		if (prizesLeft<=0){
			throw new AuraHandledException('all of this prize have been awarded!');
		}

		set<integer> existingWinners = getExistingWinnerKeys(prize.Contest__c);

		list<entry__c> winner = [select id, Entrant_Name__c, Prize_Won__c from entry__c where contest__c =: prize.contest__c and Sequence_Number__c =: getWinnerKey(unawardedCount(prize.contest__c), existingWinners) and Prize_Won__c = null];
		system.assertEquals(winner.size(), 1);

		winner[0].Prize_Won__c = prizeId;
		update winner;

		//if there were only one, let's mark this done.
		if (prizesLeft == 1){
			prize.Awarded__c = true;
			update prize;
		}

		return winner[0].Entrant_Name__c;
	}

	//draw all the instances of this prize
	@AuraEnabled
	global static list<string> drawThisPrize(string prizeId){
		prize__c prize = getPrize(prizeId);
		// 	private static integer remainingPrizes(id prizeId, integer prizeQuantity, id contestId){

		integer prizesLeft = remainingPrizes(prizeId, integer.valueOf(prize.Quantity__c), prize.Contest__c);

		system.debug('there are ' + prizesLeft  + ' prizes left');

		if (prizesLeft==0){
			throw new AuraHandledException('all of this prize have been awarded!');
		}

		integer entryCount = unawardedCount(prize.contest__c);

		list<entry__c> winners = new list<entry__c>();
		set<integer> winnerKeys = new set<integer>();
		list<string> output = new list<string>();
		set<integer> existingWinners = getExistingWinnerKeys(prize.Contest__c);
		//you could draw the same number twice, so I had to use a while loop
		do {
			winnerKeys.add(getWinnerKey(entryCount, existingWinners));
		} while (winnerKeys.size()<prizesLeft);

		system.assertEquals(winnerKeys.size(), prizesLeft);
		winners = [select id, Entrant_Name__c, Prize_Won__c from entry__c where contest__c =: prize.contest__c and Sequence_Number__c in: winnerKeys and Prize_Won__c = null];

		//set the prize
		for (entry__c e:winners){
			e.Prize_Won__c = prizeId;
			output.add(e.Entrant_Name__c);
		}

		update winners;
		prize.Awarded__c = true;
		update prize;

		return output;

	}

	//random drawing, but won't return until it finds a number that hasn't already won
	@TestVisible
	private static integer getWinnerKey(integer entryCount, set<integer> existing){
		system.debug(existing);

		integer possible;
		do {
			possible = Math.Round(Math.random()*entryCount+0.4999);
			system.debug(possible);
		} while (existing.contains(possible) && possible != 0 && possible <= entryCount);

		return possible;
	}

	@TestVisible
	public static integer unawardedCount(id contestId){
		integer count =  [select count() from entry__c where contest__c =: contestId and Prize_Won__c = null and Sequence_Number__c != null and isDeleted=false];
		if (count==0){
			throw new AuraHandledException('There are no entries left that haven\'t already won a prize');
		}
		return count;
	}

	@TestVisible
	private static prize__c getPrize(id prizeId){
		return [select contest__c, Quantity__c, Awarded__c from prize__c where id =: prizeId ];
	}

	@TestVisible
	private static set<integer> getExistingWinnerKeys(id contestId){
		set<integer> winnerKeys = new set<integer>();
		for(entry__c e:[select id, Sequence_Number__c from entry__c where contest__c =: contestId and Prize_Won__c != null and isDeleted=false]){
			winnerKeys.add(integer.valueOf(e.Sequence_Number__c));
		}
		return winnerKeys;
	}

 	@TestVisible
 	private static integer remainingPrizes(id prizeId, integer prizeQuantity, id contestId){
 		integer awardedCount = [select count() from entry__c where contest__c =: contestId and Prize_Won__c =: prizeId and isDeleted=false];
 		//system.debug('prizes already awarded ' + awardedCount);
 		//system.debug('available quantity is ' + prizeQuantity);
 		return prizeQuantity - awardedCount;
 	}

 	@TestVisible
 	private static integer randBetween (integer lowest, integer highest){
 		return Math.Round(Math.random()*(highest-lowest) + 0.4999) + lowest;
 	}

 	//this will scale badly beyond 2 digit numbers.
 	@TestVisible
 	private static list<id> randomSort(list<id> input){
 		list<id> output = new list<id>();

 		integer spots = input.size();
 		set<integer> spotsGone = new set<integer>();

 		integer totalTries = 0;
 		do {
 			totalTries = totalTries + 1;
 			integer tryThis = randBetween(0, spots-1);
 			if (!spotsGone.contains(tryThis)){
 				output.add(input[tryThis]);
 				spotsGone.add(tryThis);
 			}
 		} while (output.size() < input.size() && totalTries < 100);

 		if (input.size() != output.size()){
 			set<id> whatWeGot = new set<id>(output);
 			for (id i:input){
 				if (!whatWeGot.contains(i)){
 					//the random approach never got to this one
 					output.add(i);
 				}
 			}
 		}
 		return output;

 	}
}