list<drawings__prize__c> prizes = [select id, drawings__contest__c, drawings__awarded__c from prize__c where drawings__awarded__c = true];
for (drawings__prize__c p: prizes){
	p.drawings__awarded__c = false;
}
update prizes;

list<drawings__entry__c> entries = [select id, drawings__prize_won__c from drawings__entry__c where drawings__prize_won__c != null];
for (drawings__entry__c e:entries){
	e.drawings__prize_won__c = null;
}
update entries;