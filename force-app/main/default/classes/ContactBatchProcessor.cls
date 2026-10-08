public class ContactBatchProcessor implements Database.Batchable<Contact> {
    private List<Id> contactIds;

    public ContactBatchProcessor(List<Id> contactIds) {
        this.contactIds = contactIds;
    }

    public List<Contact> start(Database.BatchableContext bc) {
        // Fetch a chunk of contacts using the provided Contact IDs
        return [SELECT Id, Email, FirstName, MiddleName, LastName, membership_id__c, Membership_Expiry_Date__c 
                FROM Contact WHERE Id IN :contactIds 
                LIMIT 200];
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> batch) {
        for (Contact contact : batch) {
            try {
                OnlineCreation.sendPayload(contact.Id);
            } catch (Exception e) {
                System.debug('Error for Contact ID ' + contact.Id + ': ' + e.getMessage());
                contact.Auto_Create__c = false;
                // Update failed contact records
                update contact;
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // Optional: handle final logic after batch processing
    }
}