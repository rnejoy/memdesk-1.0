trigger TransactionDetailsTrigger on Transaction_Details__c (before insert) {
    /*Set<Id> tdSet = new Set<Id>();
    for(Transaction_Details__c allTD: Trigger.new){
		tdSet.add(allTD.Id);
    }
    If(Trigger.New.size() > 1){
        TransactionDetailsTriggerBatchHandler tdtbh = new TransactionDetailsTriggerBatchHandler(tdSet);
        Id batchId = Database.executeBatch(tdtbh, 200);
    }
    else{*/
        //TransactionDetailsTriggerBatchHandler tdtbh = new TransactionDetailsTriggerBatchHandler(tdSet);
        //Id batchId = Database.executeBatch(tdtbh, 200);
        TransactionDetailsTriggerHandler.getMemberLookup(Trigger.New);
        //TransactionDetailsTriggerHandler.getMemberLookup(tdSet);
    //}
}