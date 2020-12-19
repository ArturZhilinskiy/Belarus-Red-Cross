public with sharing class LeadService {

    public static List<Lead> convertLeads(List<Lead> leads, String contactRT, String oppRT, String oppName){
        System.debug('LEADS: '+leads);
        Database.DMLOptions dml = new Database.DMLOptions();
        Map <Id, Opportunity> leadToOpp = new Map<Id, Opportunity>();
        
        Map <String, Contact> contactMapToUpdate = mapContactByEmail(getContactsToUpdate(leads));
        Map <Id, Contact> leadToContact = mapContactByLeadId(leads, generateContactsFromLeads(leads, contactRT, contactMapToUpdate));
        
        for (Contact contact : contactMapToUpdate.values()) {
            System.debug('ContactMapToUpdate.Contact: '+ contact);
        }

        for (Lead lead : leads) {
            System.debug('LeadRecord: '+ lead);
        }

        for (Id leadId : leadToContact.keySet()) {
            System.debug('leadToContact.LeadId: '+ leadId);
            System.debug('leadToContact.Contact: '+ leadToContact.get(leadId));
        }

        System.debug('*! contactMapToUpdate = ' + contactMapToUpdate);        
        System.debug('*! leadToContact = ' + leadToContact);
    
        Set<Contact> setUpdatedContacts = new Set<Contact>();
        List<Contact> contactsToInsert = new List<Contact>(); 
        for (Contact contact : leadToContact.values()) {
            if (contact.Id != null) {
                setUpdatedContacts.add(contact);
            } else {
                contactsToInsert.add(contact);
            }
        }
        List<Contact> updatedContacts = new List<Contact>(setUpdatedContacts);
        for (Contact con : updatedContacts) {
            System.debug('updatedCon: '+ con);
        }
        Database.update(updatedContacts, dml);
        
        if (!contactsToInsert.isEmpty()) {
            dml.DuplicateRuleHeader.AllowSave = true;
            
            Database.SaveResult[] srList = Database.insert(contactsToInsert, dml);
            Id contId;
            for (Database.SaveResult sr : srList)
            {
                contId = sr.getId();
                System.debug('contId: -> '+contId);
            }

            
        }



        for (Contact con : contactsToInsert) {
            System.debug('conToIns: '+ con);
        }

        // if (ContactService.duplicate) {
        //     System.debug('*! leadToContact.values() = ' + leadToContact.values());
        //     Set<Contact> removeSimilarContacts = new Set<Contact>(leadToContact.values());
        //     List<Contact> uniqueContactList = new List<Contact>(removeSimilarContacts);
        //     System.debug('*! uniqueContactList = ' + uniqueContactList);
        //     Database.update(uniqueContactList, dml);
        //     ContactService.duplicate = false;
        // } else {
        //     System.debug('DatabaseInsert will be executed');
        //     dml.DuplicateRuleHeader.AllowSave = true;
        //     Database.insert(leadToContact.values(), dml);
        //     System.debug('DatabaseInsert after execution ' + leadToContact.values());
        // } 

        List<Contact> processedContacts = new List<Contact>();
        processedContacts.addAll(updatedContacts);
        processedContacts.addAll(contactsToInsert);

        for (Contact con : processedContacts) {
            System.debug('prCon: '+con);
        }

        leadToContact = mapContactByLeadId(leads, getContactsWithAccountId(processedContacts));

        for (Id leadId : leadToContact.keySet()) {
            System.debug('LeadId: '+ leadId);
            System.debug('Contact: '+leadToContact.get(leadId));
        }

        for(Lead theLead : leads) {
            System.debug('CUR LEAD: ' + theLead.Id);
            Opportunity newOpp = OpportunityService.generateOpportunity(
                oppName, 
                oppRT, 
                Date.today().addYears(1), 
                leadToContact.get(theLead.Id).AccountId, 
                leadToContact.get(theLead.Id).Id
            );
            leadToOpp.put(theLead.Id, newOpp);
        }
        
        insert leadToOpp.values();

        List<Database.LeadConvert> toConvert = generateLeadConvert(leads, leadToContact, leadToOpp);
        List<Database.LeadConvertResult> lcr = Database.convertLead(toConvert, dml);
        return verifyLeadConversion(lcr);
    }

    private static List<Contact> generateContactsFromLeads(List<Lead> leads, String contactRT, Map<String, Contact> contactMapToUpdate) {
        List<Contact> contactsFromLeads = new List<Contact>();
        for(Lead theLead : leads){
            contactsFromLeads.add(ContactService.generateContactFromLead(theLead, contactRT, contactMapToUpdate));
        }
        return contactsFromLeads;
    }

    private static Map<String, Contact> mapContactByEmail(List<Contact> contacts) {
        Map<String, Contact> contactByEmail = new Map<String, Contact>();
        
        for(Contact theContact : contacts){
            contactByEmail.put(theContact.Email, theContact);
        }

        return contactByEmail;
    }

    private static List<Contact> getContactsToUpdate(List<Lead> leads) {
        List<String> listEmails = new List<String>();
        for (Lead theLead : leads) {
            String leadEmail = (theLead.Email).deleteWhitespace();
            System.debug('leadEmail: '+ leadEmail);
            listEmails.add(leadEmail);
        }
        
        return [
            SELECT 
                Name, 
                Email, 
                LeadSource, 
                InternalType__c, 
                PaymentDay__c, 
                RecordTypeId,
                AccountId
            FROM Contact 
            WHERE Email =: listEmails
        ];
    }

    private static Map<Id, Contact> mapContactByLeadId(List<Lead> leads, List<Contact> contacts) {
        Map <Id, Contact> contactByLeadId = new Map<Id, Contact>();

        for (Contact contact : contacts) {
            for (Lead theLead : leads) {
                if (contact.Email == theLead.Email.deleteWhitespace()) {
                    contactByLeadId.put(theLead.Id, contact);
                }
            }
        }
        return contactByLeadId;
    }

    private static List<Contact> getContactsWithAccountId(List<Contact> contact) {
        return [
            SELECT
                CustomerId__c,
                OrderNumber__c,
                FirstName,
                LastName,
                Email,
                Phone,
                Birthdate,
                Address__c,
                PaymentDay__c,
                Agent__c,
                AgentId__c,
                RecordTypeId,
                AccountId,
                Account.Name,
                LeadSource,
                LeadCreationDate__c,
                InternalType__c
            FROM Contact
            WHERE Id IN :contact
        ];

    }

    public static List<Database.LeadConvert> generateLeadConvert(List<Lead> leads, Map <Id, Contact> leadToContact, Map <Id, Opportunity> leadToOpp){
        List<Database.LeadConvert> toConvert = new List<Database.LeadConvert>();
        LeadStatus status = getConvertedStatus();
        for(Lead myLead : leads){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setAccountId(leadToContact.get(myLead.Id).Account.Id);
            lc.setLeadId(myLead.Id);
            lc.setContactId(leadToContact.get(myLead.Id).Id);
            lc.setOpportunityId(leadToOpp.get(myLead.Id).Id);
            lc.setConvertedStatus(status.MasterLabel);
            toConvert.add(lc);
            System.debug('LEAD to convert: '+myLead);
        }
        System.debug('toConvert: '+ toConvert);
        return toConvert;
    }
    
    public static List<Lead> matchStagingWithLead(List<DonationStaging__c> stagings){
        List<String> siteOrderIds = new List<String>();
        for(DonationStaging__c staging : stagings){
            siteOrderIds.add(staging.SiteOrderId__c);
        } 
        return getLeadsBySiteOrderId(siteOrderIds);
    }

    public static LeadStatus getConvertedStatus(){
        return [
            SELECT MasterLabel 
            FROM LeadStatus  
            WHERE IsConverted = TRUE 
            LIMIT 1
        ];
    }
    
    public static List<Lead> getLeadsBySiteOrderId(List<String> siteOrderIds){
        return [
            SELECT OrderNumber__c, FirstName, LastName, Phone, Email, Birthday__c, 
            PaymentDay__c, Address__c, CustomerId__c, Agent__c, AgentId__c, Agent__r.AccountId, 
            LeadSource, CreatedDate, Representative_Id__c
            FROM Lead 
            WHERE IsConverted = FALSE AND OrderNumber__c IN : siteOrderIds 
            LIMIT 50000
        ];
    }
    
    public static List<Lead> getLeadsByIds(List<Id> ids){
        return [
            SELECT ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId, OrderNumber__c, PaymentDay__c
            FROM Lead 
            WHERE Id IN : ids 
            LIMIT 50000
        ];
    }
    
    public static List<Lead> getConvertedLeadsByContactIds(List<Id> contIds) {
        return [
            SELECT ConvertedContactId 
            FROM Lead 
            WHERE IsConverted = TRUE AND ConvertedContactId IN: contIds 
            LIMIT 50000
        ];
    }   
    
    private static Account getAccountByName(String name){
        return [
            SELECT Id 
            FROM Account 
            WHERE Name =: name
        ];
    }
    
    private static List<Lead> verifyLeadConversion(List<Database.LeadConvertResult> convertResult){
        List<Id> leadIds = new List<Id>();
        for (Database.LeadConvertResult convLead : convertResult) {
            System.debug('convLead: '+ convLead);
            if (convLead.isSuccess()){
                leadIds.add(convLead.getLeadId());
            }
        }
        System.debug('leadIds: '+leadIds);
        return getLeadsByIds(leadIds); 
    }
    
}