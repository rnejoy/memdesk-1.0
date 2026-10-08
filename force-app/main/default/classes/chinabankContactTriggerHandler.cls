public class chinabankContactTriggerHandler {

    public static void handleAfterInsert(List<Contact> newContacts) {

        List<Id> contactsToProcess = new List<Id>();

        for (Contact c : newContacts) {
            if (
                c.Chinabank_Credit_Card_Applied__c == true &&
                (
                    c.LeadSource == 'Chinabank-Instore' ||
                    c.LeadSource == 'Chinabank-Online'
                )
            ) {
                contactsToProcess.add(c.Id);
            }
        }

        if (!contactsToProcess.isEmpty()) {
            chinabankDelayedDispatcher.schedule(contactsToProcess, 1);
        }
    }

    public static void handleAfterUpdate(
        List<Contact> newContacts,
        Map<Id, Contact> oldMap
    ) {
        List<Id> contactsToProcess = new List<Id>();
    
        for (Contact c : newContacts) {
            Contact oldRecord = oldMap.get(c.Id);
            if (oldRecord == null) {
                continue;
            }
            
            Boolean creditCardApplied = 
                c.Chinabank_Credit_Card_Applied__c == true && 
                oldRecord.Chinabank_Credit_Card_Applied__c == false; 
            
            Boolean applicationStatusIsNull = 
                c.Chinabank_Application_Status__c == null; 
            
            Boolean cbccIDNumberChanged = 
                c.CBCC_ID_Number__c != oldRecord.CBCC_ID_Number__c; 
            
            Boolean scenario1 = 
                creditCardApplied && 
                applicationStatusIsNull && 
                cbccIDNumberChanged;
    
            Boolean mobilePhoneChanged =
            c.MobilePhone != oldRecord.MobilePhone;

            Boolean customerTypeWasExecutive =
                c.Customer_Type__c == 'Executive' &&
                oldRecord.Customer_Type__c == 'Executive';
    
            Boolean creditCardAppliedWasTrue =
                c.Chinabank_Credit_Card_Applied__c == true &&
                oldRecord.Chinabank_Credit_Card_Applied__c == true;
    
            Boolean applicationStatusAllowed =
                c.Chinabank_Application_Status__c == null ||
                c.Chinabank_Application_Status__c == 'IN-PROGRESS';
    
            Boolean scenario2 =
                mobilePhoneChanged &&
                customerTypeWasExecutive &&
                creditCardAppliedWasTrue &&
                applicationStatusAllowed;   
            
            if (scenario1 || scenario2) {
                contactsToProcess.add(c.Id);
            }
        }
    
        if (!contactsToProcess.isEmpty()) {
            chinabankDelayedDispatcher.schedule(contactsToProcess, 1);
        }
    }

}