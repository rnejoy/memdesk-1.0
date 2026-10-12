public without sharing class LoginAuthController {

    private static final Map<String, String> STORES = new Map<String, String>{
        '1010' => 'Balintawak', '1020' => 'Otis', '1030' => 'Cebu', '1040' => 'Alabang',
        '1050' => 'Arcovia', '1060' => 'BGC', '1070' => 'Fairview', '1080' => 'UPTC',
        '1090' => 'Angeles', '2010' => 'Nuvali', '2020' => 'Aseana', '2030' => 'Arca',
        '2040' => 'Bacolod', '2050' => 'Naga', '2060' => 'Davao', '2070' => 'Vermosa'
    };

    @AuraEnabled
    public static Boolean userExists(String email) {

        if (String.isBlank(email)) {
            return false;
        }

        String typedEmail = email.trim();

        List<User> users = [
            SELECT Id
            FROM User
            WHERE (Email = :typedEmail OR Username = :typedEmail)
            AND IsActive = true
            LIMIT 1
        ];

        return !users.isEmpty();
    }

    @AuraEnabled
    public static String getStoreByEmail(String email) {
        if (String.isBlank(email)) {
            return null;
        }

        String typedEmail = email.trim();

        List<User> users = [
            SELECT Store_Assigned__c
            FROM User
            WHERE (Email = :typedEmail OR Username = :typedEmail)
            AND IsActive = true
            LIMIT 1
        ];

        if (users.isEmpty() || String.isBlank(users[0].Store_Assigned__c)) {
            return null;
        }

        Matcher m = Pattern.compile('^\\s*(\\d{4})').matcher(users[0].Store_Assigned__c);
        return m.find() ? STORES.get(m.group(1)) : null;
    }
}