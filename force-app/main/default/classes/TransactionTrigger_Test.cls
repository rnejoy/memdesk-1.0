@isTest
public class TransactionTrigger_Test {
    @isTest
    public static void createTransactions(){
        Test.setMock(HttpCalloutMock.class, new Send_Contact_To_stores_Mock()); 
        List<Contact> createContacts = new List<Contact>();
        Contact dummyContact = new Contact(LastName = 'Dummy', 
                                         Membership_ID__c = '0000000000');
        INSERT dummyContact;
        Integer contactCount = 0;
        for(;contactCount < 2000;){
            Contact newContact = new Contact(LastName = 'Star '+ contactCount, 
                                             Membership_ID__c = '0000000000'+contactCount);
            createContacts.add(newContact);
            contactCount++;
        }
        INSERT createContacts;
        Test.startTest();
        List<Transaction__c> createTransactions = new List<Transaction__c>();
        Integer transactionCount = 0;
        for(;transactionCount < 2000;){
            Transaction__c newTransaction = new Transaction__c(Membership_ID__c = '0000000000'+transactionCount,
                                                               Member__c = dummyContact.Id);
            createTransactions.add(newTransaction);
            transactionCount++;
        }
        INSERT createTransactions;
        Test.stopTest();
    }
}