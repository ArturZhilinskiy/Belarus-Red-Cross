@isTest
private class PaymentTriggerTest {
    
    @testSetup
    private static void setup() {
        TestDataFactory.createTestData();
        Contact john = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'John Smith'];

        DonationStaging__c donationStaging = TestDataFactory.generateFailedRecurringStaging(john.CustomerId__c, john.OrderNumber__c, '123456781');
        insert donationStaging;

        RecurringDonation__c rd = TestDataFactory.generateRecurringDonation(10, john.Id, System.today(), System.today().addDays(1));
        insert rd;
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Red Cross' LIMIT 1];
        Opportunity opp = TestDataFactory.generateOpportunity(acc.Id, john.Id);
        insert opp;
    }
    
    @isTest
    private static void getDependentPicklistValuesTest() {
        Test.startTest();
        Boolean run = PaymentHandler.runOnce('onAfterInsert');
        Boolean run2 = PaymentHandler.runOnce('onAfterInsert');
        Boolean run3 = PaymentHandler.runOnce('onAfterInsert');
        Test.stopTest();
        System.assertEquals(run, TRUE, '');
        System.assertEquals(run2, FALSE, '');
        System.assertEquals(run3, FALSE, '');
    }
    
}