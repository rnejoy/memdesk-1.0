public with sharing class premiumApplicationController {

    @TestVisible
    private static final String APPLICANT_OBJECT = 'Lead';

    private static final String STORE_NAME_FIELD = 'Store_Pickup__c';
    private static final String STORE_CODE_FIELD = 'Store_Pickup_Code__c';
    private static final String STORE_SIGNUP_NAME_FIELD = 'Store_Signup__c';
    private static final String STORE_SIGNUP_CODE_FIELD = 'Store_Signup_Code__c';

    private static final String COUNTRY_VALUE = 'Philippines';

    // Lead / confirmation page settings
    private static final String LEAD_SOURCE = 'BPI';
    private static final String REF_PREFIX = 'BPI';
    private static final String REF_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    private static final Integer REF_SERIES_LENGTH = 5;
    private static final Integer MAX_REF_ATTEMPTS = 5;
    private static final Decimal MEMBERSHIP_FEE = 0;
    private static final String PAYMENT_METHOD = 'Pay at the Counter - Cash';

    private static final List<Option> STORES = new List<Option>{
        new Option('Balintawak', '1010'),
        new Option('Otis', '1020'),
        new Option('Cebu', '1030'),
        new Option('Alabang', '1040'),
        new Option('Arcovia', '1050'),
        new Option('BGC', '1060'),
        new Option('UPTC', '1080'),
        new Option('Angeles', '1090'),
        new Option('Nuvali', '2010'),
        new Option('Aseana', '2020'),
        new Option('Arca South', '2030'),
        new Option('Bacolod', '2040'),
        new Option('Naga', '2050'),
        new Option('Davao', '2060'),
        new Option('Vermosa', '2070')
    };

    public class Option {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public Option(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class ApplicationRequest {
        @AuraEnabled public String firstName;
        @AuraEnabled public String middleName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String gender;
        @AuraEnabled public String birthdate;
        @AuraEnabled public String maritalStatus;
        @AuraEnabled public String nationality;
        @AuraEnabled public String occupation;
        @AuraEnabled public String mobileNumber; // 10 digits, e.g. 9945226514
        @AuraEnabled public String email;
        @AuraEnabled public Integer provinceCode;
        @AuraEnabled public Integer cityCode;
        @AuraEnabled public Integer barangayCode;
        @AuraEnabled public String street;
        @AuraEnabled public String storeCode;
        @AuraEnabled public String signupStoreCode; // from the store's QR link (?store=1040)
        @AuraEnabled public Boolean agreedToTerms;
    }

    public class ApplicationResult {
        @AuraEnabled public String referenceNumber;
        @AuraEnabled public String fullName;
        @AuraEnabled public String membershipId;
        @AuraEnabled public String paymentMethod;
        @AuraEnabled public String dateApplied;
        @AuraEnabled public Decimal amountToPay;
    }

    /**
     * Reference data (province / city / barangay) is not sensitive and must be
     * readable by the Guest User on the public site, so these lookups run
     * WITHOUT sharing. Methods are instance methods because Apex does not
     * allow static methods inside an inner class.
     */
    private without sharing class ReferenceData {
        public List<Province__c> provinces() {
            return [
                SELECT Code__c, Name__c
                FROM Province__c
                WHERE Name__c != NULL AND Code__c != NULL
                ORDER BY Name__c
                LIMIT 500
            ];
        }

        public List<City__c> cities(Integer provinceCode) {
            return [
                SELECT Code__c, Name__c
                FROM City__c
                WHERE Province__c = :provinceCode AND Name__c != NULL AND Code__c != NULL
                ORDER BY Name__c
                LIMIT 2000
            ];
        }

        public List<Barangay__c> barangays(Integer cityCode) {
            return [
                SELECT Code__c, Name__c
                FROM Barangay__c
                WHERE City__c = :cityCode AND Name__c != NULL AND Code__c != NULL
                ORDER BY Name__c
                LIMIT 2000
            ];
        }

        public List<Province__c> provinceByCode(Integer code) {
            return [
                SELECT Name__c
                FROM Province__c
                WHERE Code__c = :code
                LIMIT 1
            ];
        }

        public List<City__c> cityByCode(Integer code, Integer provinceCode) {
            return [
                SELECT Name__c
                FROM City__c
                WHERE Code__c = :code AND Province__c = :provinceCode
                LIMIT 1
            ];
        }

        public List<Barangay__c> barangayByCode(Integer code, Integer cityCode) {
            return [
                SELECT Name__c
                FROM Barangay__c
                WHERE Code__c = :code AND City__c = :cityCode
                LIMIT 1
            ];
        }
    }

    // Shared instance used by all methods below.
    private static final ReferenceData REF = new ReferenceData();

    @AuraEnabled(cacheable=true)
    public static List<Option> getStores() {
        return STORES;
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getProvinces() {
        List<Option> options = new List<Option>();
        for (Province__c p : REF.provinces()) {
            // Hide test / junk rows (codes etc.) without deleting the records.
            if (!isCleanName(p.Name__c)) {
                continue;
            }
            options.add(new Option(p.Name__c, String.valueOf(p.Code__c.intValue())));
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getCities(Integer provinceCode) {
        List<Option> options = new List<Option>();
        if (provinceCode == null) {
            return options;
        }
        for (City__c c : REF.cities(provinceCode)) {
            options.add(new Option(c.Name__c, String.valueOf(c.Code__c.intValue())));
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getBarangays(Integer cityCode) {
        List<Option> options = new List<Option>();
        if (cityCode == null) {
            return options;
        }
        for (Barangay__c b : REF.barangays(cityCode)) {
            options.add(new Option(b.Name__c, String.valueOf(b.Code__c.intValue())));
        }
        return options;
    }

    @AuraEnabled
    public static ApplicationResult submitApplication(String requestJson) {
        if (String.isBlank(requestJson)) {
            throw err('Missing application request data.');
        }

        ApplicationRequest request;
        try {
            request = (ApplicationRequest) JSON.deserialize(requestJson, ApplicationRequest.class);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'JSON Deserialization failed: ' + e.getMessage());
            throw err('Invalid application data format received.');
        }

        if (request == null) {
            throw err('Missing application details.');
        }

        // The application must come from a store's QR link.
        Option signupStore = findStoreOrNull(request.signupStoreCode);
        if (signupStore == null) {
            throw err('This application link is not valid. Please scan the QR code at your Landers store to apply.');
        }

        if (request.agreedToTerms != true) {
            throw err('You must agree to the Terms and Conditions and Privacy Policy to apply.');
        }

        String firstName = required(request.firstName, 'First name');
        String lastName = required(request.lastName, 'Last name');
        String gender = required(request.gender, 'Gender');
        String rawBirthdate = required(request.birthdate, 'Date of birth');
        String maritalStatus = required(request.maritalStatus, 'Marital status');
        String nationality = required(request.nationality, 'Nationality');
        String occupation = required(request.occupation, 'Occupation');
        String email = required(request.email, 'Email');
        String street = required(request.street, 'Street address');
        String middleName = String.isBlank(request.middleName) ? null : request.middleName.trim();

        Date parsedBirthdate;
        try {
            parsedBirthdate = Date.valueOf(rawBirthdate);
        } catch (Exception e) {
            throw err('Please enter a valid date of birth.');
        }

        if (parsedBirthdate.addYears(18) > Date.today()) {
            throw err('You must be at least 18 years old to apply.');
        }

        if (!Pattern.matches('^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$', email)) {
            throw err('Please enter a valid email address.');
        }

        String mobile = toLocalMobile(request.mobileNumber);
        if (mobile == null) {
            throw err('Please enter a valid mobile number.');
        }

        // Re-check the address and store on the server so the saved text
        // always matches the real records (and the cascade is respected).
        Option store = findStore(request.storeCode);
        String provinceName = findName(
            REF.provinceByCode(request.provinceCode),
            'province'
        );
        String cityName = findName(
            REF.cityByCode(request.cityCode, request.provinceCode),
            'city'
        );
        String barangayName = findName(
            REF.barangayByCode(request.barangayCode, request.cityCode),
            'barangay'
        );

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(APPLICANT_OBJECT);
        SObject rec = objType.newSObject();
        rec.put('FirstName', firstName);
        if (middleName != null) {
            rec.put('MiddleName', middleName);
        }
        rec.put('LastName', lastName);
        rec.put('Gender__c', gender);
        rec.put('birthdate__c', parsedBirthdate);
        rec.put('Marital_Status__c', maritalStatus);
        rec.put('Nationality__c', nationality);
        rec.put('Occupation__c', occupation);
        rec.put('MobilePhone', mobile); // saved in 09XXXXXXXXX format
        rec.put('Email', email);
        rec.put('Country__c', COUNTRY_VALUE);
        rec.put('Province__c', provinceName);
        rec.put('City__c', cityName);
        rec.put('Barangay__c', barangayName);
        rec.put('Street__c', street);
        rec.put(STORE_NAME_FIELD, store.label);
        rec.put(STORE_CODE_FIELD, store.value);
        rec.put(STORE_SIGNUP_NAME_FIELD, signupStore.label);
        rec.put(STORE_SIGNUP_CODE_FIELD, signupStore.value);
        rec.put('LeadSource', LEAD_SOURCE);

        rec.put('province_code__c', request.provinceCode);
        rec.put('city_code__c', request.cityCode);
        rec.put('barangay_code__c', request.barangayCode);

        rec.put('Customer_Type__c', 'Executive');
        rec.put('Membership_Type__c', 'Member');
        rec.put('Customer_Sub_Type__c', 'Primary');
        if (APPLICANT_OBJECT == 'Lead') {
            rec.put('Company', firstName + ' ' + lastName); // required on Lead
        }

        // Generate the reference number; retry if it collides with an existing one.
        // Requires ReferenceNumber__c to be marked Unique so Salesforce raises DUPLICATE_VALUE.
        String referenceNumber;
        Boolean saved = false;
        for (Integer attempt = 1; attempt <= MAX_REF_ATTEMPTS && !saved; attempt++) {
            referenceNumber = generateReferenceNumber(signupStore.value);
            rec.put('ReferenceNumber__c', referenceNumber);
            try {
                Database.insert(rec, AccessLevel.USER_MODE);
                saved = true;
            } catch (DmlException e) {
                Boolean isDuplicate = e.getNumDml() > 0
                    && e.getDmlType(0) == StatusCode.DUPLICATE_VALUE;
                if (!isDuplicate || attempt == MAX_REF_ATTEMPTS) {
                    System.debug(LoggingLevel.ERROR, 'Executive membership save failed: ' + e.getMessage());
                    throw err('We could not save your application right now. Please try again.');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Executive membership save failed: ' + e.getMessage());
                throw err('We could not save your application right now. Please try again.');
            }
        }

        String fullName = firstName;
        if (middleName != null) {
            fullName += ' ' + middleName;
        }
        fullName += ' ' + lastName;

        ApplicationResult result = new ApplicationResult();
        result.referenceNumber = referenceNumber;
        result.fullName = fullName;
        result.membershipId = 'Pending';
        result.paymentMethod = PAYMENT_METHOD;
        result.dateApplied = Datetime.now().format('MMMM d, yyyy', 'Asia/Manila');
        result.amountToPay = MEMBERSHIP_FEE;
        return result;
    }

    // BPI + 4-digit store SIGN-UP code + 5 random A-Z / 0-9 characters = 12 chars (e.g. BPI1080A1234)
    @TestVisible
    private static String generateReferenceNumber(String storeCode) {
        String series = '';
        for (Integer i = 0; i < REF_SERIES_LENGTH; i++) {
            Integer idx = Math.abs(Math.mod(Crypto.getRandomInteger(), REF_CHARS.length()));
            series += REF_CHARS.substring(idx, idx + 1);
        }
        return REF_PREFIX + storeCode + series;
    }

    @TestVisible
    private static String toLocalMobile(String input) {
        if (String.isBlank(input)) {
            return null;
        }
        String digits = input.replaceAll('[^0-9]', '');
        if (digits.startsWith('63') && digits.length() == 12) {
            digits = digits.substring(2);
        } else if (digits.startsWith('0') && digits.length() == 11) {
            digits = digits.substring(1);
        }
        return Pattern.matches('9[0-9]{9}', digits) ? '0' + digits : null;
    }

    // A real place name has letters and no digits; anything else is treated as junk.
    @TestVisible
    private static Boolean isCleanName(String name) {
        return !Pattern.matches('.*[0-9].*', name) && Pattern.matches('.*[A-Za-z].*', name);
    }

    private static Option findStore(String storeCode) {
        for (Option s : STORES) {
            if (s.value == storeCode) {
                return s;
            }
        }
        throw err('Please select a valid preferred branch.');
    }

    private static Option findStoreOrNull(String storeCode) {
        if (String.isBlank(storeCode)) {
            return null;
        }
        for (Option s : STORES) {
            if (s.value == storeCode.trim()) {
                return s;
            }
        }
        return null;
    }

    private static String findName(List<SObject> rows, String what) {
        if (rows.isEmpty()) {
            throw err('Please select a valid ' + what + '.');
        }
        return (String) rows[0].get('Name__c');
    }

    private static String required(String value, String label) {
        if (String.isBlank(value)) {
            throw err(label + ' is required.');
        }
        return value.trim();
    }

    private static AuraHandledException err(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}