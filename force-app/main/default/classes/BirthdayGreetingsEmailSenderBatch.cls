public without sharing class BirthdayGreetingsEmailSenderBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        Integer day = Date.today().day();
        Integer month = Date.today().month();
        String query = 'SELECT Email, InternalType__c, RecordType.Name FROM Contact WHERE DAY_IN_MONTH(Birthdate) =: day AND CALENDAR_MONTH(Birthdate) =: month AND Email != null LIMIT 50000';
        Database.QueryLocator ql = Database.getQueryLocator(query);
        return ql;
        
    }
    
    public void execute(Database.BatchableContext BC, List<Contact> contacts){
        ActivityService.sendBirthdayGreetingsEmails(contacts);
    }
    
    public static void finish(Database.BatchableContext bc){
    }
    
    
}