public with sharing class UserTriggerHandler implements TriggerHandler {
    
    private static final Id volunteerPortalUserProfileId;

    static {
        volunteerPortalUserProfileId = [
            SELECT Id 
            FROM Profile 
            WHERE Name =: Utility.VOLUNTEER_PORTAL_USER_PROFILE_NAME LIMIT 1
        ]?.Id;
    }

    public static void beforeInsert(List<sObject> newRecords) {
        
    }
    
    public static void afterInsert(Map<Id, sObject> newRecordsById) {
        Map<Id, User> newUserById = (Map<Id, User>) newRecordsById;

        List<Id> volunteerContactIds = new List<Id>();
        
        for (User user : newUserById.values()) {
            Boolean isActiveVolunteerPortulUser = user.IsActive == true && user.ProfileId == volunteerPortalUserProfileId;
            
            if (isActiveVolunteerPortulUser) {
                volunteerContactIds.add(user.ContactId);
            }
        }

        List<Contact> contactsToUpdate = [SELECT GW_Volunteers__Volunteer_Status__c FROM Contact WHERE Id IN :volunteerContactIds LIMIT 10000];
        
        for (Contact contact : contactsToUpdate) {
            contact.GW_Volunteers__Volunteer_Status__c = Utility.CONTACT_VOLUNTEER_STATUS_ACTIVE_NAME;
        }

        update contactsToUpdate;
    }
    
    public static void beforeUpdate(Map<Id, sObject> oldRecordsById, Map<Id, sObject> newRecordsById) {
        Map<Id, User> oldUserById = (Map<Id, User>) oldRecordsById;
        Map<Id, User> newUserById = (Map<Id, User>) newRecordsById;
        

    }
    
    public static void afterUpdate(Map<Id, sObject> oldRecordsById, Map<Id, sObject> newRecordsById) {
        Map<Id, User> oldUserById = (Map<Id, User>) oldRecordsById;
        Map<Id, User> newUserById = (Map<Id, User>) newRecordsById;

        List<Id> volunteerContactIds = new List<Id>();
        
        for (User user : newUserById.values()) {
            Boolean isInactiveVolunteerPortulUser = user.IsActive == false && user.ProfileId == volunteerPortalUserProfileId;
            
            if (isInactiveVolunteerPortulUser) {
                volunteerContactIds.add(oldUserById.get(user.Id).ContactId);
            }
        }

        changeContactVolunteerStatusToInactive(volunteerContactIds);
    }
    
    public static void beforeDelete(Map<Id, sObject> oldRecordsById) {
        Map<Id, User> oldUserById = (Map<Id, User>) oldRecordsById;
    }
    
    public static void afterDelete(Map<Id, sObject> newRecordsById) {

    }
    
    public static void afterUndelete(Map<Id, sObject> newRecordsById) {

    }

    @future
    private static void changeContactVolunteerStatusToInactive(List<Id> contactIds) {
        List<Contact> contactsToUpdate = [SELECT GW_Volunteers__Volunteer_Status__c FROM Contact WHERE Id IN :contactIds LIMIT 10000];
        
        for (Contact contact : contactsToUpdate) {
            contact.GW_Volunteers__Volunteer_Status__c = Utility.CONTACT_VOLUNTEER_STATUS_INACTIVE_NAME;
        }

        update contactsToUpdate;
    }
}