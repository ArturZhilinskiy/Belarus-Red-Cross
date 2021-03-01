public class VolunteerJobFlowScheduler implements Schedulable {

    private static final VolunteerJobSettings__c volunteerJobSettings = VolunteerJobSettings__c.getOrgDefaults();

    private GW_Volunteers__Volunteer_Job__c volunteerJob;

    public VolunteerJobFlowScheduler(GW_Volunteers__Volunteer_Job__c volunteerJob) {
        this.volunteerJob = volunteerJob;
    }

    public void execute(SchedulableContext context) {
        Map<String, GW_Volunteers__Volunteer_Job__c> paramByName = new Map<String, GW_Volunteers__Volunteer_Job__c>();
        paramByName.put('VolunteerJobRecord', volunteerJob);
        
        Flow.Interview flow1 = Flow.Interview.createInterview(volunteerJobSettings.Participants_Email_Flow__c, paramByName);     
        flow1.start();

        Flow.Interview flow2 = Flow.Interview.createInterview(volunteerJobSettings.Responsible_Person_Email_Flow__c, paramByName);     
        flow2.start();
    }

}
