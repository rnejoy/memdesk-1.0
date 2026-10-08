trigger afterLeadInserted on Lead (after insert) {
    afterLeadInserted.processNewRecord(trigger.New);
}