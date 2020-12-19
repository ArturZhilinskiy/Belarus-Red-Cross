public with sharing class OpportunityService {
    
    private static final String ERROR_MESSAGE = 'There is an active opportunity for this contact';
    
    public static Opportunity generateOpportunity(String name, String oppRT, Date closeDate, Id accountId, Id contactId) {
        String stageName = oppRT == Utility.OPP_DONATION_RECORD_TYPE ? Utility.mainSettings.Default_Opportunity_Donation_Status__c
            : Utility.mainSettings.Default_Opportunity_Membership_Status__c;
        Opportunity theOpp = new Opportunity();
        theOpp.Name = name;
        theOpp.StageName = stageName;
        theOpp.CloseDate = closeDate;
        theOpp.AccountId = accountId;
        theOpp.ContactId = contactId;
        theOpp.npsp__Primary_Contact__c = contactId;
        theOpp.RecordTypeId = Utility.getRecordTypeId('Opportunity', oppRT);
        return theOpp;
    }
    
    public static List<Opportunity> getActiveOppByContIdsAndRT(List<Id> contIds, List<Id> oppRT){
        return [SELECT Id, npsp__Primary_Contact__c, StageName, AccountId, ContactId FROM Opportunity 
                WHERE npsp__Primary_Contact__c IN : contIds AND IsClosed = FALSE AND RecordTypeId IN : oppRT
                LIMIT 50000]; 
    }
    
    public static List<Opportunity> getActiveOppByContIds(List<Id> contIds){
        Id membershipRT = Utility.getRecordTypeId('Opportunity', Utility.OPP_MEMBERSHIP_RECORD_TYPE);
        Id donationRT = Utility.getRecordTypeId('Opportunity', Utility.OPP_DONATION_RECORD_TYPE);
        List<Id> oppRT = new List<Id> {membershipRT, donationRT};
        return getActiveOppByContIdsAndRT(contIds, oppRT); 
    }
    
    public static void replaceOpportunities(List<Id> contIds){
        Id donationRT = Utility.getRecordTypeId('Opportunity', Utility.OPP_DONATION_RECORD_TYPE);
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        List<Opportunity> oppsToClose = OpportunityService.getActiveOppByContIdsAndRT(contIds, new List<Id> {donationRT});
        changeOppStage(oppsToClose, 'Closed Won');
        
        for (Opportunity theOpp : oppsToClose){
            Opportunity newOpp = generateOpportunity(Utility.OPP_MEMBERSHIP_RECORD_TYPE, Utility.OPP_MEMBERSHIP_RECORD_TYPE, 
                                                     Date.today().addYears(1), 
                                                     theOpp.AccountId, theOpp.npsp__Primary_Contact__c);
            oppsToInsert.add(newOpp);
        }
        insert oppsToInsert;
    }
    
    public static void changeOppStage(List<Opportunity> opps, String stageName){
        for (Opportunity theOpp : opps){
            theOpp.StageName = stageName;
        }
        update opps;
    }
    
    public static List<Opportunity> generateMissingOpps(Map<Id, Contact> contactById, List<Opportunity> exsistOpps, String oppRT){
        System.debug('generateMissingOpps aa');
        Set<Id> tempContIds = new Set<Id>();
        List<Opportunity> newOpps = new List<Opportunity>();
        for(Opportunity theOpp : exsistOpps){
            tempContIds.add(theOpp.npsp__Primary_Contact__c);
        }
        for (Contact contact : contactById.values()) {
            if(!tempContIds.contains(contact.Id)) {
                System.debug('generateMissingOpps if closure');
                Id accountId = contact.Agent__c != null ? contact.Agent__r.AccountId : contact.AccountId;
                Opportunity newOpp = generateOpportunity(oppRT, oppRT, Date.today().addYears(1), accountId, contact.Id);
                System.debug('NEW OPP: '+ newOpp);
                newOpps.add(newOpp);
            }
        }
        return newOpps;
    }
    
}