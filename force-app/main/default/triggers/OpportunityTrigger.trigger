trigger OpportunityTrigger on Opportunity (before insert) {
    
    private static final String ON_BEFORE_INSERT = 'onBeforeInsert';
    
    if(Trigger.operationType == TriggerOperation.BEFORE_INSERT) {
        if (OpportunityHandler.runOnce(ON_BEFORE_INSERT)){
        }
    }
    
}