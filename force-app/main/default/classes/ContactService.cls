public with sharing class ContactService {

    public static Boolean duplicate = false;

    public static final Map<String, String> INTERNALTYPES = new Map<String, String>{
                                                                            'DonationOneTime' => 'OT General',
                                                                            'DonationRecure' => 'Rec General',
                                                                            'ElkaCamp' => 'OT Campaign',
                                                                            'F2F' => 'Rec F2F'};
    
    public static Map<Id, Contact> matchStagingWithContact(List<DonationStaging__c> stagings){
        List<String> siteOrderIds = new List<String>();
        for(DonationStaging__c staging : stagings){
            siteOrderIds.add(staging.SiteOrderId__c);
        } 
        return getContactsBySiteOrderId(siteOrderIds);
    }
    
    public static Contact generateContactFromLead(Lead theLead, String contRt, Map <String, Contact> contactMapToUpdate) {
        Contact theContact = new Contact();
        if(contactMapToUpdate.containsKey(theLead.Email)){
            Contact contactToUpdate = contactMapToUpdate.get(theLead.Email);
            theContact = updateContactFromLead(contactToUpdate, theLead, contRt);
            theContact.Id = contactToUpdate.Id;
            duplicate = true;
        } else{
            theContact = insertContactFromLead(theLead, contRt);
        }
        return theContact;  
    }

    public static Contact insertContactFromLead(Lead theLead, String contRt){
        Contact theContact = new Contact();
        theContact.CustomerId__c = theLead.CustomerId__c;
        theContact.OrderNumber__c = theLead.OrderNumber__c;
        theContact.FirstName = theLead.FirstName;
        theContact.LastName = theLead.LastName;
        theContact.Email = theLead.Email;
        theContact.Phone = theLead.Phone;
        theContact.Birthdate = theLead.Birthday__c;
        theContact.Address__c = theLead.Address__c;
        theContact.PaymentDay__c = theLead.PaymentDay__c;
        theContact.Agent__c = theLead.Agent__c; 
        theContact.AgentId__c = theLead.AgentId__c;
        theContact.RecordTypeId = Utility.getRecordTypeId('Contact', contRt);
        theContact.AccountId = theLead.Agent__c != null ? theLead.Agent__r.AccountId : null;
        theContact.LeadSource = theLead.LeadSource;
        theContact.LeadCreationDate__c = theLead.CreatedDate;
        theContact.InternalType__c = getInternalType(theContact, theLead);
        return theContact;
    }

    public static Contact updateContactFromLead(Contact contactToUpdate, Lead theLead, String contRt){
        contactToUpdate.CustomerId__c = theLead.CustomerId__c;
        contactToUpdate.OrderNumber__c = theLead.OrderNumber__c;
        contactToUpdate.FirstName = theLead.FirstName;
        contactToUpdate.LastName = theLead.LastName;
        contactToUpdate.Phone = theLead.Phone;
        contactToUpdate.Address__c  = theLead.Address__c;
        contactToUpdate.Agent__c = theLead.Agent__c;
        contactToUpdate.AgentId__c = theLead.AgentId__c;
        contactToUpdate.AccountId = theLead.Agent__c != null ? theLead.Agent__r.AccountId : contactToUpdate.AccountId;
        contactToUpdate.InternalType__c = getInternalType(contactToUpdate, theLead);
        if(theLead.PaymentDay__c != null){
        contactToUpdate.PaymentDay__c = theLead.PaymentDay__c;
        }
        if(contactToUpdate.RecordTypeId != Utility.getRecordTypeId('Contact', Utility.CONTACT_SUPPORTER_RECORD_TYPE)){
            contactToUpdate.RecordTypeId = Utility.getRecordTypeId('Contact', contRt);
        }
        if(theLead.Birthday__c != null){
            contactToUpdate.Birthdate  = theLead.Birthday__c;
        }
        return contactToUpdate;
}
    
    public static List<Contact> getContactsByEmails(List<String> emails){
        return [
            SELECT Email, Birthdate, Phone, FirstName, LastName, CustomerId__c, OrderNumber__c, PaymentDay__c, Address__c
            FROM Contact 
            WHERE Email IN: emails
            LIMIT 50000
        ];
    }
    
    public static Map<Id, Contact> getContactsBySiteOrderId(List<String> siteOrders){
        return new Map<ID, Contact>([
            SELECT
                OrderNumber__c, 
                PaymentDay__c, 
                Agent__c, 
                AccountId,
                Agent__r.AccountId,
                (
                    SELECT 
                        PaymentDay__c, 
                        LastPaymentDate__c, 
                        NextPaymentDate__c 
                    FROM RecurringDonations__r 
                    WHERE Status__c =: Utility.mainSettings.Recurring_Active_Donation_Status__c LIMIT 1
                )
            FROM Contact 
            WHERE OrderNumber__c IN: siteOrders
            LIMIT 50000
        ]);
}

    public static String getInternalType(Contact theContact, Lead theLead){
        String internalType;
        if(theContact.LeadSource == 'Donation.redcross.by'){
            internalType = theContact.PaymentDay__c == null ? INTERNALTYPES.get('DonationOneTime') : INTERNALTYPES.get('DonationRecure');
        } else{
            internalType = INTERNALTYPES.get(theContact.LeadSource);
        } 
        if(theContact.Internaltype__c != INTERNALTYPES.get('F2F')){
            if(theLead.PaymentDay__c != null){
                internalType = theLead.LeadSource == 'F2F' ? INTERNALTYPES.get('F2F') : INTERNALTYPES.get('DonationRecure');
            } else if(theContact.PaymentDay__c == null){
                internalType = theLead.LeadSource == 'ElkaCamp' ? INTERNALTYPES.get('ElkaCamp') : INTERNALTYPES.get('DonationOneTime');
            }
        }
        return internalType;
    }    
}