@isTest
public class MobileValidationServiceTest {

    // Mock class to simulate the HTTP response
    private class MockMobileValidationResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"status":"Success"}'); // Simulating a successful response
            return res;
        }
    }

    // Utility method to create a sample contact with mobilePhone
    private static void createTestContact(String mobilePhone) {
        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', MobilePhone = mobilePhone);
        insert contact;
    }

    // This method is needed to simulate the RestContext for testing
    private static void setupRestContext(String mobilePhone) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/validateMobile/';
        req.addParameter('MobilePhone', mobilePhone);

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @isTest
    static void testValidMobileNumber() {
        // Arrange: Create a valid contact with a mobile number
        createTestContact('09123456789');
        setupRestContext('09123456789'); // Setup RestContext for the test

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockMobileValidationResponse());

        // Act: Call the validateMobile method with a valid mobile number
        Test.startTest();
        MobileValidationService.validateMobile('09123456789');
        Test.stopTest();

        // Assert: Verify that the response status code is 200
        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode, 'Expected status code to be 200');
    }

    @isTest
    static void testInvalidMobileNumberFormat() {
        // Arrange: Create a valid contact with a mobile number
        createTestContact('09123456789');
        setupRestContext('123'); // Setup RestContext for the test

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockMobileValidationResponse());

        // Act: Call the validateMobile method with an invalid mobile number format
        Test.startTest();
        MobileValidationService.validateMobile('123');
        Test.stopTest();

        // Assert: Verify that the response status code is 400 for invalid format
        RestResponse res = RestContext.response;
        System.assertEquals(400, res.statusCode, 'Expected status code to be 400');
    }

    @isTest
    static void testMobileNumberNotFound() {
        // Arrange: Create a valid contact with a different mobile number
        createTestContact('09223344556');
        setupRestContext('09112223344'); // Setup RestContext for the test

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockMobileValidationResponse());

        // Act: Call the validateMobile method with a mobile number that does not exist in Salesforce
        Test.startTest();
        MobileValidationService.validateMobile('09112223344');
        Test.stopTest();

        // Assert: Verify that the response status code is 404 for mobile number not found
        RestResponse res = RestContext.response;
        System.assertEquals(404, res.statusCode, 'Expected status code to be 404');
    }

    @isTest
    static void testNullMobileNumber() {
        // Act: Call the validateMobile method with a null mobile number
        setupRestContext(null); // Setup RestContext for the test
        Test.setMock(HttpCalloutMock.class, new MockMobileValidationResponse());

        Test.startTest();
        MobileValidationService.validateMobile(null);
        Test.stopTest();

        // Assert: Verify that the response status code is 400 for invalid format (null is invalid)
        RestResponse res = RestContext.response;
        System.assertEquals(400, res.statusCode, 'Expected status code to be 400');
    }

    @isTest
    static void testMobileNumberWithLetters() {
        // Act: Call the validateMobile method with a mobile number containing letters
        setupRestContext('09123abc789'); // Setup RestContext for the test
        Test.setMock(HttpCalloutMock.class, new MockMobileValidationResponse());

        Test.startTest();
        MobileValidationService.validateMobile('09123abc789');
        Test.stopTest();

        // Assert: Verify that the response status code is 400 for invalid format (letters are not allowed)
        RestResponse res = RestContext.response;
        System.assertEquals(400, res.statusCode, 'Expected status code to be 400');
    }

    @isTest
    static void testMobileNumberTooLong() {
        // Act: Call the validateMobile method with a mobile number that is too long
        setupRestContext('091234567891234'); // Setup RestContext for the test
        Test.setMock(HttpCalloutMock.class, new MockMobileValidationResponse());

        Test.startTest();
        MobileValidationService.validateMobile('091234567891234');
        Test.stopTest();

        // Assert: Verify that the response status code is 400 for mobile number exceeding the length limit
        RestResponse res = RestContext.response;
        System.assertEquals(404, res.statusCode, 'Expected status code to be 404');
    }

    @isTest
    static void testMultipleValidMobileNumbers() {
        // Arrange: Create multiple valid contacts
        createTestContact('09123456789');
        createTestContact('09223344556');
        setupRestContext('09223344556'); // Setup RestContext for the test

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockMobileValidationResponse());

        // Act: Call the validateMobile method with one of the valid numbers
        Test.startTest();
        MobileValidationService.validateMobile('09223344556');
        Test.stopTest();

        // Assert: Verify that the response status code is 200
        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode, 'Expected status code to be 200');
    }
}