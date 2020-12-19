public with sharing class InitiatingDonationService {   
    
    public static void processInitiatingDonation(List<DonationStaging__c> stagings){
        List<Lead> leads = LeadService.matchStagingWithLead(stagings);
        Map<Id, Contact> contacts = ContactService.matchStagingWithContact(stagings);
        if(!contacts.isEmpty()){
            proceedStagingForContacts(contacts, stagings);
        }
        if (!leads.isEmpty()){
            proceedStagingForLeads(leads, stagings);
        }
    }
    
    private static void proceedStagingForContacts(Map<Id, Contact> contacts, List<DonationStaging__c> stagings){
        Id contactSupporterRT = Utility.getRecordTypeId('Contact', Utility.CONTACT_SUPPORTER_RECORD_TYPE);
        Id oppMembershipRT = Utility.getRecordTypeId('Opportunity', Utility.OPP_MEMBERSHIP_RECORD_TYPE);
        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
        List<RecurringDonation__c> recurrings = new List<RecurringDonation__c>();
        List<Card__c> cards = new List<Card__c>();
        OpportunityService.replaceOpportunities(new List<Id>(contacts.keyset()));
        List<Opportunity> exsistOpps = OpportunityService.getActiveOppByContIdsAndRT(new List<Id>(contacts.keyset()), new List<Id> {oppMembershipRT});
        
        if(exsistOpps.size() < contacts.keySet().size()){
            List<Opportunity> newOpps = OpportunityService.generateMissingOpps(contacts, exsistOpps, Utility.OPP_MEMBERSHIP_RECORD_TYPE);
            insert newOpps;
            exsistOpps = OpportunityService.getActiveOppByContIdsAndRT(new List<Id>(contacts.keyset()), new List<Id> {oppMembershipRT});
        }
        deactivateRecurrings(new List<Id>(contacts.keyset()));
        deactivateCards(new List<Id>(contacts.keyset()));
        
        for(Contact theContact : contacts.values()){
            theContact.RecordTypeId = contactSupporterRT;
            for(DonationStaging__c theStaging : stagings){
                if (theContact.OrderNumber__c == theStaging.SiteOrderId__c){
                    for(Opportunity opp : exsistOpps){
                        if(opp.npsp__Primary_Contact__c == theContact.Id){
                            payments.add(DonationService.generatePayment(theStaging, opp.Id, theContact.Id));
                            recurrings.add(generateRecurring(theStaging, theContact.Id, theContact.PaymentDay__c));
                            cards.add(generateCard(theStaging, theContact.Id));
                            theStaging.Status__c = Utility.mainSettings.Default_Processed_Staging_Status__c;
                            continue;
                        }
                    }
                }
            }
        }
        insert cards;
        insert recurrings;
        for(Integer i=0; i<cards.size(); i++){
            payments[i].Card__c = cards[i].Id;
        }
        insert payments;
        update stagings;
        update contacts.values();
    } 
    
    private static void proceedStagingForLeads(List<Lead> leads, List<DonationStaging__c> stagings){
        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
        List<RecurringDonation__c> recurrings = new List<RecurringDonation__c>();
        List<Card__c> cards = new List<Card__c>();
        List<Lead> convertedLeads = LeadService.convertLeads(leads, Utility.CONTACT_SUPPORTER_RECORD_TYPE, 
                                                             Utility.OPP_MEMBERSHIP_RECORD_TYPE, Utility.OPP_MEMBERSHIP_RECORD_TYPE);
        for(Lead theLead : convertedLeads){
            for(DonationStaging__c theStaging : stagings){
                if (theLead.OrderNumber__c == theStaging.SiteOrderId__c){
                    payments.add(DonationService.generatePayment(theStaging, theLead.ConvertedOpportunityId, theLead.ConvertedContactId));
                    cards.add(generateCard(theStaging, theLead.ConvertedContactId));
                    recurrings.add(generateRecurring(theStaging, theLead.ConvertedContactId, theLead.PaymentDay__c));
                    theStaging.Status__c = Utility.mainSettings.Default_Processed_Staging_Status__c;
                    continue;
                }
            }
        } 
        insert cards;
        insert recurrings;
        for(Integer i=0; i<cards.size(); i++){
            payments[i].Card__c = cards[i].Id;
        }
        insert payments;
        update stagings;
    }
    
    private static RecurringDonation__c generateRecurring(DonationStaging__c staging, Id contId, Decimal paymentDay){
        System.debug('generate recurring for staging: ' + staging);
        RecurringDonation__c recurring = new RecurringDonation__c();
        recurring.Amount__c = staging.Amount__c;
        recurring.Staging__c = staging.Id;
        recurring.Contact__c = contId;
        recurring.RecurringToken__c = staging.RecurringToken__c;
        recurring.OfferExpDate__c = staging.OfferExpDate__c != null ? Date.valueOf(staging.OfferExpDate__c) : Date.today().addYears(1); 
       /* recurring.LastPaymentDate__c = DonationService.getLastPaymentDate(staging);
        if(Utility.SUCCESS_PAYMENT_TYPES.contains(staging.PaymentType__c)){
           recurring.NextPaymentDate__c = DonationService.getNextPaymentDate(staging.PaymentType__c, paymentDay);
        }*/
        System.debug('generate recurring: recurring' + recurring);
        return recurring;
    }
    
    public static Card__c generateCard(DonationStaging__c staging, Id contId){
        Card__c card = new Card__c();
        card.CardNumber__c = staging.Card__c;
        card.Staging__c = staging.Id;
        card.ValidThru__c = String.isBlank(staging.OfferExpDate__c) ? null : Date.valueOf(staging.OfferExpDate__c);
        card.Contact__c = contId;
        return card;
    }
    
    private static void deactivateRecurrings(List<Id> contIds){
        List<RecurringDonation__c> recurrings = getRecurringsByContIdAndStatus(contIds, 'Open');
        for (RecurringDonation__c recurring : recurrings){
            recurring.Status__c = 'Closed';
        }
        update recurrings;
    }
    
    private static void deactivateCards(List<Id> contIds){
        List<Card__c> cards = getCardsByContIdAndStatus(contIds, 'Active');
        for (Card__c theCard : cards){
            theCard.Status__c = 'Not Active';
        }
        update cards;
    }
    
    private static List<RecurringDonation__c> getRecurringsByContIdAndStatus(List<Id> contIds, String status){
        return [SELECT Id, Status__c FROM RecurringDonation__c WHERE Contact__c IN: contIds AND Status__c =: status];
    }
    
    private static List<Card__c> getCardsByContIdAndStatus(List<Id> contIds, String status){
        return [SELECT Id, Status__c FROM Card__c WHERE Contact__c IN: contIds AND Status__c =: status];
    }
    
}