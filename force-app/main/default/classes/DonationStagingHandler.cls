public with sharing class DonationStagingHandler {
    
    private static Map<String, Boolean> actionTypeToRunOnce = new Map<String, Boolean>();
    
    public static Boolean runOnce(String actionType) {
        Boolean runOnce = actionTypeToRunOnce.get(actionType);
        if (runOnce == null || runOnce == TRUE) {
            actionTypeToRunOnce.put(actionType, FALSE);
            return TRUE;
        }
        return FALSE;
    }
    
    public static void onAfterUpdate(List<DonationStaging__c> newStagings, Map<Id, DonationStaging__c> oldStagings) {
        System.debug('Donationstaginghandler start');
        manageABU(newStagings, oldStagings);
        updateContactFields(newStagings, oldStagings);
        System.debug('Donationstaginghandler end');
    }
    
    private static void manageABU(List<DonationStaging__c> newStagings, Map<Id, DonationStaging__c> oldStagings) {
        Id stagingRTId = Schema.SObjectType.DonationStaging__c.getRecordTypeInfosByName().get('Recurring').getRecordTypeId();
        List<String> orderNumbers = new List<String>();
        Map<Id, Card__c> cardsToUpdate = new Map<Id, Card__c>();
        List<Card__c> cardsToInsert = new List<Card__c>();
        Set<Contact> contactsToUpdate = new Set<Contact>();
        List<DonationStaging__c> targetStagings = new List<DonationStaging__c>();
        for(DonationStaging__c staging : newStagings){
            if(staging.Status__c == 'Processed' && oldStagings.get(staging.Id).Status__c != 'Processed' && staging.RecordTypeId == stagingRTId){
                orderNumbers.add(staging.SiteOrderId__c);
                targetStagings.add(staging);
            }
        }
        List<Contact> contacts = [
            SELECT Id, Number_of_ABU__c, OrderNumber__c,
            (SELECT Status__c, CardNumber__c, ValidThru__c FROM Cards__r WHERE Status__c = 'Active')
            FROM Contact 
            WHERE OrderNumber__c IN: orderNumbers
        ];
        for(DonationStaging__c staging : targetStagings){
            Boolean found = false;
            Contact targetContact = null;
            for(Contact cont : contacts){
                if(cont.OrderNumber__c == staging.SiteOrderId__c){
                    targetContact = cont;
                    for(Card__c theCard : cont.Cards__r){
                        String rcText = staging.RCText__c;
                        //Invalid amount.The card is unbinded at the initiative of the acquirer
                        if(theCard.CardNumber__c == staging.Card__c){
                            found = true;
                        }
                        if(theCard.CardNumber__c == staging.Card__c && rcText != null && rcText.contains('unbinded')){
                            theCard.Status__c = 'Rejected';
                            cardsToUpdate.put(theCard.Id, theCard);
                        }
                    }
                }
            }
            if(!found && targetContact != null){
                for(Card__c card : targetContact.Cards__r){
                    if(card.Status__c == 'Active'){
                        cardsToUpdate.put(card.Id, new Card__c(Id = card.Id, Status__c = 'Not Active'));
                    }
                }
                cardsToInsert.add(InitiatingDonationService.generateCard(staging, targetContact.Id));
                contactsToUpdate.add(new Contact(Id = targetContact.Id, Number_of_ABU__c = targetContact.Number_of_ABU__c == null ? 1 : targetContact.Number_of_ABU__c + 1));
            }
        }
        insert cardsToInsert;
        update new List<Card__c> (cardsToUpdate.values());
        update new List<Contact> (contactsToUpdate);
    }
    
    private static void updateContactFields(List<DonationStaging__c> newStagings, Map<Id, DonationStaging__c> oldStagings) {
        List<String> orderNumbers = new List<String>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
        for(DonationStaging__c staging : newStagings){
            if(staging.Status__c == 'Processed'){
                orderNumbers.add(staging.SiteOrderId__c);
            }
        }
        List<Contact> contacts = [
            SELECT Id, Card_Activity_Status__c, RCText__c, OrderNumber__c,
            (SELECT Status__c, CardNumber__c, ValidThru__c FROM Cards__r WHERE Status__c = 'Active')
            FROM Contact 
            WHERE OrderNumber__c IN: orderNumbers
        ];
        for(DonationStaging__c staging : newStagings){
            for(Contact cont : contacts){
                if(cont.OrderNumber__c == staging.SiteOrderId__c){
                    for(Card__c theCard : cont.Cards__r){
                        if(theCard.CardNumber__c == staging.Card__c){
                            contactsToUpdate.put(cont.Id, new Contact(Id = cont.Id, Card_Activity_Status__c = theCard.Status__c, RCText__c = staging.RCText__c));
                        }
                    }
                }
            }
        }
        update new List<Contact> (contactsToUpdate.values());
    }
    
}