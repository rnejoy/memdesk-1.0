trigger TransactionTrigger on Transaction__c (before insert) {
    TransactionTriggerHandler.getMemberLookup(Trigger.New);
}