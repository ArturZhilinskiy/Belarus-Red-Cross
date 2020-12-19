public without sharing class RecurringBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {    
    
    public static Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator ql = RecurringDonationService.getTodaysActiveRecurrings();
        return ql;
    }
    
    public static void execute(Database.BatchableContext bc, List<RecurringDonation__c> recurrings){
        System.debug('RecurringBatch.execute();');
        System.debug('Active RecurringDonations - ' + recurrings);
        WebPayDonationRequest.sendPaymentRequest(recurrings);
    }
    
    public static void finish(Database.BatchableContext bc){
    }
    
    
}