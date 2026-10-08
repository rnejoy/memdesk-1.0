trigger chinabankContactTrigger on Contact (after insert, after update) {

    if (Trigger.isAfter) {
    
        if (Trigger.isInsert) {
            chinabankContactTriggerHandler.handleAfterInsert(Trigger.new);
        }
    
        if (Trigger.isUpdate) {
            chinabankContactTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}