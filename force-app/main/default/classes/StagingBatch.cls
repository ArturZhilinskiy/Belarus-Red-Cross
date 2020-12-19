public without sharing class StagingBatch implements Database.Batchable<sObject> {    
    
    public static Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator ql = StagingService.getNewStagings();
        System.debug('->');
        System.debug(ql);
        System.debug('->');
        return ql;
    }
    
    public static void execute(Database.BatchableContext bc, List<DonationStaging__c> stagings){
        System.debug('?---?');
        System.debug(stagings);

        StagingService.proceedStagingConversion(stagings);
    }
    
    public static void finish(Database.BatchableContext bc){
    }
    
}