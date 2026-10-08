public without sharing class RegistrationController {

    @AuraEnabled
    public static Map<String, String> validateMemberId(String memberId) {
        if (String.isBlank(memberId)) return null;

        List<Contact> contacts = [
            SELECT Id, FirstName, MiddleName, LastName
            FROM Contact
            WHERE Membership_ID__c = :memberId
            LIMIT 1
        ];

        if (contacts.isEmpty()) return null;

        return new Map<String, String>{
            'firstName'  => contacts[0].FirstName  != null ? contacts[0].FirstName  : '',
            'middleName' => contacts[0].MiddleName != null ? contacts[0].MiddleName : '',
            'lastName'   => contacts[0].LastName   != null ? contacts[0].LastName   : ''
        };
    }

    @AuraEnabled
    public static void createRegistration(
        String memberId,
        String firstName,
        String middleName,
        String lastName,
        String email,
        String phoneNumber,
        String model,
        String relationship,
        String partnership,
        String recaptchaToken
    ) {
        RecaptchaController.verify(recaptchaToken, null);

        try {
            Contact member = [
                SELECT Id
                FROM Contact
                WHERE Membership_ID__c = :memberId
                LIMIT 1
            ];

            Integer registrationNumber = getNextRegistrationNumber(partnership);

            Partner_Promo_List__c rec = new Partner_Promo_List__c();
            rec.Name                   = firstName + ' ' + lastName;
            rec.Contact_ID__c          = member.Id;
            rec.FirstName__c           = firstName;
            rec.MiddleName__c          = middleName;
            rec.LastName__c            = lastName;
            rec.Email__c               = email;
            rec.PhoneNumber__c         = phoneNumber;
            rec.Model__c               = model;
            rec.Relationship__c        = relationship;
            rec.Partnership__c         = partnership;
            rec.Registration_Number__c = registrationNumber;
            insert rec;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Integer getNextRegistrationNumber(String partnership) {
        Partner_Registration_Counter__c counter = lockOrCreateCounter(partnership);
        counter.Count__c = (counter.Count__c == null ? 0 : counter.Count__c) + 1;
        update counter;
        return Integer.valueOf(counter.Count__c);
    }

    private static Partner_Registration_Counter__c lockOrCreateCounter(String partnership) {
        List<Partner_Registration_Counter__c> existing = [
            SELECT Id, Count__c
            FROM Partner_Registration_Counter__c
            WHERE Partnership__c = :partnership
            FOR UPDATE
        ];

        if (!existing.isEmpty()) {
            return existing[0];
        }

        try {
            Partner_Registration_Counter__c newCounter = new Partner_Registration_Counter__c(
                Partnership__c = partnership,
                Count__c       = 0
            );
            insert newCounter;
            return newCounter;
        } catch (DmlException e) {
            List<Partner_Registration_Counter__c> raceWinner = [
                SELECT Id, Count__c
                FROM Partner_Registration_Counter__c
                WHERE Partnership__c = :partnership
                LIMIT 1
                FOR UPDATE
            ];
            return raceWinner[0];
        }
    }

    @AuraEnabled
    public static Boolean checkExistingRegistration(String memberId, String partnership) {
        Integer cnt = [
            SELECT COUNT()
            FROM Partner_Promo_List__c
            WHERE Contact_ID__r.Membership_ID__c = :memberId
            AND   Partnership__c                 = :partnership
        ];
        return cnt > 0;
    }

}