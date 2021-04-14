public class VolunteerJobTriggerHelper {
    
    public static void scheduleFlowExecution(Map<Id, GW_Volunteers__Volunteer_Job__c> newRecordsById) {
        List<GW_Volunteers__Volunteer_Job__c> recordsToScheduleFlow = getRecordsToScheduleFlow(newRecordsById);
        scheduleFlow(recordsToScheduleFlow);
    }

    public static void rescheduleFlowExecution(Map<Id, GW_Volunteers__Volunteer_Job__c> oldRecordsById, Map<Id, GW_Volunteers__Volunteer_Job__c> newRecordsById) {
        abortScheduledJobs(newRecordsById.values());

        List<GW_Volunteers__Volunteer_Job__c> recordsToScheduleFlow = getRecordsToScheduleFlow(newRecordsById);
        scheduleFlow(recordsToScheduleFlow);
    }

    public static void abortScheduledJobs(List<GW_Volunteers__Volunteer_Job__c> newRecords) {
        List<String> filters = new List<String>();
        
        for (GW_Volunteers__Volunteer_Job__c job : newRecords) {
            filters.add('%' + String.valueOf(job.Id) + '%');
        }
        
        for (CronTrigger job : [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE :filters LIMIT 10000]) {
            System.abortJob(job.Id);
        }
    }

    private static List<GW_Volunteers__Volunteer_Job__c> getRecordsToScheduleFlow(Map<Id, GW_Volunteers__Volunteer_Job__c> newRecordsById) {
        List<GW_Volunteers__Volunteer_Job__c> recordsToScheduleFlow = new List<GW_Volunteers__Volunteer_Job__c> ();
       
        for (Id key : newRecordsById.keySet()) {
            GW_Volunteers__Volunteer_Job__c newRecord = newRecordsById.get(key);

            Boolean isReminderTimeSetAsFuture = newRecord.Reminder_Email_Time__c > System.now();
            Boolean isInactiveChecked = newRecord.GW_Volunteers__Inactive__c == true;
            Boolean isDisplayOnWebsiteChecked = newRecord.GW_Volunteers__Display_on_Website__c == true;

            if (isReminderTimeSetAsFuture && !isInactiveChecked) {
                recordsToScheduleFlow.add(newRecord);
            }
        }

        return recordsToScheduleFlow;
    }

    private static void scheduleFlow(List<GW_Volunteers__Volunteer_Job__c> recordsToScheduleFlow) {
        for (GW_Volunteers__Volunteer_Job__c record : recordsToScheduleFlow) {
            DateTime scheduleDateTime = record.Reminder_Email_Time__c;

            String cron = buildCronExpression(scheduleDateTime);
            String jobId = System.schedule('Scheduled emails for Volunteer job ' + record.Id, cron, new VolunteerJobFlowScheduler(record));
        }
    }

    private static String buildCronExpression(DateTime scheduleDateTime) {

        List<String> parameters = new List<String> {
            '0',
            String.valueOf(scheduleDateTime.minute()),
            String.valueOf(scheduleDateTime.hour()),
            String.valueOf(scheduleDateTime.day()),
            String.valueOf(scheduleDateTime.month()),
            '?',
            String.valueOf(scheduleDateTime.year())
        };

        return String.format('{0} {1} {2} {3} {4} {5} {6} {7}', parameters);
    }

}