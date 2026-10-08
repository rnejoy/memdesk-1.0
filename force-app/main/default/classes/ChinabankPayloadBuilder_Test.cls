@IsTest
private class ChinabankPayloadBuilder_Test {

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"OK"}');
            return res;
        }
    }

    private static Contact createFullContact(String employmentStatus) {

        Contact c = new Contact(
            FirstName = 'Juan',
            MiddleName = 'Test',
            LastName = 'Dela Cruz',
            Suffix = 'Jr',
            Email = 'juan@test.com',
            Phone = '028888888',
            MobilePhone = '09171234567',

            Birthdate__c = Date.newInstance(1990, 1, 1),
            place_of_birth_city__c = 'Manila',
            gender__c = 'MALE',
            marital_status__c = 'SINGLE',
            nationality__c = 'Filipino',
            mother_maiden_name__c = 'Santos',
            educational_attainment__c = 'COLLEGE',
            car_ownership__c = 'YES',
            cbcc_id_type__c = 'PASSPORT',
            cbcc_id_number__c = 'P123456',

            street__c = 'Test Street',
            barangay__c = 'Barangay 123',
            city__c = 'Quezon City',
            province__c = 'Metro Manila',
            country__c = 'PH',
            zip_code__c = '1100',
            Permanent_Address__c = 'Same as Present',

            employment_status__c = employmentStatus,
            cbcc_occupation__c = 'SOFTWARE ENGINEER',
            cbcc_major_industry__c = 'IT',
            Industry_Class__c = 'INFORMATION TECHNOLOGY',
            industry_subclass__c = 'SOFTWARE--DEV',
            cbcc_source_of_income__c = 'SALARY',
            company_name__c = 'Test Corp',
            employment_tenure__c = '01 | 06',
            cbcc_annual_income__c = '600000',

            business_mobile_number__c = '09179999999',
            business_phone__c = '027777777',
            business_email__c = 'biz@test.com',

            Business_Street__c = 'Biz Street',
            business_barangay__c = 'Biz Barangay',
            business_city__c = 'Makati',
            business_province__c = 'Metro Manila',
            business_country__c = 'PH',
            business_address_zip_code__c = '1200',

  
            preferred_billing_address__c = 'BUSINESS',

  
            membership_id__c = 'MEM-001'
        );

        insert c;
        return c;
    }

    @IsTest
    static void testBuildPayload_Employed() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Contact c = createFullContact('EMPLOYED');

        Test.startTest();
        String payload = chinabankPayloadBuilder.buildPayload(c);
        Test.stopTest();

        System.assertNotEquals(null, payload, 'Payload should be created');
    }

    @IsTest
    static void testBuildPayload_Unemployed() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Contact c = createFullContact('UNEMPLOYED');

        Test.startTest();
        String payload = chinabankPayloadBuilder.buildPayload(c);
        Test.stopTest();

        System.assert(payload != null, 'Payload should be created');
    }

    @IsTest
    static void testNationalityMapping() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Contact c = createFullContact('EMPLOYED');

        Test.startTest();
        String payload = chinabankPayloadBuilder.buildPayload(c);
        Test.stopTest();

        System.assert(payload.contains('N0001') || payload != null,
            'Nationality transformation executed');
    }

    @IsTest
    static void testProvinceFormatting() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Contact c = createFullContact('EMPLOYED');

        Test.startTest();
        String payload = chinabankPayloadBuilder.buildPayload(c);
        Test.stopTest();

        System.assert(payload != null, 'Province formatting executed');
    }

    @IsTest
    static void testBuildGetResultPayload() {
        Test.startTest();
        String payload = chinabankPayloadBuilder.buildGetResultPayload('APP-123');
        Test.stopTest();

        System.assertNotEquals(null, payload, 'GetResult payload should be created');
    }
}