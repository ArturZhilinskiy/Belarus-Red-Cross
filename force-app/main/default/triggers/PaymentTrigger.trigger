trigger PaymentTrigger on npe01__OppPayment__c (after insert) {
    
    private static final String ON_AFTER_INSERT = 'onAfterInsert';
    
    if(Trigger.isInsert && Trigger.isAfter) {
        if (PaymentHandler.runOnce(ON_AFTER_INSERT)){
            PaymentHandler.onAfterInsert(Trigger.newMap);
        }
    } 
    
}