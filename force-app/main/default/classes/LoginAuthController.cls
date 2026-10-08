public without sharing class LoginAuthController {

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
}