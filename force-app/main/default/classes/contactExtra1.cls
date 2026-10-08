public with sharing class contactExtra1 {

    @AuraEnabled
    public static Contact getContactRec(String conId) {
        System.Debug('conId :>> ' + conId);
        Contact con = [SELECT Id,
                            FirstName,
                            Birthdate__c,
                            Membership_Expiry_Date__c
                        FROM Contact
                        WHERE Id =: conId];
        return con;
    }

    @AuraEnabled
    public static Lead getLeadRec(String conId) {
        System.Debug('conId :>> ' + conId);
        Lead ld = [SELECT Id,
                        LeadSource,
                        Canvasser_Name__c,
                        Store_Pickup__c,
                        Store_Signup__c
                    FROM Lead
                    WHERE ConvertedContactId =: conId];
        return ld;
    }
}