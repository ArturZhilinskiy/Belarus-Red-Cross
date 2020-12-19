public without sharing class ActivityService {
    
    private static List<OrgWideEmailAddress> donationOwea;
    private static List<OrgWideEmailAddress> f2fOwea;
    private static Integer used;
    private static Integer emailLimit;  
    
    static{
        donationOwea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'donation@redcross.by'];
        f2fOwea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'f2f@redcross.by'];
        used = Limits.getEmailInvocations();
        emailLimit = Limits.getLimitEmailInvocations();
    }
    
    public static void sendCardReactivationEmails(List<Contact> contacts) { 
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: 'Card_Reactivation_Email'];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Contact theCont : contacts){ 
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, null, theCont.Id);
            email.setToAddresses(new List<String>{theCont.Email});
            email.saveAsActivity = FALSE;
            if(!donationOwea.isEmpty() && theCont.InternalType__c == 'Rec General') {
                email.setOrgWideEmailAddressId(donationOwea[0].Id);
            }else if(!f2fOwea.isEmpty() && theCont.InternalType__c == 'Rec F2F'){
                email.setOrgWideEmailAddressId(f2fOwea[0].Id);
            }
            emails.add(email);                
        }
        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
        }
    }
    
    public static List<Contact> prepareContactsForCardReactivationEmailSending(List<Card__c> cards){
        List<Id> contactIds = new List<Id>();
        List<Contact> targetContacts = new List<Contact>();
        for(Card__c card : cards){
            contactIds.add(card.Contact__c);
        }
        List<Contact> contacts = [
            SELECT Email, RecordType.Name, InternalType__c,
            (SELECT Id FROM Cards__r WHERE Status__c = 'Active')
            FROM Contact 
            WHERE Id IN: contactIds
        ];
        for(Contact cont : contacts){
            if(cont.Cards__r != null && cont.Cards__r.size() == 1){
                targetContacts.add(cont);
            }
        }
        return targetContacts;
    }
    
    public static void sendPaymentSuccessEmails(List<Contact> contacts){
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Thanks_for_Payment'];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Contact theCont : contacts){ 
            Date startDate = theCont.ThanksForPaymentEmailSendingDate__c;
            if(theCont.InternalType__c == 'OT General'){
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, null, theCont.Id);
                email.setToAddresses(new List<String>{theCont.Email});
                email.saveAsActivity = FALSE;
                if(!donationOwea.isEmpty()) {
                    email.setOrgWideEmailAddressId(donationOwea[0].Id);
                }
                emails.add(email);                
            }else if(theCont.InternalType__c == 'OT Campaign' && (theCont.ThanksForPaymentEmailSendingDate__c == null || startDate.daysBetween(Date.today()) > 60)){
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, null, theCont.Id);
                email.setToAddresses(new List<String>{theCont.Email});
                email.saveAsActivity = FALSE;
                if(!donationOwea.isEmpty()) {
                    email.setOrgWideEmailAddressId(donationOwea[0].Id);
                }
                emails.add(email);
            }
        }
        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
            Boolean isValid = validateSendEmailErrors(results);
            if(isValid){
                for(Contact theCont : contacts){ 
                    theCont.ThanksForPaymentEmailSendingDate__c = Date.today();
                }
                update contacts;
            }else{
            }
        }
    }
    
    public static void sendBirthdayGreetingsEmails(List<Contact> contacts){
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Birthday_Greetings_Contacts'];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Contact theCont : contacts){ 
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, null, theCont.Id);
            email.setToAddresses(new List<String>{theCont.Email});
            email.saveAsActivity = FALSE;
            if(!donationOwea.isEmpty() && theCont.InternalType__c != 'Rec F2F') {
                email.setOrgWideEmailAddressId(donationOwea[0].Id);
            }else if(!f2fOwea.isEmpty() && theCont.InternalType__c == 'Rec F2F'){
                email.setOrgWideEmailAddressId(f2fOwea[0].Id);
            }
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
        }
    }
    
    public static void sendReactivationUnauthorizedPaymentEmails(List<Lead> leads){
                
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Reactivation_unauthorized_payment'];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Lead theLead : leads){ 
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, null, theLead.Id);
            email.setToAddresses(new List<String>{theLead.Email});
            email.saveAsActivity = FALSE;
            if(!f2fOwea.isEmpty()) {
                email.setOrgWideEmailAddressId(f2fOwea[0].Id);
            }
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
            Boolean isValid = validateSendEmailErrors(results);
            if(isValid){
                for(Lead lead : leads){
                    lead.UnauthorizedPaymentEmailSendDate__c = Date.today();
                }
                update leads;
            }else{
            }
        }
    }
    
    public static void sendLeadToSupporterEmails(List<Lead> leads){
        System.debug('sendLeadToSupporterEmails: ' + leads.size());
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Offer_to_become_supporter_for_lead'];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Lead theLead : leads){ 
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, null, theLead.Id);
            email.setToAddresses(new List<String>{theLead.Email});
            email.saveAsActivity = FALSE;
            if(!donationOwea.isEmpty()) {
                email.setOrgWideEmailAddressId(donationOwea[0].Id);
            }
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
            if(validateSendEmailErrors(results)){
                System.debug('validateSendEmailErrors validated');
                for(Lead lead : leads){
                    lead.LeadToSupporterEmailDate__c = Date.today();
                }
                update leads;
            }
        }
    }
    
    public static void sendParameterChangesEmails(List<Contact> contacts){
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Parameter_Changes'];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Contact theCont : contacts){ 
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, null, theCont.Id);
            email.setToAddresses(new List<String>{theCont.Email});
            email.saveAsActivity = FALSE;
            if(!donationOwea.isEmpty() && theCont.InternalType__c == 'Rec General') {
                email.setOrgWideEmailAddressId(donationOwea[0].Id);
            }else if(!f2fOwea.isEmpty() && theCont.InternalType__c == 'Rec F2F'){
                email.setOrgWideEmailAddressId(f2fOwea[0].Id);
            }
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
        }
    }
    
    private static Boolean validateSendEmailErrors(List<Messaging.SendEmailResult> results){
        Boolean isValid = TRUE;
        for(Messaging.SendEmailResult result : results){
            if (!result.isSuccess()) {
                isValid = FALSE;
                break;
            }
        }
        return isValid;
    }
    
}