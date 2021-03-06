public with sharing class LeadHandler {

    private static final String ORG_WIDE_EMAIL_ADDRESS = 'f2f@redcross.by';

    private static List<Lead_Setting__mdt> leadSettings = [
        SELECT Lead_Source__c, Lead_Record_Type__c
        FROM Lead_Setting__mdt
    ];

    public static void onBeforeInsert(List<Lead> newLeads) {
        defineLeadRecordType(newLeads);
        processDuplicates(getVolunters(newLeads));
        List<Lead> uniqueLeads = getUniqueLeads(newLeads);
        
        defineCityWithDistrictAndRegion(uniqueLeads);
        
        defineOrganization(uniqueLeads);

        defineLeadAgent(uniqueLeads);
    }

    private static List<Lead> getUniqueLeads(List<Lead> leads) {
        List<Lead> uniqueLeads = new List<Lead>();
        for (Lead lead : leads) {
            if (lead.Duplicate__c == false) {
                uniqueLeads.add(lead);
            }
        }

        return uniqueLeads;
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

    private static List<Lead> defineCityWithDistrictAndRegion(List<Lead> leads) {
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

        return leads;
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

    private static void defineOrganization(List<Lead> leads) {

        List<Id> cityIds = new List<Id>();
        List<Id> districtIds = new List<Id>();

        for (Lead lead : leads) {
            if (lead.District__c != null) {
                districtIds.add(lead.District__c);
            }

            if (lead.City__c != null) {
                cityIds.add(lead.City__c);
            }
        }

        List<Organization__c> organizations = [
            SELECT Id, Name, Region__c, District__c, City__c, City_District__c
            FROM Organization__c
            WHERE District__c IN : districtIds 
                AND City__c IN : cityIds 
            LIMIT 10000
        ];

        for (Lead lead : leads) {
            lead.Organization__c = getOrgaizationId(lead, organizations);
        }
    }

    private static Id getOrgaizationId(Lead lead, List<Organization__c> organizations) {
        for (Organization__c organization : organizations) {
            Boolean isDistrictMatches = organization.District__c == lead.District__c;
            Boolean isCityMatches = organization.City__c == lead.City__c;
            if (isDistrictMatches && isCityMatches) {
                return organization.Id;
            }       
        }
        return null;
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
        updateContacts(contactsToUpdate, leadByEmail);

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
                AND IsConverted = false
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
            SELECT 
                Id, 
                RecordTypeId, 
                Email, 
                GW_Volunteers__Volunteer_Status__c, 
                City__c, 
                City_District__c, 
                Region__c, 
                District__c
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
            WHERE Profile.Name = : Utility.VOLUNTEER_PORTAL_USER_PROFILE_NAME
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

    private static void updateContacts(List<Contact> contacts, Map<String, Lead> leadByEmail) {

        List<Lead> leads = defineCityWithDistrictAndRegion(leadByEmail.values());
        Map<String, Lead> leadRecordByEmail = collectLeadByEmail(leads);

        for (Contact contact : contacts) {
            Lead lead = leadRecordByEmail.get(contact.Email);
            contact.GW_Volunteers__Volunteer_Status__c = Utility.CONTACT_VOLUNTEER_STATUS_NEW_SIGN_UP_NAME;
            contact.City__c = lead.City__c;
            contact.City_District__c = lead.City_District__c;
            contact.Region__c = lead.Region__c;
            contact.District__c = lead.District__c;
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
        List<Lead> duplicates = new List<Lead>();
        
        List<Lead> volunteers = new List<Lead>();
        List<Lead> newLeadRecords = new List<Lead>();


        for (Lead lead : newLeads) {
            if (lead.Duplicate__c == true) {
                duplicates.add(lead);
            } else {
                newLeadRecords.add(lead);
                
                if (isVolunteer(lead)) {
                    volunteers.add(lead);
                }
            }
        }
        
        duplicates = [SELECT Id FROM Lead WHERE Id IN :duplicates LIMIT 10000];
        System.debug(duplicates.size());
        delete duplicates;

        sendEmailMessage(volunteers, Utility.LEAD_NEW_VOLUNTEER_EMAIL_TEMPLATE_SETTING_NAME);
        defineCampaign(newLeadRecords);
    }

    private static void defineCampaign(List<Lead> leads) {
        List<Campaign> campaigns = getCampaignsForLeads(leads);

        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        for (Lead lead : leads) {
            Id campaignId = findCampaignForLead(lead, campaigns);
            if (campaignId != null) {
                campaignMembers.add(new CampaignMember(
                    CampaignId = campaignId,
                    LeadId = lead.Id
                ));
            }
        }
        insert campaignMembers;
    }

    private static List<Campaign> getCampaignsForLeads(List<Lead> leads) {
        List<String> leadSources = new List<String>();
        List<Id> regionIds = new List<Id>();
        List<Id> districtIds = new List<Id>();
        List<Id> cityIds = new List<Id>();
        List<Id> cityDistrictIds = new List<Id>();

        for (Lead lead : leads) {
            leadSources.add(lead.leadSource);
            if (lead.Region__c != null) {
                regionIds.add(lead.Region__c);
            }
            if (lead.District__c != null) {
                districtIds.add(lead.District__c);
            }
            if (lead.City__c != null) {
                districtIds.add(lead.City__c);
            }
            if (lead.City_District__c != null) {
                districtIds.add(lead.City_District__c);
            }
        }

        return [
            SELECT Id, Name, Region__c, District__c, City__c, City_District__c, Code__c
            FROM Campaign
            WHERE Code__c IN : leadSources 
                AND (
                    Region__c IN : regionIds 
                    OR District__c IN : districtIds 
                    OR City__c IN : cityIds 
                    OR City_District__c IN : cityDistrictIds
                )
            LIMIT 500000
        ];
    }

    private static Id findCampaignForLead(Lead lead, List<Campaign> campaigns) {
        for (Campaign campaign : campaigns) {
            Boolean laeadLocationMathesWithCampaignLocation =
                    lead.LeadSource == campaign.Code__c &&
                    lead.Region__c == campaign.Region__c &&
                    lead.District__c == campaign.District__c &&
                    lead.City__c == campaign.City__c &&
                    lead.City_District__c == campaign.City_District__c;
                
            if(laeadLocationMathesWithCampaignLocation) {
                return campaign.Id;
            }
        }

        return null;
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
                SELECT Id, Name, DeveloperName 
                FROM EmailTemplate 
                WHERE Id = : emailSetting.Email_Template_Id__c
            ];
            if (!emailTemplates.isEmpty()) {
                sendEmails(targetObjectIds, emailTemplates[0].Id);
            }
        } 
    }

    @future
    private static void sendEmails(List<Id> targetObjectIds, Id templateId) {
    
        OrgWideEmailAddress wideEmailAdress = [
            SELECT Id, Address 
            FROM OrgWideEmailAddress 
            WHERE Address = :ORG_WIDE_EMAIL_ADDRESS 
            LIMIT 1
        ];
        
        if (!targetObjectIds.isEmpty()) {
            Messaging.MassEmailMessage massEmailMessage = new Messaging.MassEmailMessage();
            massEmailMessage.setTargetObjectIds(targetObjectIds);
            massEmailMessage.setReplyTo(wideEmailAdress.Address);
            massEmailMessage.setTemplateId(templateId);
            massEmailMessage.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.MassEmailMessage[] { massEmailMessage });
        }
    }



}