public class TransactionHelper {
    public static void AddLifetimeTransaction(List<Transaction__c> Transactions) {
        List<Contact> membersToUpdate = new List<Contact>();
        List<Contact> members = new List<Contact>();
        Set<Id> memberIds = new Set<Id>();
        
        for(Transaction__c t : Transactions) {
            memberIds.Add(t.Member__c);
        }
        
        members = getMembers(memberIds);

        for(contact c: members) {
            Id memberId;
            double totalLifetimeTransaction = c.Lifetime_transaction2__c; 
            
            if(totalLifetimeTransaction == null) {
                totalLifetimeTransaction = 0;
            }
            
            for(Transaction__c t : Transactions) {
                if(t.Member__c == c.Id) {
                    memberId = c.Id;
                    
                    totalLifetimeTransaction += t.Order_Total__c;
                }
            }
            
            membersToUpdate.add(new Contact(Id = memberId, Lifetime_transaction2__c = totalLifetimeTransaction));
        }        
    }
    
    private static List<Contact> getMembers(Set<Id> memberIds) {
        return [Select Id, Lifetime_transaction2__c From Contact Where Id in :memberIds];
    }
}