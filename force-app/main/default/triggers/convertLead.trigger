trigger convertLead on Lead (after update) {
    convertLead.processLeadConversion(trigger.newMap, trigger.oldMap);
}