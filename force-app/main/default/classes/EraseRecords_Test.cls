@isTest
public class EraseRecords_Test {
    @testSetup static void setup() {
        Test.setMock(HttpCalloutMock.class, new Send_Contact_To_stores_Mock()); 
        Contact testMember = new Contact(LastName='LastName',
                                         Membership_ID__c = '00000000000');
        insert testMember;
        Transaction__c testTransaction = new Transaction__c(Membership_ID__c = '00000000000',
                                                             Name = '00000000000',
                                                             Member__c = testMember.Id);
        insert testTransaction;
    }
    @isTest
    public static void S3CsvScheduler_Instore(){
        Test.startTest();
        SchedulableContext sc = null;
        EraseRecords_Scheduler tsc = new EraseRecords_Scheduler();
        tsc.execute(sc);
        Test.stopTest();
    }
}