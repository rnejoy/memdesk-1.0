public class ChinabankStatusQueueable implements Queueable, Database.AllowsCallouts {
    
    private Integer processedInThisWave = 0;

    public ChinabankStatusQueueable() { this.processedInThisWave = 0; }
    public ChinabankStatusQueueable(Integer count) { this.processedInThisWave = count; }

    public void execute(QueueableContext qc) {
        Integer hourNow = Integer.valueOf(System.now().format('H', 'Asia/Manila'));
        if (!Test.isRunningTest() && (hourNow < 9 || hourNow >= 22)) return;

        List<Contact> contactsToProcess = [
            SELECT Id, Chinabank_Application_Reference_Number__c 
            FROM Contact 
            WHERE Customer_Type__c = 'Executive' 
            AND Is_Active__c = TRUE 
            AND (Chinabank_Application_Status__c = 'IN-PROGRESS' OR Chinabank_Application_Status__c = NULL OR Chinabank_Application_Status__c = 'REFERRED')
            AND Chinabank_Application_Reference_Number__c != NULL
            AND (Chinabank_Status_Pulled__c = FALSE OR Chinabank_Status_Pulled__c = NULL)
            ORDER BY LastModifiedDate ASC 
            LIMIT 50 
        ];

        if (contactsToProcess.isEmpty()) return;

        List<Contact> contactUpdates = new List<Contact>();
        List<API_Integration_Logs__c> allLogs = new List<API_Integration_Logs__c>();
        Map<Id, API_Access_Token__c> tokensToUpdateMap = new Map<Id, API_Access_Token__c>();
        
        String sharedToken = null; 

        for (Contact con : contactsToProcess) {
            try {
                chinabankAPIService.ResultWrapper rw = chinabankAPIService.getApprovalStatusInternal(
                    con.Id, 
                    con.Chinabank_Application_Reference_Number__c, 
                    sharedToken
                );
                
                if (rw.tokenToUpdate != null) {
                    sharedToken = rw.tokenToUpdate.Access_Token__c;
                    tokensToUpdateMap.put(rw.tokenToUpdate.Id, rw.tokenToUpdate);
                }

                if (rw.contactToUpdate != null) {
                    rw.contactToUpdate.Chinabank_Status_Pulled__c = true;
                    contactUpdates.add(rw.contactToUpdate);
                }
                
                if (!rw.logs.isEmpty()) {
                    allLogs.addAll(rw.logs);
                }
                
            } catch (Exception e) {
                System.debug('Failed for Contact ' + con.Id + ': ' + e.getMessage());
            }
        }

        if (!allLogs.isEmpty()) insert allLogs;
        if (!tokensToUpdateMap.isEmpty()) update tokensToUpdateMap.values();
        if (!contactUpdates.isEmpty()) update contactUpdates;

        if (!Test.isRunningTest()) {
            Integer newTotal = this.processedInThisWave + contactsToProcess.size();
            
            if (newTotal < 100 && contactsToProcess.size() == 50) {
                System.enqueueJob(new ChinabankStatusQueueable(newTotal));
            } else {
                System.enqueueJob(new ChinabankStatusQueueable(0), 5);
            }
        }
    }
}