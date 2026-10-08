public without sharing class MemdeskEditController {

    // SAMPLE ONLY. Replace isManagerBarcode() with a real manager check later
    // (for example, look up the scanned barcode against manager employee records).
    private static final String SAMPLE_OVERRIDE_BARCODE = 'OVERRIDE';
    private static final Boolean REQUIRE_OVERRIDE = false;
    private static Boolean skipBlank = false;

    public class MemberEdit {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String street;
        @AuraEnabled public String province;
        @AuraEnabled public String provinceCode;
        @AuraEnabled public String city;
        @AuraEnabled public String cityCode;
        @AuraEnabled public String barangay;
        @AuraEnabled public String barangayCode;
        @AuraEnabled public String mobile;
        @AuraEnabled public String altMobile;
        @AuraEnabled public String email;
        @AuraEnabled public String occupation;
        @AuraEnabled public String birthdate;      // yyyy-MM-dd
        @AuraEnabled public String nationality;
        @AuraEnabled public String maritalStatus;
        @AuraEnabled public String gender;
        @AuraEnabled public String remarks;
    }

    @AuraEnabled
    public static Boolean verifyOverride(String barcode) {
        return isManagerBarcode(barcode);
    }

    // Returns the names of fields that could not be updated (missing or read-only)
    @AuraEnabled
    public static List<String> saveMember(String memberKey, String overrideBarcode, MemberEdit edit) {
        skipBlank = true;
        if (REQUIRE_OVERRIDE && !isManagerBarcode(overrideBarcode)) {
        }
        if (edit == null) {
            throw buildError('Nothing to save.');
        }
        Id contactId = resolveContactId(memberKey);
        if (contactId == null) {
            throw buildError('That member could not be found.');
        }

        Date birth = null;
        if (String.isNotBlank(edit.birthdate)) {
            try {
                birth = Date.valueOf(edit.birthdate.trim());
            } catch (Exception e) {
                throw buildError('That birthdate is not valid.');
            }
        }

        Map<String, Schema.SObjectField> f = Schema.SObjectType.Contact.fields.getMap();
        List<String> skipped = new List<String>();
        Contact c = new Contact(Id = contactId);

        put(c, f, 'FirstName', clean(edit.firstName, 40), skipped);
        if (String.isNotBlank(edit.lastName)) {
            put(c, f, 'LastName', clean(edit.lastName, 80), skipped);
        }
        put(c, f, 'Street__c', clean(edit.street, 100), skipped);
        put(c, f, 'Province__c', clean(edit.province, 50), skipped);
        put(c, f, 'City__c', clean(edit.city, 50), skipped);
        put(c, f, 'Barangay__c', clean(edit.barangay, 50), skipped);
        putCode(c, f, 'Province_Code__c', edit.provinceCode, skipped);
        putCode(c, f, 'City_Code__c', edit.cityCode, skipped);
        putCode(c, f, 'Barangay_Code__c', edit.barangayCode, skipped);
        put(c, f, 'MobilePhone', clean(edit.mobile, 40), skipped);
        put(c, f, 'Secondary_Mobile_No__c', clean(edit.altMobile, 40), skipped);
        put(c, f, 'Email', clean(edit.email, 80), skipped);
        put(c, f, 'Occupation__c', clean(edit.occupation, 100), skipped);
        put(c, f, 'Birthdate__c', birth, skipped);
        put(c, f, 'Birthdate', birth, skipped);          // standard field, kept in sync
        put(c, f, 'Nationality__c', clean(edit.nationality, 255), skipped);
        put(c, f, 'Marital_Status__c', clean(edit.maritalStatus, 255), skipped);
        put(c, f, 'Gender__c', clean(edit.gender, 255), skipped);
        put(c, f, 'Remarks__c', clean(edit.remarks, 300), skipped);

        try {
            update c;
        } catch (DmlException e) {
            throw buildError(e.getDmlMessage(0));
        }
        return skipped;
    }

    // Clerks can change these any time (no override needed)
    @AuraEnabled
    public static Boolean savePreferences(String memberKey, String reachText, String sourceText) {
        Id contactId = resolveContactId(memberKey);
        if (contactId == null) {
            throw buildError('That member could not be found.');
        }

        Map<String, Schema.SObjectField> f = Schema.SObjectType.Contact.fields.getMap();
        List<String> skipped = new List<String>();
        Contact c = new Contact(Id = contactId);
        put(c, f, 'Customer_How_Reached__c', clean(reachText, 200), skipped);
        put(c, f, 'Customer_Heard_Landers__c', clean(sourceText, 255), skipped);

        try {
            update c;
        } catch (DmlException e) {
            throw buildError(e.getDmlMessage(0));
        }
        return true;
    }

    // ---------- helpers ----------
    private static Boolean isManagerBarcode(String barcode) {
        return !REQUIRE_OVERRIDE || (String.isNotBlank(barcode) && barcode.trim().equalsIgnoreCase(SAMPLE_OVERRIDE_BARCODE));
    }

    private static Id resolveContactId(String memberKey) {
        if (String.isBlank(memberKey)) {
            return null;
        }
        String key = memberKey.trim();
        if (Pattern.matches('003[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?', key)) {
            return (Id) key;
        }
        List<Contact> rows = [SELECT Id FROM Contact WHERE Membership_ID__c = :key LIMIT 1];
        return rows.isEmpty() ? null : rows[0].Id;
    }

    private static String clean(String value, Integer maxLength) {
        if (value == null) {
            return null;
        }
        String t = value.trim();
        if (t == '') {
            return null;
        }
        return t.length() > maxLength ? t.substring(0, maxLength) : t;
    }

    private static void put(SObject record, Map<String, Schema.SObjectField> fields, String apiName, Object value, List<String> skipped) {
        if (skipBlank && value == null) {
            return;
        }
        Schema.SObjectField field = fields.get(apiName);
        if (field == null || !field.getDescribe().isUpdateable()) {
            skipped.add(apiName);
            return;
        }
        record.put(apiName, value);
    }

    // null = leave unchanged, '' = clear, digits = set, anything else (sample list) is ignored
    private static void putCode(SObject record, Map<String, Schema.SObjectField> fields, String apiName, String code, List<String> skipped) {
        if (code == null) {
            return;
        }
        String trimmed = code.trim();
        if (trimmed == '') {
            put(record, fields, apiName, null, skipped);
        } else if (Pattern.matches('\\d{1,9}', trimmed)) {
            put(record, fields, apiName, Decimal.valueOf(trimmed), skipped);
        }
    }

    private static AuraHandledException buildError(String msg) {
        AuraHandledException ex = new AuraHandledException(msg);
        ex.setMessage(msg);
        return ex;
    }
}