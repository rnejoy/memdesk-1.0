public with sharing class MemdeskMemberController {

    public class MemberDetailWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String membershipId { get; set; }
        @AuraEnabled public String photoUrl { get; set; }
        @AuraEnabled public Boolean isEditable { get; set; }
        @AuraEnabled public String customerType { get; set; }
        @AuraEnabled public String membershipType { get; set; }
        @AuraEnabled public String accountLevel { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String monthsToGo { get; set; }
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String expiryDate { get; set; }
        @AuraEnabled public String membershipPaidDate { get; set; }
        @AuraEnabled public String cardPrintedDate { get; set; }

        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String middleName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String suffix { get; set; }
        @AuraEnabled public String gender { get; set; }

        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String barangay { get; set; }
        @AuraEnabled public String barangayCode { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String cityCode { get; set; }
        @AuraEnabled public String province { get; set; }
        @AuraEnabled public String provinceCode { get; set; }

        @AuraEnabled public Boolean isVatExempt { get; set; }
        @AuraEnabled public String mobileNumber { get; set; }
        @AuraEnabled public String altMobileNumber { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String occupation { get; set; }
        @AuraEnabled public String birthdate { get; set; }
        @AuraEnabled public String nationality { get; set; }
        @AuraEnabled public String maritalStatus { get; set; }
        @AuraEnabled public String remarks { get; set; }

        @AuraEnabled public Boolean reachEmail { get; set; }
        @AuraEnabled public Boolean reachMail { get; set; }
        @AuraEnabled public Boolean reachMobile { get; set; }
        @AuraEnabled public Boolean reachHomePhone { get; set; }

        @AuraEnabled public Boolean sourceWalkIn { get; set; }
        @AuraEnabled public Boolean sourceSalesTeam { get; set; }
        @AuraEnabled public Boolean sourceAds { get; set; }
        @AuraEnabled public Boolean sourceReferral { get; set; }
        @AuraEnabled public Boolean sourceWebsite { get; set; }
    }

    // UI key -> Contact field API name (from your field list).
    // The "Std" keys are standard-field fallbacks used when the custom field is empty.
    private static final Map<String, String> MEMBER_FIELDS = new Map<String, String>{
        'membershipId'    => 'Membership_ID__c',
        'photo'           => 'Picture_Decoded_URL__c',
        'photoAlt'        => 'Picture_URL__c',
        'customerType'    => 'Customer_Type__c',
        'membershipType'  => 'Membership_Type__c',
        'accountLevel'    => 'Customer_Sub_Type__c',
        'isActive'        => 'Is_Active__c',
        'expired'         => 'Expired__c',
        'monthsToGo'      => 'Months_To_Go__c',
        'startDate'       => 'Membership_Start_Date__c',
        'expiryDate'      => 'Membership_Expiry_Date__c',
        'paidDate'        => 'Membership_Paid_Date__c',
        'cardPrintedDate' => 'Membership_Card_Printed_Date__c',
        'firstName'       => 'FirstName',
        'middleName'      => 'MiddleName',
        'lastName'        => 'LastName',
        'suffix'          => 'Suffix',
        'gender'          => 'Gender__c',
        'street'          => 'Street__c',
        'streetStd'       => 'MailingStreet',
        'barangay'        => 'Barangay__c',
        'barangayCode'    => 'Barangay_Code__c',
        'city'            => 'City__c',
        'cityStd'         => 'MailingCity',
        'cityCode'        => 'City_Code__c',
        'province'        => 'Province__c',
        'provinceStd'     => 'MailingState',
        'provinceCode'    => 'Province_Code__c',
        'vatExempt'       => 'Is_VAT_Exempt__c',
        'mobile'          => 'MobilePhone',
        'altMobile'       => 'Secondary_Mobile_No__c',
        'altMobileStd'    => 'OtherPhone',
        'email'           => 'Email',
        'occupation'      => 'Occupation__c',
        'birthdate'       => 'Birthdate__c',
        'birthdateStd'    => 'Birthdate',
        'nationality'     => 'Nationality__c',
        'maritalStatus'   => 'Marital_Status__c',
        'remarks'         => 'Remarks__c',
        'remarksStd'      => 'Description',
        'reachText'       => 'Customer_How_Reached__c',
        'sourceText'      => 'Customer_Heard_Landers__c'
    };

    // Not cacheable on purpose, so Refresh and Save always show current data
    @AuraEnabled
    public static MemberDetailWrapper getMemberDetails(String memberKey, String recordType) {
        if (String.isBlank(memberKey)) {
            return null;
        }
        String key = memberKey.trim();
        return recordType == 'Lead' ? getLeadDetails(key) : getContactDetails(key);
    }

    private static MemberDetailWrapper getContactDetails(String key) {
        Map<String, Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap();
        Set<String> selectFields = new Set<String>{ 'Id' };
        Map<String, String> found = new Map<String, String>();

        for (String uiKey : MEMBER_FIELDS.keySet()) {
            String apiName = MEMBER_FIELDS.get(uiKey);
            Schema.SObjectField field = contactFields.get(apiName);
            if (field != null) {
                found.put(uiKey, apiName);
                selectFields.add(apiName);
            }
        }

        Boolean looksLikeId = Pattern.matches('003[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?', key);
        String soql = 'SELECT ' + String.join(new List<String>(selectFields), ', ')
            + ' FROM Contact WHERE '
            + (looksLikeId ? '(Id = :key OR Membership_ID__c = :key)' : 'Membership_ID__c = :key')
            + ' LIMIT 1';

        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) {
            return null;
        }

        SObject record = rows[0];
        Map<String, Object> v = new Map<String, Object>();
        for (String uiKey : found.keySet()) {
            v.put(uiKey, record.get(found.get(uiKey)));
        }

        MemberDetailWrapper d = new MemberDetailWrapper();
        d.id = String.valueOf(record.Id);
        d.isEditable = true;
        d.membershipId = firstOf(text(v, 'membershipId'), d.id);
        d.photoUrl = firstOf(text(v, 'photo'), text(v, 'photoAlt'));
        d.customerType = text(v, 'customerType');
        d.membershipType = text(v, 'membershipType');
        d.accountLevel = text(v, 'accountLevel');

        if (v.containsKey('isActive') || v.containsKey('expired')) {
            d.status = flag(v, 'expired') ? 'EXPIRED' : (flag(v, 'isActive') ? 'ACTIVE' : 'INACTIVE');
        }

        d.monthsToGo = text(v, 'monthsToGo');
        d.startDate = iso(v, 'startDate');
        d.expiryDate = iso(v, 'expiryDate');
        d.membershipPaidDate = iso(v, 'paidDate');
        d.cardPrintedDate = iso(v, 'cardPrintedDate');

        d.firstName = text(v, 'firstName');
        d.middleName = text(v, 'middleName');
        d.lastName = text(v, 'lastName');
        d.suffix = text(v, 'suffix');
        d.gender = text(v, 'gender');

        d.street = firstOf(text(v, 'street'), text(v, 'streetStd'));
        d.barangay = text(v, 'barangay');
        d.barangayCode = text(v, 'barangayCode');
        d.city = firstOf(text(v, 'city'), text(v, 'cityStd'));
        d.cityCode = text(v, 'cityCode');
        d.province = firstOf(text(v, 'province'), text(v, 'provinceStd'));
        d.provinceCode = text(v, 'provinceCode');

        d.isVatExempt = flag(v, 'vatExempt');
        d.mobileNumber = text(v, 'mobile');
        d.altMobileNumber = firstOf(text(v, 'altMobile'), text(v, 'altMobileStd'));
        d.email = text(v, 'email');
        d.occupation = text(v, 'occupation');
        d.birthdate = firstOf(iso(v, 'birthdate'), iso(v, 'birthdateStd'));
        d.nationality = text(v, 'nationality');
        d.maritalStatus = text(v, 'maritalStatus');
        d.remarks = firstOf(text(v, 'remarks'), text(v, 'remarksStd'));

        Set<String> reach = tokens(text(v, 'reachText'));
        d.reachEmail = reach.contains('email');
        d.reachMail = reach.contains('mailservice');
        d.reachMobile = reach.contains('mobilephone') || reach.contains('mobile');
        d.reachHomePhone = reach.contains('homephone');

        Set<String> source = tokens(text(v, 'sourceText'));
        d.sourceWalkIn = source.contains('walkin');
        d.sourceSalesTeam = source.contains('salesteam');
        d.sourceAds = source.contains('ads');
        d.sourceReferral = source.contains('referral');
        d.sourceWebsite = source.contains('website');

        return d;
    }

    private static MemberDetailWrapper getLeadDetails(String key) {
        if (!Pattern.matches('00Q[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?', key)) {
            return null;
        }
        List<Lead> leads = [
            SELECT Id, FirstName, MiddleName, LastName, MobilePhone, Email, Status, Street, City, State
            FROM Lead
            WHERE Id = :key
            LIMIT 1
        ];
        if (leads.isEmpty()) {
            return null;
        }

        Lead l = leads[0];
        MemberDetailWrapper d = new MemberDetailWrapper();
        d.id = l.Id;
        d.membershipId = l.Id;
        d.isEditable = false;
        d.firstName = l.FirstName;
        d.middleName = l.MiddleName;
        d.lastName = l.LastName;
        d.mobileNumber = l.MobilePhone;
        d.email = l.Email;
        d.status = l.Status;
        d.street = l.Street;
        d.city = l.City;
        d.province = l.State;
        d.customerType = 'LEAD';
        d.membershipType = 'PROSPECT';
        return d;
    }

    // ---------- helpers ----------
    private static String text(Map<String, Object> v, String key) {
        Object o = v.get(key);
        if (o == null) {
            return null;
        }
        String s = String.valueOf(o).trim();
        return s == '' ? null : s;
    }

    private static String iso(Map<String, Object> v, String key) {
        Object o = v.get(key);
        if (o == null) {
            return null;
        }
        if (o instanceof Date) {
            return String.valueOf((Date) o);
        }
        if (o instanceof Datetime) {
            return ((Datetime) o).format('yyyy-MM-dd');
        }
        return String.valueOf(o);
    }

    private static Boolean flag(Map<String, Object> v, String key) {
        Object o = v.get(key);
        return (o instanceof Boolean) && (Boolean) o;
    }

    private static String firstOf(String a, String b) {
        return String.isNotBlank(a) ? a : b;
    }

    // "Email, Mail Service" -> {'email', 'mailservice'}
    private static Set<String> tokens(String raw) {
        Set<String> result = new Set<String>();
        if (String.isBlank(raw)) {
            return result;
        }
        for (String part : raw.split('[;,|/]')) {
            String t = part.toLowerCase().replaceAll('[^a-z0-9]', '');
            if (t != '') {
                result.add(t);
            }
        }
        return result;
    }
}