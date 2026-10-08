@isTest
private class MemberFeedbackLookupController_Test {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testFindMemberSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Contact testContact = new Contact(
            FirstName = 'Katherine',
            LastName = 'Santos',
            Membership_ID__c = 'LNDR-8899'
        );
        insert testContact;

        Test.startTest();
        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember('LNDR-8899');
        Test.stopTest();

        Assert.isNotNull(result, 'findMember should return a MemberResult for a valid membership ID');
        Assert.isNotNull(result.token, 'Token should be generated');
        Assert.areEqual('Katherine', result.firstName, 'First name should match the contact record');
    }

    @isTest
    static void testFindMemberSuccessWithSpacing() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Contact testContact = new Contact(
            FirstName = 'Juan',
            LastName = 'Dela Cruz',
            Membership_ID__c = 'LNDR-1122'
        );
        insert testContact;

        Test.startTest();
        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember('  LNDR-1122 \n ');
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null despite spacing');
        Assert.areEqual('Juan', result.firstName, 'First name should match after trimming');
    }

    @isTest
    static void testFindMemberFallbackName() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Contact anonymousContact = new Contact(
            LastName = 'Legacy Account Holder',
            Membership_ID__c = 'LNDR-0000'
        );
        insert anonymousContact;

        Test.startTest();
        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember('LNDR-0000');
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.areEqual('Member', result.firstName, 'Blank first names should default to "Member"');
    }

    @isTest
    static void testFindMemberNotFound() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember('NON-EXISTENT-ID');
        Test.stopTest();

        Assert.isNull(result, 'Non-existent membership ID should return null');
    }

    @isTest
    static void testFindMemberEmptyInput() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember('');
        Test.stopTest();

        Assert.isNull(result, 'Empty input should return null');
    }

    @isTest
    static void testFindMemberNullInput() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember(null);
        Test.stopTest();

        Assert.isNull(result, 'Null input should return null');
    }

    @isTest
    static void testResolveMemberTokenSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Contact testContact = new Contact(
            FirstName = 'Maria',
            LastName = 'Garcia',
            Membership_ID__c = 'LNDR-5555'
        );
        insert testContact;

        // Generate a token via findMember
        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember('LNDR-5555');
        Assert.isNotNull(result.token);

        Test.startTest();
        Id resolvedContactId = MemberFeedbackLookupController.resolveMemberToken(result.token, 'LNDR-5555');
        Test.stopTest();

        Assert.areEqual(testContact.Id, resolvedContactId, 'Token should resolve to the correct Contact ID');
    }

    @isTest
    static void testResolveMemberTokenMismatchedMembershipId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Contact testContact = new Contact(
            FirstName = 'Carlos',
            LastName = 'Rodriguez',
            Membership_ID__c = 'LNDR-6666'
        );
        insert testContact;

        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember('LNDR-6666');

        Test.startTest();
        try {
            MemberFeedbackLookupController.resolveMemberToken(result.token, 'LNDR-WRONG');
            Assert.fail('Should have thrown SecurityException for mismatched membership ID');
        } catch (MemberFeedbackLookupController.SecurityException e) {
            Assert.isTrue(
                e.getMessage().containsIgnoreCase('does not match'),
                'Exception message should indicate membership ID mismatch'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testResolveMemberTokenInvalidFormat() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        try {
            MemberFeedbackLookupController.resolveMemberToken('invalid-token-format', 'LNDR-1234');
            Assert.fail('Should have thrown SecurityException for invalid token format');
        } catch (MemberFeedbackLookupController.SecurityException e) {
            Assert.isTrue(
                e.getMessage().containsIgnoreCase('Invalid token'),
                'Exception message should indicate invalid token'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testResolveMemberTokenNullToken() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        try {
            MemberFeedbackLookupController.resolveMemberToken(null, 'LNDR-1234');
            Assert.fail('Should have thrown SecurityException for null token');
        } catch (MemberFeedbackLookupController.SecurityException e) {
            Assert.isTrue(
                e.getMessage().containsIgnoreCase('Invalid token'),
                'Exception message should indicate invalid token'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testResolveMemberTokenTamperedSignature() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Contact testContact = new Contact(
            FirstName = 'Pedro',
            LastName = 'Lopez',
            Membership_ID__c = 'LNDR-7777'
        );
        insert testContact;

        MemberFeedbackLookupController.MemberResult result = MemberFeedbackLookupController.findMember('LNDR-7777');
        String validToken = result.token;

        // Tamper with the token by replacing the last few characters of the signature
        String tamperedToken = validToken.substring(0, validToken.length() - 5) + 'XXXXX';

        Test.startTest();
        try {
            MemberFeedbackLookupController.resolveMemberToken(tamperedToken, 'LNDR-7777');
            Assert.fail('Should have thrown SecurityException for tampered token');
        } catch (MemberFeedbackLookupController.SecurityException e) {
            Assert.isTrue(
                e.getMessage().containsIgnoreCase('verification failed'),
                'Exception message should indicate token verification failed'
            );
        }
        Test.stopTest();
    }

}