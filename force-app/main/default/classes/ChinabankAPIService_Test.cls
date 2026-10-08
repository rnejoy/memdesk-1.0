@IsTest
private class ChinabankAPIService_Test {

    private class ChinabankHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            if (req.getEndpoint() != null && req.getEndpoint().contains('getResult')) {
                res.setBody('{"body": {"responseData": "{\\"responseBody\\": {\\"result\\": \\"PENDING\\"}}"}}');
            } else {
                res.setBody('{"result":"SUCCESS","applicationStatus":"PENDING"}');
            }
            return res;
        }
    }

    private class ChinabankErrorMock implements HttpCalloutMock {
        private Integer statusCode;
        private String endpointContains;
        private String responseBody;

        public ChinabankErrorMock(Integer statusCode, String endpointContains, String responseBody) {
            this.statusCode = statusCode;
            this.endpointContains = endpointContains;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus('Mock Status');
            res.setBody(this.responseBody);
            return res;
        }
    }

    private class ChinabankRetryMock implements HttpCalloutMock {
        private Integer callCount = 0;
    
        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"NEW_TEST_TOKEN","expires_in":3600}');
                return res;
            }
            if (callCount == 1) {
                res.setStatusCode(401);
                res.setBody('{"error":"invalid_token"}');
                return res;
            }
            res.setStatusCode(200);
            res.setBody('{"body": {"responseData": "{\\"responseBody\\": {\\"result\\": \\"PENDING\\"}}"}}');
            return res;
        }
    }

    private class ChinabankExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated HTTP Timeout Error');
        }
    }

    private static Contact createTestContact() {
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Coverage',
            MiddleName = 'T',
            Suffix = 'Jr',
            Membership_Id__c = 'C987654',
            Birthdate__c = Date.newInstance(1990, 1, 1),
            MobilePhone = '09170000000',
            Email = 'test.coverage@test.com',
            Street__c = '123 Test Street',
            Barangay__c = 'Barangay Test',
            City__c = 'Test City',
            Province__c = 'Metro Manila',
            Country__c = 'PH',
            Gender__c = 'MALE',
            Marital_Status__c = 'SINGLE',
            Nationality__c = 'FILIPINO',
            Mother_Maiden_Name__c = 'Reyes',
            Employment_Status__c = 'EMPLOYED',
            CBCC_Occupation__c = 'SOFTWARE ENGINEER',
            CBCC_Major_Industry__c = 'MI0010-INFORMATION AND COMMUNICATION',
            CBCC_Annual_Income__c = '850000',
            Industry_Class__c = 'IT SERVICES',
            Industry_Subclass__c = 'APPLICATION DEVELOPMENT',
            CBCC_Source_of_Income__c = 'SALARY',
            Company_Name__c = 'Test Company Inc.',
            Employment_Tenure__c = '02 | 06',
            Preferred_Billing_Address__c = 'BUSINESS',
            Business_Mobile_Number__c = '639171234568',
            Business_Phone__c = '028888889',
            Business_Email__c = 'juan@company.com',
            Business_Street__c = '456 Business St',
            Business_Barangay__c = 'Barangay Biz',
            Business_City__c = 'Taguig',
            Business_Province__c = 'Metro Manila',
            Business_Country__c = 'PH',
            Business_Address_Zip_Code__c = '1630'
        );
        insert c;

        API_Access_Token__c token = new API_Access_Token__c(
            Access_Token__c = 'INITIAL_TOKEN',
            Token_Expiry__c = (DateTime.now().getTime() / 1000) + 3600
        );
        insert token;

        return c;
    }

    @IsTest
    static void test_sendToBank_success() {
        Contact c = createTestContact();
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());
        Test.startTest();
        String result = chinabankAPIService.sendToBank(c.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void test_getApprovalStatus_success() {
        Contact c = createTestContact();
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());
        Test.startTest();
        chinabankAPIService.getApprovalStatusInternal(c.Id, 'APP-TEST-123', null);
        Test.stopTest();
        Contact updated = [SELECT Chinabank_Application_Status__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals('PENDING', updated.Chinabank_Application_Status__c);
    }

    @IsTest
    static void test_chinabankStatusScheduler_execute() {
        Contact c = createTestContact();
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());
        Test.startTest();
        chinabankStatusSchedulerv2 sched = new chinabankStatusSchedulerv2();
        String jobId = System.schedule(
            'Chinabank Status Scheduler Test',
            '0 0 0 1 1 ? 2099',
            sched
        );
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void test_sendToBank_nullContactId() {
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            chinabankAPIService.sendToBank(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown);
    }

    @IsTest
    static void test_getApprovalStatusInternal_nullInputs() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            chinabankAPIService.getApprovalStatusInternal(null, null, null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown);
    }

    @IsTest
    static void test_sendToBank_HttpCalloutException() {
        Contact c = createTestContact();
        Test.setMock(HttpCalloutMock.class, new ChinabankExceptionMock());
        Test.startTest();
        String result = chinabankAPIService.sendToBank(c.Id);
        Test.stopTest();
        System.assert(result.contains('Simulated HTTP Timeout Error'));
    }

    @IsTest
    static void test_getApprovalStatus_future() {
        Contact c = createTestContact();
        Test.setMock(HttpCalloutMock.class, new ChinabankHttpMock());
        Test.startTest();
        chinabankAPIService.getApprovalStatus(c.Id, 'APP-FUTURE-123');
        Test.stopTest();
        Contact updated = [SELECT Chinabank_Application_Status__c FROM Contact WHERE Id = :c.Id];
        System.assertNotEquals(null, updated.Chinabank_Application_Status__c);
    }

    @IsTest
    static void test_getApprovalStatusInternal_DecryptionParseError() {
        Contact c = createTestContact();
        String malformedResponseBody = '{"body": {"responseData": "INVALID"}}';
        Test.setMock(HttpCalloutMock.class, new ChinabankErrorMock(200, 'getResult', malformedResponseBody));
        Test.startTest();
        chinabankAPIService.getApprovalStatusInternal(c.Id, 'APP-PARSE-123', null);
        Test.stopTest();
        API_Integration_Logs__c log = [SELECT Decrypted_Response_Body__c FROM API_Integration_Logs__c WHERE Membership_id__c = :c.Id LIMIT 1];
        System.assert(log.Decrypted_Response_Body__c.contains('DECRYPT'));
    }
}