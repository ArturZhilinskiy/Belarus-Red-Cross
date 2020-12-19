public with sharing class SchedularActivityBatch implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        Database.executebatch(new ActivityBatch(), 200);
    }

}