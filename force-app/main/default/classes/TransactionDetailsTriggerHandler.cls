public class TransactionDetailsTriggerHandler {
    //public static void getMemberLookup(Set<Id> idSet) {
    //    List<Transaction_Details__c> newTransactionsDetails = [SELECT Id,Member__c,Transaction__c,Membership_ID__c, Transaction_No__c FROM Transaction_Details__c WHERE Id IN: idSet];
    public static void getMemberLookup(List<Transaction_Details__c> newTransactionsDetails) {
        Set<String> memberId = new Set<String>();
        Set<String> transNo = new Set<String>();
        for(Transaction_Details__c nt:newTransactionsDetails){
            memberId.add(nt.Membership_ID__c);
            transNo.add(nt.Transaction_No__c);
        }
        
        Map<String,Id> memberList = new Map<String,Id>();
        Map<String,Id> transList = new Map<String,Id>();
        System.debug('Transaction Details size: '+memberId.size());
        for(Contact m: [SELECT Id, Membership_ID__c FROM Contact WHERE Membership_ID__c IN :memberId]){
            memberList.put(m.Membership_ID__c, m.Id);
        }
        for(Transaction__c m: [SELECT Id, Name FROM Transaction__c WHERE Name IN :transNo]){
            transList.put(m.Name, m.Id);
        }
        for(Transaction_Details__c nt:newTransactionsDetails){
           	nt.Member__c = memberList.get(nt.Membership_ID__c);
            nt.Transaction__c = transList.get(nt.Transaction_No__c);
        }
    }
}