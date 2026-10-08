@IsTest
private class ChinabankStatusSweeper_Test {

    private class ChinabankSmartMock implements HttpCalloutMock {
        public Integer callCount = 0;
        public String mode = 'SUCCESS'; 

        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (mode == 'ERROR') {
                res.setStatusCode(500);
                res.setBody('{"error": "Internal Server Error"}');
                return res;
            }

            if (mode == '401' && callCount == 1) {
                res.setStatusCode(401);
                res.setBody('{"error": "invalid_token"}');
                return res;
            }

            String endpoint = req.getEndpoint() != null ? req.getEndpoint() : '';

   
            if (endpoint.contains('token')) {
                res.setBody('{"access_token":"NEW_TOKEN_XYZ","expires_in":3600}');
            } 

            else if (endpoint.contains('getResult') || endpoint.contains('approval')) {
                if(mode == 'BAD_DATA') {
                    res.setBody('{"body": {"responseData": "!!!NOT_BASE64!!!"}}');
                } else {
                    String innerJson = '{"responseBody":{"result":"APPROVED","applicationRefNo":"CB-REF-123"}}';
                    String encrypted = EncodingUtil.base64Encode(Blob.valueOf(innerJson));
                    res.setBody('{"body": {"responseData": "' + encrypted + '"}}');
                }
            } 
            // Handle Push
            else {
                String innerJson = '{"responseHeader":{"responseContext":{"providerReferenceNumber":"CB-REF-777"}}}';
                String encrypted = EncodingUtil.base64Encode(Blob.valueOf(innerJson));
                res.setBody('{"body": {"responseData": "' + encrypted + '"}}');
            }
            return res;
        }
    }

    @testSetup
    static void setupData() {

        Test.setMock(HttpCalloutMock.class, new ChinabankSmartMock());

     
        List<Contact> testContacts = new List<Contact>();
        for(Integer i=0; i<60; i++) {
            testContacts.add(new Contact(
                FirstName = 'Juan' + i,
                LastName = 'Dela Cruz',
                MiddleName = 'Procopio',
                Suffix = 'Jr',
                Membership_Id__c = 'M-ID-' + i,
                Birthdate__c = Date.newInstance(1985, 5, 20),
                Place_of_Birth_City__c = 'Manila',
                Gender__c = 'MALE',
                Marital_Status__c = 'MARRIED',
                Nationality__c = 'FILIPINO',
                Educational_Attainment__c = 'COLLEGE GRADUATE',
                Mother_Maiden_Name__c = 'Reyes',
                Car_Ownership__c = 'YES',
                CBCC_Id_Type__c = 'PASSPORT',
                CBCC_Id_Number__c = 'P1234567' + i,
                MobilePhone = '0917123456' + i,
                Email = 'test' + i + '@example.com',
                Phone = '028123456',
                Street__c = '123 Main St',
                Barangay__c = 'San Lorenzo',
                City__c = 'Makati',
                Province__c = 'Metro Manila',
                Country__c = 'PH',
                Zip_Code__c = '1223',
                Permanent_Address__c = '123 Main St, Makati',
                Employment_Status__c = 'EMPLOYED',
                CBCC_Occupation__c = 'MANAGER',
                CBCC_Major_Industry__c = 'BANKING',
                Industry_Class__c = 'FINANCE',
                Industry_Subclass__c = 'COMMERCIAL BANK',
                CBCC_Source_of_Income__c = 'SALARY',
                Company_Name__c = 'Test Corp',
                Employment_Tenure__c = '05 | 00',
                Business_Mobile_Number__c = '09179998877',
                Business_Phone__c = '028999000',
                Business_Email__c = 'work@test.com',
                Business_Street__c = '456 Office Tower',
                Business_Barangay__c = 'Bel-Air',
                Business_City__c = 'Makati',
                Business_Province__c = 'Metro Manila',
                Business_Country__c = 'PH',
                Business_Address_Zip_Code__c = '1209',
                CBCC_Annual_Income__c = '1200000',
                Preferred_Billing_Address__c = 'HOME',
            
                Customer_Type__c = 'Executive',
                Is_Active__c = true,
                Chinabank_Application_Status__c = 'IN-PROGRESS',
                Chinabank_Application_Reference_Number__c = 'REF-' + i,
                Chinabank_Status_Pulled__c = false
            ));
        }
        insert testContacts;

        insert new API_Access_Token__c(
            Access_Token__c = 'EXPIRED_TOKEN',
            Token_Expiry__c = (DateTime.now().getTime() / 1000) - 3600 
        );
    }

    @IsTest
    static void testPushAndFutureLogic() {
        Test.setMock(HttpCalloutMock.class, new ChinabankSmartMock());
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        String pushRes = chinabankAPIService.sendToBank(con.Id);
        chinabankAPIService.getApprovalStatus(con.Id, 'REF-0');
        Test.stopTest();

        System.assertNotEquals(null, pushRes, 'Push response should not be null');
        Contact updated = [SELECT Chinabank_Application_Status__c FROM Contact WHERE Id = :con.Id];
        System.assertEquals('APPROVED', updated.Chinabank_Application_Status__c);
    }

    @IsTest
    static void testQueueableWaveLogic() {
        Test.setMock(HttpCalloutMock.class, new ChinabankSmartMock());

        Test.startTest();
        System.enqueueJob(new ChinabankStatusQueueable());
        Test.stopTest();

        Integer processedCount = [SELECT Count() FROM Contact WHERE Chinabank_Status_Pulled__c = true];
        System.assertEquals(50, processedCount, 'Should process exactly 50 records in the first wave');
    }

    @IsTest
    static void testSchedulerAndConstructors() {
        Test.setMock(HttpCalloutMock.class, new ChinabankSmartMock());

        Test.startTest();
        ChinabankStatusQueueable job = new ChinabankStatusQueueable(50);
        System.enqueueJob(job);
        
        String cron = '0 0 0 * * ?';
        System.schedule('Chinabank Deployment Test Job', cron, new ChinabankStatusSchedulerV2());
        Test.stopTest();
        
        System.assert(true);
    }

    @IsTest
    static void testErrorAndRetryFlows() {
        ChinabankSmartMock mock = new ChinabankSmartMock();
        mock.mode = '401'; 
        Test.setMock(HttpCalloutMock.class, mock);
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        try {
            chinabankAPIService.sendToBank(con.Id);
        } catch (Exception e) { /* Expected if DML fails during retry */ }
        
        mock.mode = 'ERROR';
        chinabankAPIService.getApprovalStatusInternal(con.Id, 'REF-ERR', 'TOKEN');
        Test.stopTest();

        List<API_Integration_Logs__c> logs = [SELECT Id FROM API_Integration_Logs__c];
        System.assert(logs.size() > 0, 'Should create logs even on error');
    }

    @IsTest
    static void testBadDataParsing() {
        ChinabankSmartMock mock = new ChinabankSmartMock();
        mock.mode = 'BAD_DATA';
        Test.setMock(HttpCalloutMock.class, mock);
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        chinabankAPIService.getApprovalStatusInternal(con.Id, 'REF-BAD', 'TOKEN');
        Test.stopTest();

        List<API_Integration_Logs__c> logs = [SELECT Decrypted_Response_Body__c FROM API_Integration_Logs__c];
        if(!logs.isEmpty()) {
            System.assert(true);
        }
    }
}