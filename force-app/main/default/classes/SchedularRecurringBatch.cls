public with sharing class SchedularRecurringBatch implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        RecurringBatch rch = new RecurringBatch();
        // Database.executebatch(rch, Limits.getLimitCallouts());// Limit Callouts: 100
        Database.executebatch(rch, 3);
    }
}