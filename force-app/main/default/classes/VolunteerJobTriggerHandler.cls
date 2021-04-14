public class VolunteerJobTriggerHandler implements TriggerHandler {
    
    public static void beforeInsert(List<sObject> newRecords) {
        
    }
    
    public static void afterInsert(Map<Id, sObject> newRecordsById) {
        VolunteerJobTriggerHelper.scheduleFlowExecution((Map<Id, GW_Volunteers__Volunteer_Job__c>) newRecordsById);
    }
    
    public static void beforeUpdate(Map<Id, sObject> oldRecordsById, Map<Id, sObject> newRecordsById) {
        Map<Id, GW_Volunteers__Volunteer_Job__c> oldVolunteerJobById = (Map<Id, GW_Volunteers__Volunteer_Job__c>) oldRecordsById;
        Map<Id, GW_Volunteers__Volunteer_Job__c> newVolunteerJobById = (Map<Id, GW_Volunteers__Volunteer_Job__c>) newRecordsById;
        
        for (Id key : newVolunteerJobById.keySet()) {
            GW_Volunteers__Volunteer_Job__c newRecord = newVolunteerJobById.get(key);
            GW_Volunteers__Volunteer_Job__c oldRecord = oldVolunteerJobById.get(key);

            Boolean isDisplayOnWebSiteChanged = newRecord.GW_Volunteers__Display_on_Website__c != oldRecord.GW_Volunteers__Display_on_Website__c;
            Boolean isDisplayOnWebSiteChecked = newRecord.GW_Volunteers__Display_on_Website__c == true;
            Boolean isInactiveChanged = newRecord.GW_Volunteers__Inactive__c != oldRecord.GW_Volunteers__Inactive__c;
            Boolean isInactiveChecked = newRecord.GW_Volunteers__Inactive__c == true;

            if (isDisplayOnWebSiteChanged && isDisplayOnWebSiteChecked) {
                newRecord.GW_Volunteers__Inactive__c = false;
            }

            if (isInactiveChanged && isInactiveChecked) {
                newRecord.GW_Volunteers__Display_on_Website__c = false;
            }
        }
    }
    
    public static void afterUpdate(Map<Id, sObject> oldRecordsById, Map<Id, sObject> newRecordsById) {
        Map<Id, GW_Volunteers__Volunteer_Job__c> oldVolunteerJobById = (Map<Id, GW_Volunteers__Volunteer_Job__c>) oldRecordsById;
        Map<Id, GW_Volunteers__Volunteer_Job__c> newVolunteerJobById = (Map<Id, GW_Volunteers__Volunteer_Job__c>) newRecordsById;

        VolunteerJobTriggerHelper.rescheduleFlowExecution(oldVolunteerJobById, newVolunteerJobById);
    }
    
    public static void beforeDelete(Map<Id, sObject> oldRecordsById) {
        Map<Id, GW_Volunteers__Volunteer_Job__c> oldVolunteerJobById = (Map<Id, GW_Volunteers__Volunteer_Job__c>) oldRecordsById;
        VolunteerJobTriggerHelper.abortScheduledJobs(oldVolunteerJobById.values());
    }
    
    public static void afterDelete(Map<Id, sObject> newRecordsById) {

    }
    
    public static void afterUndelete(Map<Id, sObject> newRecordsById) {

    }
}