public with sharing class ChinabankResponseController {
    @AuraEnabled(cacheable=true)
    public static API_Integration_Logs__c getLatestPushLog(Id contactId)
    {
        List<API_Integration_Logs__c> logs = [
            SELECT Decrypted_Response_Body__c, CreatedDate
            FROM API_Integration_Logs__c
            WHERE Membership_ID__c = :contactId AND Type__c = 'Push Details'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!logs.isEmpty()) {
            return logs[0];
        }
        return null;
    }
}