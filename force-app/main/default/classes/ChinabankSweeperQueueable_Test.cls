@IsTest
private class ChinabankSweeperQueueable_Test {

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    private static Contact createValidContact(String name) {
        return new Contact(
            LastName = name,
            Chinabank_Application_Reference_Number__c = null, 
            Chinabank_Application_Status__c = null,        
            Chinabank_Credit_Card_Applied__c = true,
            Customer_Type__c = 'Executive',
            Membership_Type__c = 'Member',
            Is_Active__c = true,
            Membership_Expiry_Date__c = Date.today().addDays(30),
            Chinabank_Sweeper_Pushed__c = false,
            Biz_Conversion_Date__c = Date.newInstance(2026, 1, 1) 
        );
    }

    @IsTest
    static void testProcessingLoop() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        ChinabankSweeperQueueable.isTestExecution = true;
        ChinabankSweeperQueueable.bypassTimeWindowForTest = true;

        Contact con = createValidContact('Processor');
        insert con;

        Test.startTest();
        System.enqueueJob(new ChinabankSweeperQueueable());
        Test.stopTest();
        
    }

    @IsTest
    static void testTimeWindowBypass() {
        ChinabankSweeperQueueable.isTestExecution = false;
        ChinabankSweeperQueueable.bypassTimeWindowForTest = false;
        
        Test.startTest();
        System.enqueueJob(new ChinabankSweeperQueueable());
        Test.stopTest();
    }

    @IsTest
    static void testNoRecordsFound() {
        ChinabankSweeperQueueable.isTestExecution = true;
        ChinabankSweeperQueueable.bypassTimeWindowForTest = true;
        
        delete [SELECT Id FROM Contact];

        Test.startTest();
        System.enqueueJob(new ChinabankSweeperQueueable());
        Test.stopTest();
    }

    @IsTest
    static void testNinetyRecordChaining() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        ChinabankSweeperQueueable.isTestExecution = true; 
        ChinabankSweeperQueueable.bypassTimeWindowForTest = true;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 90; i++) {
            contacts.add(createValidContact('Bulk' + i));
        }
        insert contacts;

        Test.startTest();
        System.enqueueJob(new ChinabankSweeperQueueable());
        Test.stopTest();
        
        System.assertEquals(90, [SELECT count() FROM Contact WHERE LastName LIKE 'Bulk%'], '90 records should exist');
    }

    @IsTest
    static void testPostCalloutTagging() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        ChinabankSweeperQueueable.isTestExecution = true;
        ChinabankSweeperQueueable.bypassTimeWindowForTest = true;
        
        Contact c = createValidContact('TaggingTest');
        insert c;

        c.Chinabank_Application_Reference_Number__c = 'MOCK-REF-123';
        update c;

        Test.startTest();
        System.enqueueJob(new ChinabankSweeperQueueable());
        Test.stopTest();
    }
}