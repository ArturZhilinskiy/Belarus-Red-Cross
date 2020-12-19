public with sharing class OneTimeDonationService {
    
    public static void processOneTimeDonation(List<DonationStaging__c> stagings){
        List<Lead> leads = LeadService.matchStagingWithLead(stagings);
        Map<Id, Contact> contacts = ContactService.matchStagingWithContact(stagings);
        System.debug('%^& OneTimeDonationService.processOneTimeDonation(), leads = ' + leads);
        System.debug('%^& OneTimeDonationService.processOneTimeDonation(), stagings = ' + stagings);
        if(!contacts.isEmpty()){
            proceedStagingForContacts(contacts, stagings);
        }
        if (!leads.isEmpty()){
            proceedStagingForLeads(leads, stagings);
        }
        System.debug('%^& OneTimeDonationService.processOneTimeDonation(), ---> final line');
    }    
    
    private static void proceedStagingForContacts(Map<Id, Contact> contacts, List<DonationStaging__c> stagings){
        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
        List<Opportunity> exsistOpps = OpportunityService.getActiveOppByContIds(new List<Id> (contacts.keyset()));
        
        if(exsistOpps.size() < contacts.keySet().size()){
            List<Opportunity> newOpps = OpportunityService.generateMissingOpps(contacts, exsistOpps, Utility.OPP_DONATION_RECORD_TYPE);
            insert newOpps;
            exsistOpps = OpportunityService.getActiveOppByContIds(new List<Id> (contacts.keyset()));
        }
        for(Contact theContact : contacts.values()){
            for(DonationStaging__c theStaging : stagings){
                if (theContact.OrderNumber__c == theStaging.SiteOrderId__c){
                    for(Opportunity opp : exsistOpps){
                        if(opp.npsp__Primary_Contact__c == theContact.Id){
                            npe01__OppPayment__c thePayment = DonationService.generatePayment(theStaging, opp.Id, theContact.Id);
                            payments.add(thePayment);
                            theStaging.Status__c = Utility.mainSettings.Default_Processed_Staging_Status__c;
                            continue;
                        }
                    }
                }
            }
        }
        System.debug('%^& OneTimeDonationService.proceedStagingForContacts(), payments = ' + payments);
        insert payments;
        System.debug('%^& OneTimeDonationService.proceedStagingForContacts(), stagings = ' + stagings);
        update stagings;
    } 
    
    private static void proceedStagingForLeads(List<Lead> leads, List<DonationStaging__c> stagings){
        System.debug('ProceedStagingForLeads: start');
        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
        List<Lead> convertedLeads = LeadService.convertLeads(leads, Utility.CONTACT_DONOR_RECORD_TYPE, 
                                                             Utility.OPP_DONATION_RECORD_TYPE, Utility.OPP_DONATION_RECORD_TYPE);
        System.debug('ProceedStagingForLeads: convertedLeads: ' +convertedLeads);
        for(Lead theLead : convertedLeads){
            for(DonationStaging__c theStaging : stagings){
                if (theLead.OrderNumber__c == theStaging.SiteOrderId__c){
                    System.debug('ProceedStagingForLeads: if clasure');
                    npe01__OppPayment__c thePayment = DonationService.generatePayment(theStaging, theLead.ConvertedOpportunityId, theLead.ConvertedContactId);
                    System.debug('ProceedStagingForLeads: thePayment '+ thePayment);
                    payments.add(thePayment);
                    theStaging.Status__c = Utility.mainSettings.Default_Processed_Staging_Status__c;
                    continue;
                }
            }
        } 
        System.debug('%^& OneTimeDonationService.proceedStagingForLeads(), payments = ' + payments);
        insert payments;
        System.debug('%^& OneTimeDonationService.proceedStagingForLeads(), stagings = ' + stagings);
        update stagings; 
    }
    
}