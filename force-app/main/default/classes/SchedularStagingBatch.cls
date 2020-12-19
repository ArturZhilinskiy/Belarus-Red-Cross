public with sharing class SchedularStagingBatch implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch, 1);
        
    }
    
}