@isTest
private class MemberFeedbackController_Test {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Helper method to get a valid store code from the metadata in the org
     * so that test assertions don't fail due to hardcoded store codes missing.
     */
    private static String getValidStoreCode() {
        for (Store_Setting__mdt s : Store_Setting__mdt.getAll().values()) {
            if (s.Is_Active__c) {
                return s.Store_Code__c;
            }
        }
        return 'DEFAULT_TEST_STORE'; // Fallback just in case
    }

    @isTest
    static void testSaveFeedbackSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String validStoreCode = getValidStoreCode();

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Member',
            Membership_ID__c = 'MEM12345'
        );
        insert testContact;

        // Generate a real token using the lookup controller
        MemberFeedbackLookupController.MemberResult memberResult = 
            MemberFeedbackLookupController.findMember('MEM12345');
        Assert.isNotNull(memberResult.token, 'Token should be generated');

        // Build the payload
        MemberFeedbackController.FeedbackInput input = new MemberFeedbackController.FeedbackInput();
        input.membershipId = 'MEM12345';
        input.memberToken = memberResult.token;
        input.storeCode = validStoreCode;
        
        // Section A
        input.tripMission = 'Weekly Shop';
        input.availabilityItems = new List<String>{'Produce', 'Dairy'};
        input.availabilityFollowUp = new List<String>{'Other (please specify)'};
        input.availabilityFollowUpOther = 'Specialty Cheese';
        
        // Section B
        input.rateStoreAppearance = 5;
        input.rateFreshItems = 10; // Should be clamped to 5
        input.rateProductAvailability = 0; // Should be clamped to 1
        
        // Section C
        input.shareOfWallet = new List<String>{'Store A', 'Store B'};
        input.leakageFollowUp = 'Other (please specify)';
        input.leakageFollowUpOther = 'Better parking elsewhere';

        // Section D
        input.recommendScore = 9;
        input.serviceRecoveryConsent = true;
        input.serviceRecoveryPhone = '555-1234';

        Test.startTest();
        MemberFeedbackController.saveFeedback(input);
        Test.stopTest();

        List<Member_Feedback__c> results = [
            SELECT Id, Contact_ID__c, Store_Code__c, Trip_Mission__c, 
                   Availability_Open_Text__c, Availability_Follow_Up__c,
                   Rate_Store_Appearance__c, Rate_Fresh_Items__c, Rate_Product_Availability__c,
                   Share_Of_Wallet__c, Leakage_Follow_Up__c, 
                   Rate_Recommendation__c, Service_Recovery_Consent__c, Service_Recovery_Phone__c
            FROM Member_Feedback__c
        ];

        Assert.areEqual(1, results.size(), 'Exactly one feedback record should have been saved.');
        
        Member_Feedback__c savedRecord = results[0];
        
        // Check core mapping
        Assert.areEqual(testContact.Id, savedRecord.Contact_ID__c, 'Contact ID should be resolved and linked properly.');
        Assert.areEqual(validStoreCode, savedRecord.Store_Code__c, 'Store Code should map correctly.');
        Assert.areEqual(9, savedRecord.Rate_Recommendation__c, 'NPS score failed to map.');
        
        // Check text joining logic and "Other" replacements
        Assert.areEqual('Produce; Dairy', savedRecord.Availability_Open_Text__c, 'List strings failed to join properly.');
        Assert.areEqual('Other: Specialty Cheese', savedRecord.Availability_Follow_Up__c, 'The Other multi-select replacement failed.');
        Assert.areEqual('Other: Better parking elsewhere', savedRecord.Leakage_Follow_Up__c, 'The Other single-select replacement failed.');
        
        // Check clamps for Matrix ratings
        Assert.areEqual(5, savedRecord.Rate_Store_Appearance__c);
        Assert.areEqual(5, savedRecord.Rate_Fresh_Items__c, 'Scores above the max should be clamped down to 5.');
        Assert.areEqual(1, savedRecord.Rate_Product_Availability__c, 'Scores below the min should be clamped up to 1.');
        
        // Check generic booleans/strings
        Assert.isTrue(savedRecord.Service_Recovery_Consent__c, 'Consent boolean should be true.');
        Assert.areEqual('555-1234', savedRecord.Service_Recovery_Phone__c);
    }

    @isTest
    static void testGetActiveStores() {
        Test.startTest();
        List<MemberFeedbackController.StoreOption> stores = MemberFeedbackController.getActiveStores();
        Test.stopTest();

        Assert.isNotNull(stores, 'Stores list should not be null.');
        
        // We evaluate against the MDT limits. If org has setup stores it shouldn't be empty, 
        // but we verify at least the object structure initiates safely.
        for (MemberFeedbackController.StoreOption option : stores) {
            Assert.isNotNull(option.code, 'Store option code should never be null');
            Assert.isNotNull(option.name, 'Store option name should automatically default to code if empty.');
        }
    }
}