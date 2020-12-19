public with sharing class RecurringDonationHandler {
    
    private static Map<String, Boolean> actionTypeToRunOnce = new Map<String, Boolean>();
    
    public static Boolean runOnce(String actionType) {
        Boolean runOnce = actionTypeToRunOnce.get(actionType);
        if (runOnce == null || runOnce == TRUE) {
            actionTypeToRunOnce.put(actionType, FALSE);
            return TRUE;
        }
        return FALSE;
    }
    
    public static void onAfterUpdate(List<RecurringDonation__c> newRecurrings, Map<Id, RecurringDonation__c> oldRecurrings) {
        sendEmails(newRecurrings, oldRecurrings);
    }

    public static void onBeforeInsert(List<RecurringDonation__c> newRecurrings){
        List<Id> contactList = new List<Id>(); 
        List<RecurringDonation__c> recDonationsToUpdate = new List<RecurringDonation__c>();
        for(RecurringDonation__c recDonation : newRecurrings){
            contactList.add(recDonation.Contact__c);
        }
        List<RecurringDonation__c> oldRecDonations = [SELECT Id, Name, Status__c FROM RecurringDonation__c WHERE Contact__c =: contactList];
        for(RecurringDonation__c theRecDonation : oldRecDonations){
            if(theRecDonation.Status__c == 'Active'){
                theRecDonation.Status__c = 'Not Active';
                recDonationsToUpdate.add(theRecDonation);
            }
        }
        update recDonationsToUpdate;
    }
    
    private static void sendEmails(List<RecurringDonation__c> newRecurrings, Map<Id, RecurringDonation__c> oldRecurrings) {
        List<Id> contactIds = new List<Id>();
        for(RecurringDonation__c rec : newRecurrings){
            if(rec.Amount__c != oldRecurrings.get(rec.Id).Amount__c && oldRecurrings.get(rec.Id).Amount__c != null && rec.Status__c == 'Active'){
                contactIds.add(rec.Contact__c);
            }else if(rec.PaymentDay__c != oldRecurrings.get(rec.Id).PaymentDay__c && oldRecurrings.get(rec.Id).PaymentDay__c != null && rec.Status__c == 'Active'){
                contactIds.add(rec.Contact__c);
            }
        }
        List<Contact> contacts = [SELECT Email, InternalType__c FROM Contact WHERE Id IN: contactIds AND Email != null LIMIT 50000];
        ActivityService.sendParameterChangesEmails(contacts);
    }
    
}