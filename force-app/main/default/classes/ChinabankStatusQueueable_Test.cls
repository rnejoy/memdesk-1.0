@isTest
public class ChinabankStatusQueueable_Test {

    public class ChinabankAPIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            res.setBody('{"body": {"responseData": "MOCK_ENCRYPTED_DATA"}}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }

    @testSetup
    static void setup() {
        API_Access_Token__c token = new API_Access_Token__c(
            Access_Token__c = 'Test_Token_123',
            Token_Expiry__c = (DateTime.now().getTime() / 1000) + 3600 
        );
        insert token;

        // 2. Create Test Contacts that match the Queueable's SOQL filters
        List<Contact> testContacts = new List<Contact>();
        for(Integer i=0; i<60; i++) {
            testContacts.add(new Contact(
                LastName = 'QueueableTest' + i,
                Customer_Type__c = 'Executive',
                Is_Active__c = true,
                Chinabank_Application_Status__c = 'IN-PROGRESS',
                Chinabank_Application_Reference_Number__c = 'REF-' + i,
                Chinabank_Status_Pulled__c = false
            ));
        }
        insert testContacts;
    }

    @isTest
    static void testQueueableBatchAndChaining() {
        // Set the mock inside the test method
        Test.setMock(HttpCalloutMock.class, new ChinabankAPIMock());

        Test.startTest();
        // Kick off the first batch
        System.enqueueJob(new ChinabankStatusQueueable(0));
        Test.stopTest(); // This forces the first Queueable to execute

        // Verify that the first 50 records were processed
        Integer processedCount = [SELECT Count() FROM Contact WHERE Chinabank_Status_Pulled__c = true];
        
        // Assertions
        System.assertEquals(50, processedCount, 'The first batch should have processed exactly 50 records.');
        
        // Check if logs were created
        Integer logCount = [SELECT Count() FROM API_Integration_Logs__c];
        System.assert(logCount > 0, 'Logs should have been generated for the callouts.');
    }

    @isTest
    static void testSecondWaveLogic() {
        Test.setMock(HttpCalloutMock.class, new ChinabankAPIMock());

        Test.startTest();
        System.enqueueJob(new ChinabankStatusQueueable(50));
        Test.stopTest();

        Integer totalProcessed = [SELECT Count() FROM Contact WHERE Chinabank_Status_Pulled__c = true];
        System.assert(totalProcessed > 0, 'The second wave should process available records.');
    }

    @isTest
    static void testEmptyQueue() {
        delete [SELECT Id FROM Contact];

        Test.startTest();
        System.enqueueJob(new ChinabankStatusQueueable());
        Test.stopTest();

        Integer processedCount = [SELECT Count() FROM Contact WHERE Chinabank_Status_Pulled__c = true];
        System.assertEquals(0, processedCount);
    }
}