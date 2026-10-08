@isTest
public class TransactionDetailsTrigger_Test {
    @isTest
    public static void createTransactions(){
        Test.setMock(HttpCalloutMock.class, new Send_Contact_To_stores_Mock()); 
        List<Contact> createContacts = new List<Contact>();
        Contact dummyContact = new Contact(LastName = 'Dummy', 
                                           Membership_ID__c = '00000000000');
        Transaction__c dummyTransaction = new Transaction__c(Membership_ID__c = '00000000000',
                                                           Name = '00000000000',
                                                           Member__c = dummyContact.Id);
        INSERT dummyContact;
        INSERT dummyTransaction;
        Integer contactCount = 1;
        for(;contactCount < 201;){
            Contact newContact = new Contact(LastName = 'Star '+ contactCount, 
                                             Membership_ID__c = '0000000000'+contactCount);
            createContacts.add(newContact);
            contactCount++;
        }
        INSERT createContacts;
		List<Transaction__c> createTransactions = new List<Transaction__c>();
        Integer transactionCount = 1;
        for(;transactionCount < 201;){
            Transaction__c newTransaction = new Transaction__c(Membership_ID__c = '0000000000'+transactionCount,
                                                               Name = '0000000000'+transactionCount,
                                                               Member__c = dummyContact.Id);
            createTransactions.add(newTransaction);
            transactionCount++;
        }
        INSERT createTransactions;
        Test.startTest();
        List<Transaction_Details__c> createTransactionDetails = new List<Transaction_Details__c>();
        Integer transactionDetailsCount = 1;
        for(;transactionDetailsCount < 201;){
            Transaction_Details__c newTransactionDetails = new Transaction_Details__c(Membership_ID__c = '0000000000'+transactionDetailsCount,
                                                                                      Transaction_no__c = '0000000000'+transactionDetailsCount,
                                                                                      Transaction__c = dummyTransaction.Id,
                                                               				   		  Member__c = dummyContact.Id);
            createTransactionDetails.add(newTransactionDetails);
            transactionDetailsCount++;
        }
        INSERT createTransactionDetails;       
        Test.stopTest();
    }
}