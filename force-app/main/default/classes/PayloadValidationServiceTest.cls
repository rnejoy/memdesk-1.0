@isTest
private class PayloadValidationServiceTest {

    @isTest
    static void testValidatePayloadWithValidData() {
        // Create test data for a matching contact
        Contact testContact = new Contact(
            LastName = 'Doe',
            Membership_id__c = '12345678901234',
            Birthdate__c = Date.newInstance(1990, 1, 1),
            Landers_Credit_Card_Applied__c = true
        );
        insert testContact;

        // Set up the request parameters
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/validatePayload/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
            'membershipId' => '12345678901234',
            'lastName' => 'Doe',
            'dobString' => '1990-01-01'
        }));
        RestContext.request = req;
        RestContext.response = res;

        // Start test, set the mock, and call the service method
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PayloadValidationMock()); // Set the mock here
        PayloadValidationService.validatePayload('12345678901234', 'Doe', '1990-01-01');
        Test.stopTest();

        // Verify success response
        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.toString().contains('"status":"Success"'));

        // Verify that the contact's "Maya_Validated__c" field was updated
        testContact = [SELECT Maya_Validated__c FROM Contact WHERE Id = :testContact.Id];
        System.assert(testContact.Maya_Validated__c);
    }

    @isTest
    static void testValidatePayloadWithInvalidDate() {
        // Set up the request parameters
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/validatePayload/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
            'membershipId' => '12345678901234',
            'lastName' => 'Doe',
            'dobString' => '1990-31-01'
        }));
        RestContext.request = req;
        RestContext.response = res;

        // Start test, set the mock, and call the service method
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PayloadValidationMock()); // Set the mock here
        PayloadValidationService.validatePayload('12345678901234', 'Doe', '1990-31-01');
        Test.stopTest();

        // Verify the error response for invalid date format
        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains('"Invalid date format"'));
    }

    @isTest
    static void testValidatePayloadWithInvalidMembershipId() {
        // Set up the request parameters
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/validatePayload/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
            'membershipId' => '123',  // Invalid membership ID
            'lastName' => 'Doe',
            'dobString' => '1990-01-01'
        }));
        RestContext.request = req;
        RestContext.response = res;

        // Start test, set the mock, and call the service method
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PayloadValidationMock()); // Set the mock here
        PayloadValidationService.validatePayload('123', 'Doe', '1990-01-01');
        Test.stopTest();

        // Verify the error response for invalid membership ID format
        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains('"Invalid membership ID"'));
    }

    @isTest
    static void testValidatePayloadRecordNotFound() {
        // Set up the request parameters for a non-existing contact (no matching record)
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/validatePayload/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
            'membershipId' => '12345678901234',
            'lastName' => 'Smith',  // Non-matching last name
            'dobString' => '1990-01-01'
        }));
        RestContext.request = req;
        RestContext.response = res;

        // Start test, set the mock, and call the service method
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PayloadValidationMock()); // Set the mock here
        PayloadValidationService.validatePayload('12345678901234', 'Smith', '1990-01-01');
        Test.stopTest();

        // Verify the error response for record not found
        System.assertEquals(404, res.statusCode);
        System.assert(res.responseBody.toString().contains('"Record not found"'));
    }

    @isTest
    static void testValidatePayloadExceptionHandling() {
        // Set up the request parameters with null membershipId
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/validatePayload/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
            'membershipId' => null,  // Null membership ID
            'lastName' => 'Doe',
            'dobString' => '1990-01-01'
        }));
        RestContext.request = req;
        RestContext.response = res;

        // Start test, set the mock, and call the service method
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PayloadValidationMock()); // Set the mock here
        PayloadValidationService.validatePayload(null, 'Doe', '1990-01-01');
        Test.stopTest();

        // Verify the error response for exception handling
        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains('"Invalid membership ID"'));
    }
}