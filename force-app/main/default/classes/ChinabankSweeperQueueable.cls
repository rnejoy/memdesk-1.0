global class ChinabankSweeperQueueable implements Queueable, Database.AllowsCallouts {

    @TestVisible
    static Boolean isTestExecution = Test.isRunningTest();
    @TestVisible
    static Boolean bypassTimeWindowForTest = false;

    private Integer recordsProcessed;

    global ChinabankSweeperQueueable() {
        this.recordsProcessed = 0;
    }

    global ChinabankSweeperQueueable(Integer recordsProcessed) {
        this.recordsProcessed = recordsProcessed;
    }

    global void execute(QueueableContext qc) {
 
        Integer hour = Datetime.now().hour();
        Boolean isAllowedWindow = (hour >= 23 || hour <= 3);

        if (!isTestExecution && !bypassTimeWindowForTest && !isAllowedWindow) {
            return;
        }

        List<Contact> conList = [
            SELECT Id
            FROM Contact
            WHERE Chinabank_Application_Reference_Number__c = NULL
              AND Chinabank_Application_Status__c = NULL
              AND Chinabank_Credit_Card_Applied__c = TRUE
              AND Customer_Type__c = 'Executive'
              AND Membership_Type__c IN ('Member', 'Complimentary')
              AND Is_Active__c = TRUE
              AND Membership_Expiry_Date__c >= TODAY
              AND (CreatedDate > 2025-12-13T16:00:00Z OR Biz_Conversion_Date__c > 2025-12-13)
              AND Chinabank_Sweeper_Pushed__c = FALSE
            ORDER BY CreatedDate
            LIMIT 1
        ];

        if (conList.isEmpty()) {
            return; 
        }

        Id currentConId = conList[0].Id;

        try {
            chinabankAPIService.sendToBank(currentConId);
        } catch (Exception e) {
            System.debug('Error processing Contact ' + currentConId + ': ' + e.getMessage());
        } finally {
            update new Contact(Id = currentConId, Chinabank_Sweeper_Pushed__c = true);
        }

        this.recordsProcessed++;

        if (!Test.isRunningTest()) {
            if (this.recordsProcessed < 90) {
                System.enqueueJob(new ChinabankSweeperQueueable(this.recordsProcessed));
            } else {
                System.enqueueJob(new ChinabankSweeperQueueable(0), 5);
            }
        }
    }
}