public class TransactionDetailsHelper {
    public static void ComputeSavingsAndLifeTimePurchase(List<Transaction_Details__c> TransactionDetails) {
        List<Contact> membersToUpdate = new List<Contact>();
        List<Contact> members = new List<Contact>();
        Set<Id> memberIds = new Set<Id>();

        for(Transaction_Details__c td : TransactionDetails) {
            memberIds.Add(td.Member__c);
        }
        
		members = getMembers(memberIds);
        
        for(contact c: members) {
            if (c.Customer_Sub_Type__c == 'Primary') {
                Id memberId;
                double totalMemberSavings = c.Member_savings__c; 
                double totalLifeTimePurchase = c.Lifetime_transaction2__c;
                
                if(totalMemberSavings == null) {
                    totalMemberSavings = 0;
                }
                
                if(totalLifeTimePurchase == null) {
                    totalLifeTimePurchase = 0;
                }
                
                for(Transaction_Details__c td : TransactionDetails) {
                    if(td.Member__c == c.Id) {
                        memberId = c.Id;
                        
                        if(td.Savings__c == null) {
                            td.Savings__c = 0;
                        }
                        
                        totalMemberSavings += td.Savings_in_Peso__c;
                        totalLifeTimePurchase += td.Subtotal__c;
                    }
                }
                
                membersToUpdate.add(new Contact(Id = memberId, Member_savings__c = totalMemberSavings, Lifetime_transaction2__c = totalLifeTimePurchase));  
            }
        }
        
        if(membersToUpdate.size() > 0) {
            update membersToUpdate;
        }
    }
    
    private static List<Contact> getMembers(Set<Id> memberIds) {
        return [Select Id, Member_savings__c, Lifetime_transaction2__c, Customer_Sub_Type__c From Contact Where Id in :memberIds];
    }
}