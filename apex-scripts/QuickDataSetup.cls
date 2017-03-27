//let's create some contests
list<drawings__contest__c> contests = new list<drawings__contest__c>();

drawings__contest__c contest = new drawings__contest__c();
contest.Name = 'Internal Contest';
contest.drawings__Description__c = 'For employees!';
contest.drawings__Planned_Drawing_Time__c = system.now().addDays(30);
contest.drawings__Start_Accepting_Entries__c = system.now().addDays(-30);
contest.drawings__Stop_Accepting_Entries__c = system.now().addDays(29);


contests.add(contest);

contest = new drawings__contest__c();
contest.Name = 'External Contest';
contest.drawings__Description__c = 'For customers and partners!';
contest.drawings__Planned_Drawing_Time__c = system.now().addDays(30);
contest.drawings__Start_Accepting_Entries__c = system.now().addDays(-30);
contest.drawings__Stop_Accepting_Entries__c = system.now().addDays(29);
contests.add(contest);

insert contests;


list<drawings__prize__c> prizes = new list<drawings__prize__c>();

for (drawings__contest__c cont:contests){

  drawings__prize__c prize = new drawings__prize__c();
  prize.Name = 'Grand Prize';
  prize.drawings__Quantity__c = 1;
  prize.drawings__Contest__c = cont.Id;
  prize.drawings__Value__c = 10000;
  prize.drawings__Prize_Image__c = 'http://ohfact.1ygkv60km.netdna-cdn.com/wp-content/uploads/2016/06/science-all.jpg';
  prizes.add(prize);

  prize = new drawings__prize__c();
  prize.Name = '2nd Prize';
  prize.drawings__Quantity__c = 3;
  prize.drawings__Contest__c = cont.Id;
  prize.drawings__Value__c = 500;
  prize.drawings__Prize_Image__c = 'http://c.shld.net/rpx/i/s/i/spin/10117770/prod_1401193812??hei=64&wid=64&qlt=50';
  prizes.add(prize);

  prize = new drawings__prize__c();
  prize.Name = '3rd Prize';
  prize.drawings__Quantity__c = 10;
  prize.drawings__Contest__c = cont.Id;
  prize.drawings__Value__c = 50;
  prize.drawings__Prize_Image__c = 'https://us.v-cdn.net/5017260/uploads/FileUpload/de/d6ff97e1a6ceb026912ef0dd405711.jpg';
  prizes.add(prize);
}

insert prizes;

list<drawings__entry__c> entries = new list<drawings__entry__c>();
list<user> users = [select id from user where usertype = 'Standard' limit 1200];
for (user u:users){
  for (integer k = 0; k<math.round(1200/users.size()); k++){
    drawings__entry__c entry = new drawings__entry__c();
    entry.drawings__User__c = u.id;
    entry.drawings__contest__c = contests[0].id;
    entries.add(entry);
  }
}
for (user u:[select id from user where (usertype = 'PowerCustomerSuccess' OR usertype = 'PowerPartner')]){
	drawings__entry__c entry = new drawings__entry__c();
  entry.drawings__User__c = u.id;
  entry.drawings__contest__c = contests[1].id;
  entries.add(entry);
}
for (contact c:[select id from contact limit 300]){
	drawings__entry__c entry = new drawings__entry__c();
  entry.drawings__Contact__c = c.id;
  entry.drawings__contest__c = contests[1].id;
  entries.add(entry);
}
for (lead l:[select id from lead limit 300]){
	drawings__entry__c entry = new drawings__entry__c();
  entry.drawings__Lead__c = l.id;
  entry.drawings__contest__c = contests[1].id;
  entries.add(entry);
}
for (integer k=0; k<10; k++){
	drawings__entry__c entry = new drawings__entry__c();
  entry.drawings__Free_Name__c = 'Not in the org';
  entry.drawings__contest__c = contests[1].id;
  entries.add(entry);
}

insert entries;
