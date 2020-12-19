public with sharing class RecurringDonationService {
        
    public static Database.QueryLocator getTodaysActiveRecurrings() {
        Date today = System.today();
        String recurringDonationStatusOpen = 'Active'; //Utility.mainSettings.Recurring_Active_Donation_Status__c;
        String query = 'SELECT Amount__c, CustomerId__c, OrderNumber__c, Email__c, RecurringToken__c ';
        query += ' FROM RecurringDonation__c WHERE Status__c =: recurringDonationStatusOpen AND NextPaymentDate__c =: today LIMIT 50000';
        return Database.getQueryLocator(query);
    }
    
    public static void processRecuringDonation(List<DonationStaging__c> stagings){
        System.debug('RecurringDonationService.processRecuringDonation(), stagings = ' + stagings);
        Map<Id, Contact> contacts = ContactService.matchStagingWithContact(stagings);
        System.debug('RecurringDonationService.processRecuringDonation(), contacts = ' + contacts);
        if(!contacts.isEmpty()){
            proceedStagingForContacts(contacts, stagings);
        }
    }
    
    public static List<RecurringDonation__c> getOpenRecurringsByContactIds(List<Id> contactIds) {
        return [SELECT Id, NextPaymentDate__c, Contact__c, PaymentDay__c, LastPaymentDate__c, Staging__c, Staging__r.PaymentType__c, Staging__r.BatchTimestamp__c
                FROM RecurringDonation__c 
                WHERE Contact__c IN: contactIds 
                AND Status__c =: Utility.mainSettings.Recurring_Active_Donation_Status__c
                LIMIT 50000];
    }
    
    private static void proceedStagingForContacts(Map<Id, Contact> contacts, List<DonationStaging__c> stagings){
        Id membershipRT = Utility.getRecordTypeId('Opportunity', Utility.OPP_MEMBERSHIP_RECORD_TYPE);
        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
       // List<RecurringDonation__c> recurrings = new List<RecurringDonation__c>();
        List<Opportunity> exsistOpps = OpportunityService.getActiveOppByContIdsAndRT(new List<Id> (contacts.keyset()), new List<Id> {membershipRT});
        if(exsistOpps.size() != contacts.keySet().size()){
            List<Opportunity> newOpps = OpportunityService.generateMissingOpps(contacts, exsistOpps, Utility.OPP_MEMBERSHIP_RECORD_TYPE);
            insert newOpps;
            exsistOpps = OpportunityService.getActiveOppByContIdsAndRT(new List<Id> (contacts.keyset()), new List<Id> {membershipRT});
        }        
        for(Contact theContact : contacts.values()){
            System.debug('theContact = ' + theContact);
            for(DonationStaging__c theStaging : stagings){
                if (theContact.OrderNumber__c == theStaging.SiteOrderId__c) {
                    for(Opportunity opp : exsistOpps){
                        if(opp.npsp__Primary_Contact__c == theContact.Id){
                            payments.add(DonationService.generatePayment(theStaging, opp.Id, theContact.Id));
                            theStaging.Status__c = Utility.mainSettings.Default_Processed_Staging_Status__c;
                            System.debug('theStaging.Status__c = ' + theStaging.Status__c);
                            // RecurringDonation__c oldRecurring = theContact.RecurringDonations__r[0];
                          //  updateRecurring(oldRecurring, theStaging);
                         //   recurrings.add(oldRecurring);
                            continue;
                        }
                    }
                }
            }
        }
        System.debug('payments = ' + payments);
        System.debug('stagings = ' + stagings);
        insert payments;
        update stagings;
      //  update recurrings;
    }
    
  /*  private static void updateRecurring(RecurringDonation__c recurring, DonationStaging__c theStaging){
        system.debug('updateRecurring: ' + recurring);
            recurring.NextPaymentDate__c = DonationService.getNextPaymentDate(theStaging.PaymentType__c, recurring.PaymentDay__c);
        Date lastPaymentDate = DonationService.getLastPaymentDate(theStaging);
        if(lastPaymentDate != null){
            recurring.LastPaymentDate__c = lastPaymentDate;
        }
    }*/
    
}