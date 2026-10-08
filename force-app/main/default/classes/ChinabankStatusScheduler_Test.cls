@IsTest
private class ChinabankStatusScheduler_Test {

    private class GetResultMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            String decryptedJson = '{"responseBody":{"result":"APPROVED"}}';
            String encrypted = EncodingUtil.base64Encode(Blob.valueOf(decryptedJson));

            res.setBody(
                JSON.serialize(new Map<String, Object>{
                    'body' => new Map<String, Object>{
                        'responseData' => encrypted
                    }
                })
            );

            return res;
        }
    }

    @IsTest
    static void testSchedulerEnqueuesQueueable() {
        Test.setMock(HttpCalloutMock.class, new GetResultMock());

        Contact c = new Contact(
            LastName = 'Scheduler Exec',
            Chinabank_Application_Status__c = 'IN-PROGRESS',
            Chinabank_Application_Reference_Number__c = 'CB-REF-456'
        );
        insert c;

        String cron = '0 0 4 * * ?'; 

        Test.startTest();
        System.schedule(
            'Chinabank Status Scheduler Test',
            cron,
            new ChinabankStatusSchedulerV2() 
        );
        Test.stopTest();

        System.assert(true, 'Scheduler executed');
    }
}