public class TransactionTriggerHandler {
    public static void getMemberLookup(List<Transaction__c> newTransactions) {
        Set<String> memberId = new Set<String>();
        for(Transaction__c nt:newTransactions){
            memberId.add(nt.Membership_ID__c);
        }
        Map<String,Id> memberList = new Map<String,Id>();
        System.debug(memberId.size());
        for(Contact m: [SELECT Id, Membership_ID__c FROM Contact WHERE Membership_ID__c IN :memberId]){
            memberList.put(m.Membership_ID__c, m.Id);
        }
        for(Transaction__c nt:newTransactions){
            if(nt.Membership_ID__c != null){
            	nt.Member__c = memberList.get(nt.Membership_ID__c);    
            }
        }
    }
}