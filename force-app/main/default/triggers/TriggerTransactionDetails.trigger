trigger TriggerTransactionDetails on Transaction_Details__c (before insert) {
    if(Trigger.isBefore){
        if(Trigger.IsInsert) {
			TransactionDetailsHelper.ComputeSavingsAndLifeTimePurchase(Trigger.New);       
        }
    }
}