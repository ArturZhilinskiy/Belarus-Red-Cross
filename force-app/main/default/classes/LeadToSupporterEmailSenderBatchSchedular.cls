public with sharing class LeadToSupporterEmailSenderBatchSchedular implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        Database.executebatch(new LeadToSupporterEmailSenderBatch(), 200);
    }

}