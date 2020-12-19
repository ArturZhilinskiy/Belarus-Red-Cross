public without sharing class ReactivationPaymentBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        Integer day = Date.today().day();
        Integer month = Date.today().month();
        String query = 'SELECT Email, UnauthorizedPaymentEmailSendDate__c FROM Lead WHERE UnauthorizedPaymentEmailSendDate__c = null AND IsConverted = FALSE AND CreatedDate = YESTERDAY AND PaymentDay__c != null AND Email != null LIMIT 50000';
        Database.QueryLocator ql = Database.getQueryLocator(query);
        return ql;
    }
    
    public void execute(Database.BatchableContext BC, List<Lead> leads){
        List<Lead> targetLeads = new List<Lead>();
        List<String> allEmails = new List<String>();
        List<String> contactEmails = new List<String>();
        for(Lead theLead : leads){
            allEmails.add(theLead.email);
        }
        List<Contact> contacts = [SELECT Email FROM Contact WHERE Email IN: allEmails LIMIT 50000];
        for(Contact cont : contacts){
            contactEmails.add(cont.Email);
        }
        for(Lead theLead : leads){
            if(!contactEmails.contains(theLead.Email)){
                targetLeads.add(theLead);
            }
        }
        ActivityService.sendReactivationUnauthorizedPaymentEmails(leads);
    }
    
    public static void finish(Database.BatchableContext bc){
    }
    
    
}