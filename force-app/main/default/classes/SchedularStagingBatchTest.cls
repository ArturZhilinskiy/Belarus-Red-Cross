@isTest
private class SchedularStagingBatchTest {
    
    /*
	 * Cron Expression
	 * Seconds Minutes Hours Day_of_month Month Day_of_week Optional_year
	 */
    private static final String CRON_EXP_DAILY_8_AM = '0 0 8 * * ?';
    
    public void execute(SchedulableContext ctx) {
   
        StagingBatch ach = new StagingBatch();
        System.schedule('Staging Batch Schedule job', CRON_EXP_DAILY_8_AM, new SchedularStagingBatch());
        Database.executebatch(ach, 10);
    }
}