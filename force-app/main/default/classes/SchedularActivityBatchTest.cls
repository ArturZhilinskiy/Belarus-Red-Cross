@isTest
private class SchedularActivityBatchTest {
    
    /*
	 * Cron Expression
	 * Seconds Minutes Hours Day_of_month Month Day_of_week Optional_year
	 */
    private static final String CRON_EXP_DAILY_8_AM = '0 0 8 * * ?';
    
    public void execute(SchedulableContext ctx) {
   
        ActivityBatch ach = new ActivityBatch();
        System.schedule('Activity Batch  Schedule job', CRON_EXP_DAILY_8_AM, new SchedularActivityBatch());
        Database.executebatch(ach, 200);
    }
}