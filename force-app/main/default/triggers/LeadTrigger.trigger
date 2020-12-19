trigger LeadTrigger on Lead (before insert, after insert) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            LeadHandler.onBeforeInsert(Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LeadHandler.onAfterInsert(Trigger.new);
        }
    }
    
}