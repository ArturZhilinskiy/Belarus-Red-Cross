public with sharing class ReactivationPaymentBatchSchedular implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        Database.executebatch(new ReactivationPaymentBatch(), 200);
    }

}