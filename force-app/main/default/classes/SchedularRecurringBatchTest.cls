@isTest
private class SchedularRecurringBatchTest {
    
    /*
	 * Cron Expression
	 * Seconds Minutes Hours Day_of_month Month Day_of_week Optional_year
	 */
    private static final String CRON_EXP_DAILY_8_AM = '0 0 8 * * ?';
    private static final String CRON_EXP_DAILY_9_AM = '0 0 9 * * ?';
    
    public void execute(SchedulableContext ctx) {
   
        RecurringBatch ach = new RecurringBatch();
        System.schedule('Reccuring Batch  Schedule job', CRON_EXP_DAILY_8_AM, new SchedularRecurringBatch());
        Database.executebatch(ach, 200);
    }
}