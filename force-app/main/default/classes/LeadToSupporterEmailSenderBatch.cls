public without sharing class LeadToSupporterEmailSenderBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public static Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Email, LeadToSupporterEmailDate__c FROM Lead WHERE IsConverted = FALSE AND Email != null AND (LeadToSupporterEmailDate__c = null OR LeadToSupporterEmailDate__c < LAST_N_YEARS:1) LIMIT 50000';
        Database.QueryLocator ql = Database.getQueryLocator(query);
        return ql;
    }
    
    public static void execute(Database.BatchableContext bc, List<Lead> leads){
        ActivityService.sendLeadToSupporterEmails(leads);
    }
    
    public static void finish(Database.BatchableContext bc){
    }
    
}