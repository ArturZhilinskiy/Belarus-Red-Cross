trigger VolunteerJobTrigger on GW_Volunteers__Volunteer_Job__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    TriggerDispatcher.run(new VolunteerJobTriggerHandler(), Trigger.operationType);

}