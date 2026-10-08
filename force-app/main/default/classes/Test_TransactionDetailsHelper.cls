@isTest
public class Test_TransactionDetailsHelper {
    @testSetup static void setup() {
        Contact member = new Contact(LastName = 'Testington',
                                     Member_savings__c = null,
                                     Customer_Sub_Type__c = 'Primary');
        insert member;
        Transaction__c newTransaction = new Transaction__c(Member__c = member.Id);
        insert newTransaction;
    }
    @isTest public static void transactionDetailsHelper_Codecoverage(){
        Contact member = [SELECT Id FROM Contact LIMIT 1];
        Transaction__c newTransaction = [SELECT Id FROM Transaction__c LIMIT 1];
        Transaction_Details__c transactionDetails = new Transaction_Details__c(Transaction__c = newTransaction.Id, 
                                                                               Member__c = member.Id,
                                                                               Reg_SRP__c = 1000,
                                                                               Quantity__c = 1,
                                                                               Price__c = 1000);
        Test.startTest();
        insert transactionDetails;
        Test.stopTest();
        Contact getTransactionDetails = [SELECT Member_savings__c, Lifetime_transaction2__c FROM Contact LIMIT 1];
        System.assert(getTransactionDetails.Member_savings__c == 0);
        System.assert(getTransactionDetails.Lifetime_transaction2__c == 1000);
    }
}