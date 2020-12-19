trigger RecurringDonationTrigger on RecurringDonation__c (after update, before insert) {

private static final String ON_AFTER_UPDATE = 'onAfterUpdate';
private static final String ON_BEFORE_INSERT = 'onBeforeInsert';
    
    if(Trigger.isUpdate && Trigger.isAfter) {
        if (RecurringDonationHandler.runOnce(ON_AFTER_UPDATE)){
            RecurringDonationHandler.onAfterUpdate(Trigger.new, Trigger.OldMap);
        }
    } 
    if(Trigger.isInsert && Trigger.isBefore){
        if(RecurringDonationHandler.runOnce(ON_BEFORE_INSERT)){
            RecurringDonationHandler.onBeforeInsert(Trigger.new);
        }
    }

}