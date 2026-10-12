@IsTest
private class BpiApplicationController_Test {

    private static final String SIGNUP_STORE = '1040'; // Alabang
    private static final String PICKUP_STORE = '1060'; // BGC

    // ------------------------------------------------------------------
    // Test data
    // ------------------------------------------------------------------

    @TestSetup
    static void setup() {
        insert new List<Province__c>{
            new Province__c(Code__c = 1, Name__c = 'Metro Manila'),
            new Province__c(Code__c = 2, Name__c = 'Cebu'),
            // Junk rows that getProvinces() must hide
            new Province__c(Code__c = 3, Name__c = 'Test 123'),
            new Province__c(Code__c = 4, Name__c = '9999')
        };

        insert new List<City__c>{
            new City__c(Code__c = 10, Name__c = 'Taguig', Province__c = 1),
            new City__c(Code__c = 11, Name__c = 'Makati', Province__c = 1),
            new City__c(Code__c = 20, Name__c = 'Cebu City', Province__c = 2)
        };

        insert new List<Barangay__c>{
            new Barangay__c(Code__c = 100, Name__c = 'Fort Bonifacio', City__c = 10),
            new Barangay__c(Code__c = 101, Name__c = 'Western Bicutan', City__c = 10),
            new Barangay__c(Code__c = 200, Name__c = 'Poblacion', City__c = 11)
        };
    }

    private static BpiApplicationController.ApplicationRequest validRequest() {
        BpiApplicationController.ApplicationRequest r = new BpiApplicationController.ApplicationRequest();
        r.firstName = 'Juan';
        r.middleName = 'Santos';
        r.lastName = 'Dela Cruz';
        r.gender = 'Male';
        r.birthdate = String.valueOf(Date.today().addYears(-30));
        r.maritalStatus = 'Single';
        r.nationality = 'Filipino';
        r.occupation = 'ENGINEER';
        r.mobileNumber = '9945226514';
        r.email = 'juan.delacruz@example.com';
        r.provinceCode = 1;
        r.cityCode = 10;
        r.barangayCode = 100;
        r.street = '123 Test Street';
        r.storeCode = PICKUP_STORE;
        r.signupStoreCode = SIGNUP_STORE;
        r.agreedToTerms = true;
        return r;
    }

    /** Submits the request and returns the error message, or null if it succeeded. */
    private static String submitAndGetError(BpiApplicationController.ApplicationRequest req) {
        try {
            BpiApplicationController.submitApplication(JSON.serialize(req));
            return null;
        } catch (AuraHandledException e) {
            return e.getMessage();
        }
    }

    private static void assertError(BpiApplicationController.ApplicationRequest req, String expected) {
        String msg = submitAndGetError(req);
        System.assertEquals(expected, msg, 'Unexpected result for expected error: ' + expected);
    }

    // ------------------------------------------------------------------
    // Dropdown data
    // ------------------------------------------------------------------

    @IsTest
    static void getStores_returnsAllStores() {
        List<BpiApplicationController.Option> stores = BpiApplicationController.getStores();
        System.assertEquals(15, stores.size());
        System.assertEquals('Balintawak', stores[0].label);
        System.assertEquals('1010', stores[0].value);
    }

    @IsTest
    static void getProvinces_hidesJunkRows() {
        List<BpiApplicationController.Option> options = BpiApplicationController.getProvinces();

        System.assertEquals(2, options.size(), 'Only clean names should be returned.');
        // Ordered by name
        System.assertEquals('Cebu', options[0].label);
        System.assertEquals('2', options[0].value);
        System.assertEquals('Metro Manila', options[1].label);
        System.assertEquals('1', options[1].value);
    }

    @IsTest
    static void getCities_nullProvince_returnsEmpty() {
        System.assertEquals(0, BpiApplicationController.getCities(null).size());
    }

    @IsTest
    static void getCities_returnsCitiesOfProvince() {
        List<BpiApplicationController.Option> options = BpiApplicationController.getCities(1);

        System.assertEquals(2, options.size());
        System.assertEquals('Makati', options[0].label);
        System.assertEquals('11', options[0].value);
        System.assertEquals('Taguig', options[1].label);
        System.assertEquals('10', options[1].value);
    }

    @IsTest
    static void getCities_unknownProvince_returnsEmpty() {
        System.assertEquals(0, BpiApplicationController.getCities(999).size());
    }

    @IsTest
    static void getBarangays_nullCity_returnsEmpty() {
        System.assertEquals(0, BpiApplicationController.getBarangays(null).size());
    }

    @IsTest
    static void getBarangays_returnsBarangaysOfCity() {
        List<BpiApplicationController.Option> options = BpiApplicationController.getBarangays(10);

        System.assertEquals(2, options.size());
        System.assertEquals('Fort Bonifacio', options[0].label);
        System.assertEquals('100', options[0].value);
        System.assertEquals('Western Bicutan', options[1].label);
    }

    // ------------------------------------------------------------------
    // submitApplication: success
    // ------------------------------------------------------------------

    @IsTest
    static void submitApplication_success_createsLeadAndReturnsResult() {
        BpiApplicationController.ApplicationResult result =
            BpiApplicationController.submitApplication(JSON.serialize(validRequest()));

        System.assertNotEquals(null, result);
        System.assert(
            Pattern.matches('BPI' + SIGNUP_STORE + '[A-Z0-9]{5}', result.referenceNumber),
            'Reference number format is wrong: ' + result.referenceNumber
        );
        System.assertEquals('Juan Santos Dela Cruz', result.fullName);
        System.assertEquals('Pending', result.membershipId);
        System.assertEquals('Pay at the Counter - Cash', result.paymentMethod);
        System.assertEquals(0, result.amountToPay);
        System.assertNotEquals(null, result.dateApplied);

        List<Lead> leads = [
            SELECT FirstName, MiddleName, LastName, Email, MobilePhone, LeadSource, Company,
                   Gender__c, Marital_Status__c, Nationality__c, Occupation__c, Country__c,
                   Province__c, City__c, Barangay__c, Street__c,
                   Store_Pickup__c, Store_Pickup_Code__c, Store_Signup__c, Store_Signup_Code__c,
                   Customer_Type__c, Membership_Type__c, Customer_Sub_Type__c, ReferenceNumber__c
            FROM Lead
        ];
        System.assertEquals(1, leads.size());

        Lead l = leads[0];
        System.assertEquals('Juan', l.FirstName);
        System.assertEquals('Santos', l.MiddleName);
        System.assertEquals('Dela Cruz', l.LastName);
        System.assertEquals('juan.delacruz@example.com', l.Email);
        System.assertEquals('09945226514', l.MobilePhone);
        System.assertEquals('BPI', l.LeadSource);
        System.assertEquals('Juan Dela Cruz', l.Company);
        System.assertEquals('Male', l.Gender__c);
        System.assertEquals('Single', l.Marital_Status__c);
        System.assertEquals('Filipino', l.Nationality__c);
        System.assertEquals('ENGINEER', l.Occupation__c);
        System.assertEquals('Philippines', l.Country__c);
        System.assertEquals('Metro Manila', l.Province__c);
        System.assertEquals('Taguig', l.City__c);
        System.assertEquals('Fort Bonifacio', l.Barangay__c);
        System.assertEquals('123 Test Street', l.Street__c);
        System.assertEquals('BGC', l.Store_Pickup__c);
        System.assertEquals(PICKUP_STORE, l.Store_Pickup_Code__c);
        System.assertEquals('Alabang', l.Store_Signup__c);
        System.assertEquals(SIGNUP_STORE, l.Store_Signup_Code__c);
        System.assertEquals('Executive', l.Customer_Type__c);
        System.assertEquals('Member', l.Membership_Type__c);
        System.assertEquals('Primary', l.Customer_Sub_Type__c);
        System.assertEquals(result.referenceNumber, l.ReferenceNumber__c);
    }

    @IsTest
    static void submitApplication_noMiddleName_fullNameHasNoExtraSpace() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.middleName = '   ';

        BpiApplicationController.ApplicationResult result =
            BpiApplicationController.submitApplication(JSON.serialize(req));

        System.assertEquals('Juan Dela Cruz', result.fullName);
    }

    @IsTest
    static void submitApplication_mobileInInternationalFormat_isNormalised() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.mobileNumber = '+63 994 522 6514';

        BpiApplicationController.submitApplication(JSON.serialize(req));

        System.assertEquals('09945226514', [SELECT MobilePhone FROM Lead LIMIT 1].MobilePhone);
    }

    // ------------------------------------------------------------------
    // submitApplication: validation errors
    // ------------------------------------------------------------------

    @IsTest
    static void submitApplication_blankJson_throws() {
        try {
            BpiApplicationController.submitApplication('');
            System.assert(false, 'Expected an exception.');
        } catch (AuraHandledException e) {
            System.assertEquals('Missing application request data.', e.getMessage());
        }
    }

    @IsTest
    static void submitApplication_invalidJson_throws() {
        try {
            BpiApplicationController.submitApplication('{ this is not json');
            System.assert(false, 'Expected an exception.');
        } catch (AuraHandledException e) {
            System.assertEquals('Invalid application data format received.', e.getMessage());
        }
    }

    @IsTest
    static void submitApplication_nullJsonLiteral_throws() {
        try {
            BpiApplicationController.submitApplication('null');
            System.assert(false, 'Expected an exception.');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage() == 'Missing application details.'
                    || e.getMessage() == 'Invalid application data format received.',
                'Unexpected message: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void submitApplication_missingSignupStore_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.signupStoreCode = null;
        assertError(req, 'This application link is not valid. Please scan the QR code at your Landers store to apply.');
    }

    @IsTest
    static void submitApplication_unknownSignupStore_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.signupStoreCode = '9999';
        assertError(req, 'This application link is not valid. Please scan the QR code at your Landers store to apply.');
    }

    @IsTest
    static void submitApplication_termsNotAccepted_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.agreedToTerms = false;
        assertError(req, 'You must agree to the Terms and Conditions and Privacy Policy to apply.');

        req.agreedToTerms = null;
        assertError(req, 'You must agree to the Terms and Conditions and Privacy Policy to apply.');

        System.assertEquals(0, [SELECT COUNT() FROM Lead], 'No lead should be created.');
    }

    @IsTest
    static void submitApplication_missingRequiredFields_throw() {
        BpiApplicationController.ApplicationRequest req;

        req = validRequest();
        req.firstName = '';
        assertError(req, 'First name is required.');

        req = validRequest();
        req.lastName = null;
        assertError(req, 'Last name is required.');

        req = validRequest();
        req.gender = ' ';
        assertError(req, 'Gender is required.');

        req = validRequest();
        req.birthdate = null;
        assertError(req, 'Date of birth is required.');

        req = validRequest();
        req.maritalStatus = '';
        assertError(req, 'Marital status is required.');

        req = validRequest();
        req.nationality = '';
        assertError(req, 'Nationality is required.');

        req = validRequest();
        req.occupation = '';
        assertError(req, 'Occupation is required.');

        req = validRequest();
        req.email = '';
        assertError(req, 'Email is required.');

        req = validRequest();
        req.street = '';
        assertError(req, 'Street address is required.');
    }

    @IsTest
    static void submitApplication_invalidBirthdate_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.birthdate = 'not-a-date';
        assertError(req, 'Please enter a valid date of birth.');
    }

    @IsTest
    static void submitApplication_under18_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.birthdate = String.valueOf(Date.today().addYears(-17));
        assertError(req, 'You must be at least 18 years old to apply.');
    }

    @IsTest
    static void submitApplication_exactly18_isAccepted() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.birthdate = String.valueOf(Date.today().addYears(-18));
        System.assertEquals(null, submitAndGetError(req));
    }

    @IsTest
    static void submitApplication_invalidEmail_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.email = 'not-an-email';
        assertError(req, 'Please enter a valid email address.');
    }

    @IsTest
    static void submitApplication_invalidMobile_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.mobileNumber = '12345';
        assertError(req, 'Please enter a valid mobile number.');

        req.mobileNumber = null;
        assertError(req, 'Please enter a valid mobile number.');
    }

    @IsTest
    static void submitApplication_invalidPickupStore_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.storeCode = '0000';
        assertError(req, 'Please select a valid preferred branch.');
    }

    @IsTest
    static void submitApplication_invalidProvince_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.provinceCode = 999;
        assertError(req, 'Please select a valid province.');
    }

    @IsTest
    static void submitApplication_cityNotInProvince_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.cityCode = 20; // Cebu City belongs to province 2, not 1
        assertError(req, 'Please select a valid city.');
    }

    @IsTest
    static void submitApplication_barangayNotInCity_throws() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        req.barangayCode = 200; // belongs to city 11, not 10
        assertError(req, 'Please select a valid barangay.');
    }

    // ------------------------------------------------------------------
    // submitApplication: save failure
    // ------------------------------------------------------------------

    @IsTest
    static void submitApplication_saveFails_throwsFriendlyError() {
        BpiApplicationController.ApplicationRequest req = validRequest();
        // Far longer than any text field allows, forces a non-duplicate DML failure.
        req.street = 'x'.repeat(200000);

        assertError(req, 'We could not save your application right now. Please try again.');
        System.assertEquals(0, [SELECT COUNT() FROM Lead]);
    }

    // ------------------------------------------------------------------
    // Helper methods
    // ------------------------------------------------------------------

    @IsTest
    static void toLocalMobile_handlesFormats() {
        System.assertEquals('09945226514', BpiApplicationController.toLocalMobile('9945226514'));
        System.assertEquals('09945226514', BpiApplicationController.toLocalMobile('09945226514'));
        System.assertEquals('09945226514', BpiApplicationController.toLocalMobile('639945226514'));
        System.assertEquals('09945226514', BpiApplicationController.toLocalMobile('+63 (994) 522-6514'));

        System.assertEquals(null, BpiApplicationController.toLocalMobile(null));
        System.assertEquals(null, BpiApplicationController.toLocalMobile(''));
        System.assertEquals(null, BpiApplicationController.toLocalMobile('8945226514')); // must start with 9
        System.assertEquals(null, BpiApplicationController.toLocalMobile('994522651'));  // too short
        System.assertEquals(null, BpiApplicationController.toLocalMobile('abcdefghij'));
    }

    @IsTest
    static void isCleanName_acceptsLettersOnly() {
        System.assertEquals(true, BpiApplicationController.isCleanName('Metro Manila'));
        System.assertEquals(true, BpiApplicationController.isCleanName('Dasmariñas'));
        System.assertEquals(false, BpiApplicationController.isCleanName('Test 123'));
        System.assertEquals(false, BpiApplicationController.isCleanName('12345'));
        System.assertEquals(false, BpiApplicationController.isCleanName('---'));
    }

    @IsTest
    static void generateReferenceNumber_hasExpectedFormat() {
        Set<String> seen = new Set<String>();
        for (Integer i = 0; i < 50; i++) {
            String ref = BpiApplicationController.generateReferenceNumber('1080');
            System.assertEquals(12, ref.length());
            System.assert(Pattern.matches('BPI1080[A-Z0-9]{5}', ref), 'Bad format: ' + ref);
            seen.add(ref);
        }
        System.assert(seen.size() > 1, 'Reference numbers should be random.');
    }
}