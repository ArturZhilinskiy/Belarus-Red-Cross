@isTest
private class ActivityBatchTest {
    
    @testSetup
    private static void setup() {
        TestDataFactory.createTestData(); 
        Contact bob = [SELECT Id FROM Contact WHERE Name = 'Bob Furguston'];
        insert TestDataFactory.generateCard(bob.Id, Date.today());
        insert TestDataFactory.generateRecurringDonation(10, bob.Id, Date.today().addDays(-1), Date.today());
    }
    
    @isTest
    public static void activityBatchTest() { 
        Test.startTest();
        ActivityBatch ach = new ActivityBatch();
        Database.executebatch(ach);
        Test.stopTest();
    }
    
}