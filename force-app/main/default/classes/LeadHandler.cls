public with sharing class LeadHandler {

    private static List<Lead_Setting__mdt> leadSettings = [
        SELECT Lead_Source__c, Lead_Record_Type__c
        FROM Lead_Setting__mdt
    ];

    public static void onBeforeInsert(List<Lead> newLeads) {
        mapFields(newLeads);
        processDuplicates(getVolunters(newLeads));
        defineLeadAgent(newLeads);

    }

    private static void mapFields(List<Lead> leads) {
        defineLeadRecordType(leads);
        defineCityWithDistrictAndRegion(leads);
    }

    private static void defineLeadRecordType(List<Lead> leads) {
        for (Lead lead : leads) {
            if (isVolunteer(lead)) {
                lead.RecordTypeId = Utility.LEAD_VOLUNTEER_RECORT_TYPE_ID;
            } else {
                lead.RecordTypeId = Utility.LEAD_DONOR_RECORT_TYPE_ID;
            }
        }
    }

    private static Boolean isVolunteer(Lead lead) {
        for (Lead_Setting__mdt leadSetting : leadSettings) {
            Boolean isVolunteerRecordType = leadSetting.Lead_Record_Type__c == Utility.LEAD_VOLUNTEER_RECORD_TYPE_NAME;
            Boolean isLeadSourceMatches = leadSetting.Lead_Source__c == lead.LeadSource;
            
            if (isVolunteerRecordType && isLeadSourceMatches) {
                return true;
            }
        }
        return false;
    }

    private static void defineCityWithDistrictAndRegion(List<Lead> leads) {
        Set<String> regions = new Set<String>();
        Set<String> cities = new Set<String>();

        for (Lead lead : leads) {
            regions.add(lead.Web2Lead_Region__c);
            cities.add(lead.Web2Lead_City__c);
        }

        List<District__c> districts = [
            SELECT Id, Name, Region__r.Id, Region__r.Name, (
                    SELECT Id, Name
                    FROM Cities__r
                    WHERE Name IN : cities
                )
            FROM District__c
            WHERE Region__r.Name IN : regions
            LIMIT 50000
        ];

        Map<String, List<District__c>> districtsByRegionName = new Map<String, List<District__c>>();
        
        for (District__c district : districts) {
            if (districtsByRegionName.containsKey(district.Region__r.Name)) {
                districtsByRegionName.get(district.Region__r.Name).add(district);
            } else {
                districtsByRegionName.put(district.Region__r.Name, new List<District__c>{district});
            }
        }

        for (Lead lead : leads) {
            if (districtsByRegionName.containsKey(lead.Web2Lead_Region__c)) {
                defineLeadLocation(lead, districtsByRegionName.get(lead.Web2Lead_Region__c));
            }
        }

    }

    private static void defineLeadLocation(Lead lead, List<District__c> districts) {
        for (District__c district : districts) {
            if (lead.Web2Lead_Region__c == district.Region__r.Name) {
                for (City__c city : district.Cities__r) {
                    if (lead.Web2Lead_City__c == city.Name) {
                        lead.City__c = city.Id;
                        lead.Region__c = district.Region__r.Id;
                        lead.District__c = district.Id;
                        break;
                    }
                }
            }
        }
    }

    private static List<Lead> getVolunters(List<Lead> leads) {
        List<Lead> volunteers = new List<Lead>();
        
        for (Lead lead : leads) {
            if (lead.RecordTypeId == Utility.LEAD_VOLUNTEER_RECORT_TYPE_ID) {
                volunteers.add(lead);
            }
        }

        return volunteers;
    }

    

    private static void processDuplicates(List<Lead> newLeads) {
        List<Lead> leadsToUpdate =  new List<Lead>();
        
        List<Contact> contactsToUpdate = new List<Contact>();

        List<Contact> contactsToPortalUserCheck = new List<Contact>();

        List<Contact> contactsWithPortalUser= new List<Contact>();
        List<Contact> contactsWithoutPortalUser = new List<Contact>();

        Map<String, Lead> leadByEmail = collectLeadByEmail(newLeads);
        List<Lead> existingLeads = findExistingLeads(leadByEmail);
        
        if (!existingLeads.isEmpty()) {
            
            leadsToUpdate.addAll(getLeadsToUpdate(existingLeads));
            markRecordsAsDuplicate(leadByEmail, existingLeads);  

        }

        List<Contact> existingContacts = findExisitingContacts(leadByEmail);

        if (!existingContacts.isEmpty()) {
            
            markRecordsAsDuplicate(leadByEmail, existingContacts);
            contactsToUpdate.addAll(getContactsToUpdate(existingContacts));
            contactsToPortalUserCheck.addAll(getContactsToPortalUserCheck(existingContacts, contactsToUpdate));

        }

        if (!contactsToPortalUserCheck.isEmpty()) {            
            Map<Id, Contact> contactsWithPortalUserById = new Map<Id, Contact>(getContactsWithPortalUser(contactsToPortalUserCheck));
            
            for (Contact con : contactsToPortalUserCheck) {
                if (contactsWithPortalUserById.containsKey(con.Id)) {
                    contactsWithPortalUser.add(con);
                } else {
                    contactsWithoutPortalUser.add(con);
                }
            }

        }
        updateLeads(leadsToUpdate);
        updateContacts(contactsToUpdate);

        if (leadsToUpdate.isEmpty() == false) {
            sendEmailMessage(leadsToUpdate, Utility.LEAD_RE_APPEAL_EMAIL_TEMPLATE_SETTING_NAME);
        }

        if (contactsToUpdate.isEmpty() == false) {
            sendEmailMessage(contactsToUpdate, Utility.CONTACT_VOLUNTEER_NEW_SIGN_UP_EMAIL_TEMPLATE_SETTING_NAME);
        }

        if (contactsWithPortalUser.isEmpty() == false) {
            sendEmailMessage(contactsWithPortalUser,  Utility.CONTACT_VOLUNTEER_WITH_PROTAL_USER_EMAIL_TEMPLATE_SETTING_NAME);
        }

        if (contactsWithoutPortalUser.isEmpty() == false) {
            sendEmailMessage(contactsWithoutPortalUser,  Utility.CONTACT_VOLUNTEER_WITHOUT_PROTAL_USER_EMAIL_TEMPLATE_SETTING_NAME);
        }
    }

    private static Map<String, Lead> collectLeadByEmail(List<Lead> newLeads) {
        Map<String, Lead> leadByEmail = new Map<String, Lead>();
        for (Lead lead : newLeads) {
            leadByEmail.put(lead.Email, lead);
        }
        
        return leadByEmail;
    } 

    private static List<Lead> findExistingLeads(Map<String, Lead> leadByEmail) {
        return [
            SELECT Id, Status, Email, Re_appeal__c
            FROM Lead
            WHERE Email IN : leadByEmail.keySet()
            LIMIT 10000
        ];
    }

    private static List<Lead> getLeadsToUpdate(List<Lead> existingLeads) {
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead lead : existingLeads) {
            if (lead.Status == Utility.LEAD_DISQUALIFIED_STATUS_NAME) {
                leadsToUpdate.add(lead);
            }
        }

        return leadsToUpdate;
    }

    private static void markRecordsAsDuplicate(Map<String, Lead> leadByEmail, List<sObject> existingRecords) {
        for (sObject record : existingRecords) {
            if (leadByEmail.containsKey((String) record.get('Email'))) {
                leadByEmail.get((String) record.get('Email')).Duplicate__c = true;
            }
        }
    }

    private static List<Contact> findExisitingContacts(Map<String, Lead> leadByEmail) {
        return [
            SELECT Id, RecordTypeId, Email, GW_Volunteers__Volunteer_Status__c
            FROM Contact
            WHERE Email IN : leadByEmail.keySet()
            LIMIT 10000
        ];
    }

    private static List<Contact> getContactsToUpdate(List<Contact> existingContacts) {
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact contact : existingContacts) {
            if (contact.GW_Volunteers__Volunteer_Status__c != Utility.CONTACT_VOLUNTEER_STATUS_ACTIVE_NAME) {
                contactsToUpdate.add(contact);
            }
        }

        return contactsToUpdate;
    }

    private static List<Contact> getContactsToPortalUserCheck(List<Contact> existingContacts, List<Contact> contactsToUpdate) {
        List<Contact> contactsToPortalUserCheck = new List<Contact>();
        
        Map<Id, Contact> contactById = new Map<Id, Contact>(contactsToUpdate);
        for (Contact con : existingContacts) {
            if (!contactById.containsKey(con.Id)) {
                contactsToPortalUserCheck.add(con);
            }
        }

        return contactsToPortalUserCheck;
    }

    private static List<Contact> getContactsWithPortalUser(List<Contact> contacts) {
        List<User> portalUsers = getPortalUsers(contacts);
        List<Contact> contactsWithPortalUser = new List<Contact>();

        Map<Id, Contact> contactsById = new Map<Id, Contact>(contacts);
       
        for (User user : portalUsers) {
            if (contactsById.containsKey(user.Contact.Id)) {
                contactsWithPortalUser.add(contactsById.get(user.Contact.Id));
            }
        }

        return contactsWithPortalUser;
    }

    private static List<User> getPortalUsers(List<Contact> contacts) {
        return [
            SELECT Id, Contact.Id, Email
            FROM User
            WHERE Profile.Name = : Utility.CUSTOMER_PORTAL_USER_PROFILE_NAME
                AND ContactId IN : contacts
            LIMIT 10000
        ];
    }

    private static void updateLeads(List<Lead> leads) {
        for (Lead lead : leads) {
            lead.Re_appeal__c = true;
            lead.Status = Utility.LEAD_OPEN_NOT_CONTACTED_STATUS_NAME;
        }

        update leads;
    }

    private static void updateContacts(List<Contact> contacts) {
        for (Contact contact : contacts) {
            contact.GW_Volunteers__Volunteer_Status__c = Utility.CONTACT_VOLUNTEER_STATUS_NEW_SIGN_UP_NAME;
        }

        update contacts;
    }

    

    private static void defineLeadAgent(List<Lead> newLeads) {
        List<Lead> leadsWithRepresentativeId = new List<Lead>();
        Set<String> representativeIds = new Set<String>();
        
        Set<String> newRepresentativeIds = new Set<String>();

        List<Lead> leadsWithotFoundedAgent = new List<Lead>();
        List<Contact> newAgents = new List<Contact>();
        
        for(Lead lead : newLeads) {
            if(lead.Representative_Id__c != null) {
                leadsWithRepresentativeId.add(lead);
                representativeIds.add(lead.Representative_Id__c);
            }
        }

        List<Contact> agents = getAgents(representativeIds);

        for(Lead lead : leadsWithRepresentativeId){
            defineAgent(lead, agents);
            if(lead.Agent__c == null) {
                leadsWithotFoundedAgent.add(lead);
                newRepresentativeIds.add(lead.Representative_Id__c);
            }
        }

        for(String representativeId : newRepresentativeIds) {
            Contact newAgent = generateAgent(representativeId);
            newAgents.add(newAgent);
        }

        insert newAgents;
        
        for(Lead lead : leadsWithotFoundedAgent) {
            defineAgent(lead, newAgents);
        }
    }

    private static List<Contact> getAgents(Set<String> representativeIds) {
        List<Contact> agetns = new List<Contact>();
        if (!representativeIds.isEmpty()) {
            agetns = [
                SELECT Representative_Id__c 
                FROM Contact 
                WHERE RecordType.Name =: Utility.CONTACT_AGENT_RECORD_TYPE
                    AND Representative_Id__c =: representativeIds
            ];
        }
        return agetns;
    }

    private static void defineAgent(Lead lead, List<Contact> agents) {
        for(Contact agent : agents) {
            if(lead.Representative_Id__c == agent.Representative_Id__c){
                lead.AgentId__c = agent.Id;
                lead.Agent__c = agent.Id;
                break;
            }
        }
    }

    private static Contact generateAgent(String representativeId) {
        Contact agent = new Contact(
            FirstName = 'Agent',
            LastName = representativeId,
            RecordTypeId = Utility.getRecordTypeId('Contact', Utility.CONTACT_AGENT_RECORD_TYPE),
            AccountId = Utility.redCrossAccount.Id,
            Representative_Id__c = representativeId
        );
        return agent;
    }

    public static void onAfterInsert(List<Lead> newLeads) {
        Map<Id, Lead> leadToDeleteById = new Map<Id, Lead>();
        Map<Id, Lead> leadToSendEmailById = new Map<Id, Lead>();

        for (Lead lead : newLeads) {
            if (lead.Duplicate__c == true) {
                Lead leadCopy = lead.clone(true, false, false, false);
                leadToDeleteById.put(leadCopy.Id, leadCopy);
            } else {
                leadToSendEmailById.put(lead.Id, lead);
            }
        }
        
        delete leadToDeleteById.values();

        sendEmailMessage(leadToSendEmailById.values(), Utility.LEAD_NEW_VOLUNTEER_EMAIL_TEMPLATE_SETTING_NAME);
    }

    private static void sendEmailMessage(List<sObject> targetObjects, String emailTemplateName) {
        
        List<Id> targetObjectIds = new List<Id>();
        for (sObject record : targetObjects) {
            if (record.get('Email') != null) {
                targetObjectIds.add(record.Id);
            }
        }

        Email_Template_Settings__c emailSetting = Email_Template_Settings__c.getValues(emailTemplateName);
        if (emailSetting != null) {
            List<EmailTemplate> emailTemplates = [
                SELECT Id, DeveloperName 
                FROM EmailTemplate 
                WHERE DeveloperName = : emailSetting.Email_Template_Name__c
            ];
            if (!emailTemplates.isEmpty()) {
                sendEmails(targetObjectIds, emailTemplates[0].Id);
            }
        } 
    }

    @future
    private static void sendEmails(List<Id> targetObjectIds, Id templateId) {
        if (!targetObjectIds.isEmpty()) {
            Messaging.MassEmailMessage mail = new Messaging.MassEmailMessage();
            mail.setTargetObjectIds(targetObjectIds);
            mail.setSenderDisplayName('Belarus Red Cross');
            mail.setTemplateId(templateId);
            Messaging.sendEmail(new Messaging.MassEmailMessage[] { mail });
        }
    }

}