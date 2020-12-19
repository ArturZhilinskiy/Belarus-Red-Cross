trigger DonationStagingTrigger on DonationStaging__c (after update) {
    
    private static final String ON_AFTER_UPDATE = 'onAfterUpdate';
    
    if(Trigger.OperationType == TriggerOperation.AFTER_UPDATE) {
        if (DonationStagingHandler.runOnce(ON_AFTER_UPDATE)){
            DonationStagingHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
}