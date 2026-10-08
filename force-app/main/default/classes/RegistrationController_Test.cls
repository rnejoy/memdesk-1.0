/**
 * Test class for RegistrationController.
 *
 * NOTE: createRegistration() calls RecaptchaController.verify(), which does
 * a real callout and depends on a 'Default' Recaptcha_Setting__mdt record.
 * Custom Metadata records can't be inserted via DML in tests, so the
 * createRegistration tests are gated behind isRecaptchaConfigured() and will
 * skip (not fail) if that record isn't deployed to the org. Deploy a
 * 'Default' record (any non-blank Site_Key__c/Secret_Key__c) to get full
 * coverage on this class.
 */
@isTest
private class RegistrationController_Test {

    // ── Mock for the reCAPTCHA siteverify callout ──────────────────────────
    private class RecaptchaHttpMock implements HttpCalloutMock {
        Integer statusCode;
        String body;

        RecaptchaHttpMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    private static Boolean isRecaptchaConfigured() {
        return ![SELECT Id FROM Recaptcha_Setting__mdt WHERE DeveloperName = 'Default' LIMIT 1].isEmpty();
    }

    private static void mockRecaptchaSuccess() {
        Test.setMock(HttpCalloutMock.class, 
            new RecaptchaHttpMock(200, '{"success":true}'));
    }

    private static void mockRecaptchaFailure() {
        Test.setMock(HttpCalloutMock.class, 
            new RecaptchaHttpMock(200, '{"success":false,"error-codes":["invalid-input-response"]}'));
    }

    @testSetup
    static void setup() {
        // Register mock in setup in case Contact triggers make callouts
        mockRecaptchaSuccess();
        
        insert new Contact(
            FirstName        = 'John',
            MiddleName       = 'Q',
            LastName         = 'Doe',
            Membership_ID__c = 'MEM-001'
        );
    }

    // ───────────────────────── validateMemberId ────────────────────────────

    @isTest
    static void testValidateMemberId_blankReturnsNull() {
        mockRecaptchaSuccess(); // Register mock in case static block fires callout
        System.assertEquals(null, RegistrationController.validateMemberId(null));
        System.assertEquals(null, RegistrationController.validateMemberId(''));
        System.assertEquals(null, RegistrationController.validateMemberId('   '));
    }

    @isTest
    static void testValidateMemberId_notFoundReturnsNull() {
        mockRecaptchaSuccess();
        Map<String, String> result = RegistrationController.validateMemberId('NO-SUCH-ID');
        System.assertEquals(null, result);
    }

    @isTest
    static void testValidateMemberId_foundReturnsNameFields() {
        mockRecaptchaSuccess();
        Test.startTest();
        Map<String, String> result = RegistrationController.validateMemberId('MEM-001');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('John', result.get('firstName'));
        System.assertEquals('Q', result.get('middleName'));
        System.assertEquals('Doe', result.get('lastName'));
    }

    @isTest
    static void testValidateMemberId_nullMiddleNameReturnsEmptyString() {
        mockRecaptchaSuccess();
        
        insert new Contact(
            FirstName        = 'Jane',
            LastName         = 'Smith',
            Membership_ID__c = 'MEM-002'
        );

        Map<String, String> result = RegistrationController.validateMemberId('MEM-002');

        System.assertNotEquals(null, result);
        System.assertEquals('Jane', result.get('firstName'));
        System.assertEquals('', result.get('middleName'));
        System.assertEquals('Smith', result.get('lastName'));
    }

    // ───────────────────────── createRegistration ──────────────────────────

    @isTest
    static void testCreateRegistration_recaptchaNotConfiguredThrows() {
        mockRecaptchaSuccess();
        if (isRecaptchaConfigured()) return;

        Boolean threw = false;
        try {
            RegistrationController.createRegistration(
                'MEM-001', 'John', 'Q', 'Doe', 'john@example.com',
                '555-1234', 'Model X', 'Self', 'PartnerA', 'some-token'
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected failure when reCAPTCHA is not configured');
    }

    @isTest
    static void testCreateRegistration_recaptchaFailsThrows() {
        mockRecaptchaFailure(); // Specific failure mock for this test
        if (!isRecaptchaConfigured()) return;

        Boolean threw = false;
        Test.startTest();
        try {
            RegistrationController.createRegistration(
                'MEM-001', 'John', 'Q', 'Doe', 'john@example.com',
                '555-1234', 'Model X', 'Self', 'PartnerA', 'bad-token'
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Expected failure when captcha verification fails');
        System.assertEquals(0, [SELECT COUNT() FROM Partner_Promo_List__c]);
    }

    @isTest
    static void testCreateRegistration_memberNotFoundThrows() {
        mockRecaptchaSuccess();
        if (!isRecaptchaConfigured()) return;

        Boolean threw = false;
        Test.startTest();
        try {
            RegistrationController.createRegistration(
                'NO-SUCH-ID', 'John', 'Q', 'Doe', 'john@example.com',
                '555-1234', 'Model X', 'Self', 'PartnerA', 'good-token'
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Expected failure when member Contact cannot be found');
        System.assertEquals(0, [SELECT COUNT() FROM Partner_Promo_List__c]);
    }

    @isTest
    static void testCreateRegistration_successCreatesCounterAndRecord() {
        mockRecaptchaSuccess();
        if (!isRecaptchaConfigured()) return;

        Test.startTest();
        RegistrationController.createRegistration(
            'MEM-001', 'John', 'Q', 'Doe', 'john@example.com',
            '555-1234', 'Model X', 'Self', 'PartnerA', 'good-token'
        );
        Test.stopTest();

        List<Partner_Promo_List__c> recs = [
            SELECT Name, Contact_ID__c, FirstName__c, MiddleName__c, LastName__c,
                   Email__c, PhoneNumber__c, Model__c, Relationship__c,
                   Partnership__c, Registration_Number__c
            FROM Partner_Promo_List__c
        ];
        System.assertEquals(1, recs.size());
        System.assertEquals('John Doe', recs[0].Name);
        System.assertEquals('john@example.com', recs[0].Email__c);
        System.assertEquals('PartnerA', recs[0].Partnership__c);
        System.assertEquals(1, Integer.valueOf(recs[0].Registration_Number__c));

        Partner_Registration_Counter__c counter = [
            SELECT Count__c FROM Partner_Registration_Counter__c WHERE Partnership__c = 'PartnerA'
        ];
        System.assertEquals(1, Integer.valueOf(counter.Count__c));
    }

    @isTest
    static void testCreateRegistration_incrementsExistingCounter() {
        mockRecaptchaSuccess();
        if (!isRecaptchaConfigured()) return;

        insert new Partner_Registration_Counter__c(
            Partnership__c = 'PartnerB',
            Count__c       = 5
        );

        Test.startTest();
        RegistrationController.createRegistration(
            'MEM-001', 'John', 'Q', 'Doe', 'john@example.com',
            '555-1234', 'Model X', 'Self', 'PartnerB', 'good-token'
        );
        Test.stopTest();

        Partner_Registration_Counter__c counter = [
            SELECT Count__c FROM Partner_Registration_Counter__c WHERE Partnership__c = 'PartnerB'
        ];
        System.assertEquals(6, Integer.valueOf(counter.Count__c));

        Partner_Promo_List__c rec = [
            SELECT Registration_Number__c FROM Partner_Promo_List__c WHERE Partnership__c = 'PartnerB'
        ];
        System.assertEquals(6, Integer.valueOf(rec.Registration_Number__c));
    }

    // ───────────────────────── checkExistingRegistration ───────────────────

    @isTest
    static void testCheckExistingRegistration_falseWhenNoneExist() {
        mockRecaptchaSuccess();
        Boolean exists = RegistrationController.checkExistingRegistration('MEM-001', 'PartnerA');
        System.assertEquals(false, exists);
    }

    @isTest
    static void testCheckExistingRegistration_trueWhenExists() {
        mockRecaptchaSuccess();
        Contact c = [SELECT Id FROM Contact WHERE Membership_ID__c = 'MEM-001' LIMIT 1];

        insert new Partner_Promo_List__c(
            Name           = 'John Doe',
            Contact_ID__c  = c.Id,
            Partnership__c = 'PartnerA'
        );

        Test.startTest();
        Boolean exists = RegistrationController.checkExistingRegistration('MEM-001', 'PartnerA');
        Test.stopTest();

        System.assertEquals(true, exists);
    }

    @isTest
    static void testCheckExistingRegistration_falseForDifferentPartnership() {
        mockRecaptchaSuccess();
        Contact c = [SELECT Id FROM Contact WHERE Membership_ID__c = 'MEM-001' LIMIT 1];

        insert new Partner_Promo_List__c(
            Name           = 'John Doe',
            Contact_ID__c  = c.Id,
            Partnership__c = 'PartnerA'
        );

        Boolean exists = RegistrationController.checkExistingRegistration('MEM-001', 'PartnerC');
        System.assertEquals(false, exists);
    }
}