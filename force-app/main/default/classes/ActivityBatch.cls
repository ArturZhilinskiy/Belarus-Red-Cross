public without sharing class ActivityBatch implements Database.Batchable<sObject>, Database.Stateful {    
    
    public static Database.QueryLocator start(Database.BatchableContext bc) {
        String cardStatusOpen = 'Active';
        String query = 'SELECT Contact__c, Contact__r.OwnerId, Contact__r.Email, ValidThru__c FROM Card__c ';
        query += ' WHERE Status__c =: cardStatusOpen AND Contact__r.Email != null AND  ValidThru__c = YESTERDAY LIMIT 50000';
        return Database.getQueryLocator(query);
    }
    
    public static void execute(Database.BatchableContext bc, List<Card__c> cards){
        List<Contact> contacts = ActivityService.prepareContactsForCardReactivationEmailSending(cards);
        ActivityService.sendCardReactivationEmails(contacts);
    }
    
    public static void finish(Database.BatchableContext bc){
    }    
    
}