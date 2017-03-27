//let's create some contests
list<drawings__contest__c> contests = new list<drawings__contest__c>();

drawings__contest__c contest = new drawings__contest__c();
contest.Name = 'Internal Contest';
contest.Description__c = 'For employees!';
contest.Planned_Drawing_Time__c = system.now().addDays(30);
contest.Start_Accepting_Entries__c = system.now().addDays(-30);
contest.Stop_Accepting_Entries__c = system.now().addDays(29);


contests.add(contest);

contest = new drawings__contest__c();
contest.Name = 'External Contest';
contest.Description__c = 'For customers and partners!';
contest.Planned_Drawing_Time__c = system.now().addDays(30);
contest.Start_Accepting_Entries__c = system.now().addDays(-30);
contest.Stop_Accepting_Entries__c = system.now().addDays(29);
contests.add(contest);

insert contests;


list<drawings__prize__c> prizes = new list<drawings__prize__c>();

for (drawings__contest__c cont:contests){
  drawings__prize__c prize = new drawings__prize__c();
  prize.Name = 'Grand Prize';
  prize.Quantity__c = 1;
  prize.Contest__c = cont.Id;
  prize.Value__c = 10000;
  prizes.add(prize);
  prize = new drawings__prize__c();
  prize.Name = '2nd Prize';
  prize.Quantity__c = 3;
  prize.Contest__c = cont.Id;
  prize.Value__c = 500;
  prizes.add(prize);
  prize = new drawings__prize__c();
  prize.Name = '3rd Prize';
  prize.Quantity__c = 10;
  prize.Contest__c = cont.Id;
  prize.Value__c = 50;
  prizes.add(prize);
}

list<drawings__entry__c> entries = new list<drawings__entry__c>();
for (user u:[select id from user where usertype = 'Standard']){
  drawings__entry__c entry = new drawings__entry__c();
  entry.User__c = u.id;
  entry.contest__c = contests[0].id;
  entries.add(entry);
}
for (user u:[select id from user where (usertype = 'PowerCustomerSuccess' OR usertype = 'PowerPartner')]){
	drawings__entry__c entry = new drawings__entry__c();
  entry.User__c = u.id;
  entry.contest__c = contests[1].id;
  entries.add(entry);
}
for (contact c:[select id from contact limit 300]){
	drawings__entry__c entry = new drawings__entry__c();
  entry.Contact__c = c.id;
  entry.contest__c = contests[1].id;
  entries.add(entry);
}
for (lead l:[select id from lead limit 300]){
	drawings__entry__c entry = new drawings__entry__c();
  entry.Lead__c = l.id;
  entry.contest__c = contests[1].id;
  entries.add(entry);
}
for (integer k=0; k<10; k++){
	drawings__entry__c entry = new drawings__entry__c();
  entry.Free_Name__c = 'Not in the org';
  entry.contest__c = contests[1].id;
  entries.add(entry);
}

insert entries;
