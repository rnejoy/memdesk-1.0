trigger ContactTrigger on Contact (after insert) {
    if (ContactTriggerHelper.isExecuting) {
        return; // Prevent recursion 'calling itself directly or indirectly'
    }

    try {
        ContactTriggerHelper.isExecuting = true;

        List<Id> contactIdsToProcess = new List<Id>();

        for (Contact contact : Trigger.new) {
            if ((contact.LeadSource == 'store' || contact.LeadSource == 'canvasser' || contact.LeadSource == 'Maya' || contact.LeadSource == 'Chinabank-Instore') 
                && contact.store_signup_code__c != '1000') {
                contactIdsToProcess.add(contact.Id);
            }
        }

        // Call the batch processor with the list of Contact IDs
        if (!contactIdsToProcess.isEmpty()) {
            ContactBatchProcessor batchProcessor = new ContactBatchProcessor(contactIdsToProcess);
            Database.executeBatch(batchProcessor, 200); // Process in batches of 200
        }

    } finally {
        ContactTriggerHelper.isExecuting = false; // Reset static variable
    }
}