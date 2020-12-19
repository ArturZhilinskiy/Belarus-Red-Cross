@isTest
private class StagingBatchTest {
    static Date TODAYS_DATE = Date.today();
    static Integer SECOND_ATTEMPT_DAY;
    static Integer THIRD_ATTEMPT_DAY; 
    static Integer FOURTH_ATTEMPT_DAY;

    @testSetup
    private static void setup() {
        TestDataFactory.createTestData();
    }
    
    @isTest
    public static void processLeadOneTimePaymentTest() {
        System.assertEquals(1, [SELECT count() FROM Account WHERE Name =: 'Red Cross'], 'Red Cross Account has to be created');
        Lead jerry = [SELECT Name, CustomerId__c, OrderNumber__c FROM Lead WHERE Name = 'Jerry Myers'];
        insert TestDataFactory.generateOneTimeStaging(jerry.CustomerId__c, jerry.OrderNumber__c, '123456781');
        Test.startTest();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM npe01__OppPayment__c], 'Payment has to be created');
        System.assertEquals(1, [SELECT count() FROM Contact WHERE Name =: jerry.Name], 'Lead has to be converted');
        System.assertEquals(1, [SELECT count() FROM Opportunity WHERE RecordType.Name =: Utility.OPP_DONATION_RECORD_TYPE], 'Opp has to be created');
        List<DonationStaging__c> processed = [SELECT Status__c FROM DonationStaging__c];
        System.assertEquals(1, processed.size());
        System.assertEquals('Processed', processed[0].Status__c, 'Staging status has to be changed');
    }
    
    @isTest
    public static void processLeadInitiationPaymentTest() { 
        System.assertEquals(1, [SELECT count() FROM Account WHERE Name =: 'Red Cross'], 'Red Cross Account has to be created');
        Lead tabitha = [SELECT Name, CustomerId__c, OrderNumber__c FROM Lead WHERE Name = 'Tabitha Myers'];
        insert TestDataFactory.generateInitiationStaging(tabitha.CustomerId__c, tabitha.OrderNumber__c, '123456782', '434179xxxxxx0051', '920762012');        
        Test.startTest();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Card__c], 'Card has to be created');
        System.assertEquals(1, [SELECT count() FROM RecurringDonation__c], 'Recurring has to be created');
        System.assertEquals(1, [SELECT count() FROM npe01__OppPayment__c], 'Payment has to be created');
        System.assertEquals(1, [SELECT count() FROM Contact WHERE Name =: tabitha.Name], 'Lead has to be converted');
        System.assertEquals(1, [SELECT count() FROM Opportunity WHERE RecordType.Name =: Utility.OPP_MEMBERSHIP_RECORD_TYPE], 'Opp has to be created');
        List<DonationStaging__c> processed = [SELECT Status__c FROM DonationStaging__c];
        System.assertEquals(1, processed.size());
        System.assertEquals('Processed', processed[0].Status__c, 'Staging status has to be changed');
    }
    
    @isTest
    public static void processContactOneTimePaymentTest() {
        Contact barbara = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Barbara Furguston'];
        insert TestDataFactory.generateOneTimeStaging(barbara.CustomerId__c, barbara.OrderNumber__c, '123456783');
        Test.startTest();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM npe01__OppPayment__c], 'Payment has to be created');
        System.assertEquals(1, [SELECT count() FROM Opportunity WHERE RecordType.Name =: Utility.OPP_DONATION_RECORD_TYPE], 'Opp has to be created');
        List<DonationStaging__c> processed = [SELECT Status__c FROM DonationStaging__c];
        System.assertEquals(1, processed.size());
        System.assertEquals('Processed', processed[0].Status__c, 'Staging status has to be changed');
    }
    
    @isTest
    public static void processContactInitiationPaymentTest() { 
        Contact bob = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Bob Furguston'];
        insert TestDataFactory.generateInitiationStaging(bob.CustomerId__c, bob.OrderNumber__c, '123456784', '434179xxxxxx1111', '920762013');
        Test.startTest();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Card__c], 'Card has to be created');
        System.assertEquals(1, [SELECT count() FROM RecurringDonation__c], 'Recurring has to be created');
        System.assertEquals(1, [SELECT count() FROM npe01__OppPayment__c], 'Payment has to be created');
        System.assertEquals(1, [SELECT count() FROM Opportunity WHERE RecordType.Name =: Utility.OPP_MEMBERSHIP_RECORD_TYPE], 'Opp has to be created');
        List<DonationStaging__c> processed = [SELECT Status__c FROM DonationStaging__c];
        System.assertEquals(1, processed.size());
        System.assertEquals('Processed', processed[0].Status__c, 'Staging status has to be changed');
    }
    
    @isTest
    public static void processContactRecurringPaymentTest() {
        Contact john = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'John Smith'];
        DonationStaging__c donationStaging = TestDataFactory.generateRecurringStaging(john.CustomerId__c, john.OrderNumber__c, '123456781');
        insert donationStaging;
        RecurringDonation__c rd = TestDataFactory.generateRecurringDonation(10, john.Id, System.today(), System.today().addDays(1));
        insert rd;
        Test.startTest();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM npe01__OppPayment__c], 'Payment has to be created');
        System.assertEquals(1, [SELECT count() FROM Opportunity WHERE RecordType.Name =: Utility.OPP_MEMBERSHIP_RECORD_TYPE], 'Opp has to be created');
        List<DonationStaging__c> processed = [SELECT Status__c FROM DonationStaging__c];
        System.assertEquals(1, processed.size());
        System.assertEquals('Processed', processed[0].Status__c, 'Staging status has to be changed');
    } 

    @isTest
    public static void processContactRecurringFailedPaymentFirstAttemptTest() {
        Contact bob = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Bob Furguston'];
        Id StagingRTId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
        insert TestDataFactory.generateRecurringDonation(20, bob.Id, Date.today().addDays(-13), Date.today());
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/recurringpayment/';       
        String xml = getXMLRequest('8', bob.CustomerId__c, bob.OrderNumber__c);
        req.requestBody = Blob.valueof(xml);
        RestContext.request = req; 
        RestContext.response= res;

        SECOND_ATTEMPT_DAY = Utility.getRecurringDonationSecondAttemptDay();
        
        Test.startTest();
        RestRecurringPaymentGenerator.doPost();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();

        RecurringDonation__c recurring = [SELECT Id, NextPaymentDate__c, PaymentDay__c FROM RecurringDonation__c];
        List<npe01__OppPayment__c> payments = [SELECT Id FROM npe01__OppPayment__c];

        System.assertEquals(1, payments.size());

        Date expectedDate = TODAYS_DATE.month() == TODAYS_DATE.addDays(SECOND_ATTEMPT_DAY).month() ? 
            TODAYS_DATE.addDays(SECOND_ATTEMPT_DAY) 
            : Date.newInstance(TODAYS_DATE.year(), TODAYS_DATE.month(), Integer.valueOf(recurring.PaymentDay__c)).addMonths(1);
            
        System.debug('FIRST ATTEMPT: NextPaymentDate= ' + recurring.NextPaymentDate__c);
        System.assertEquals(expectedDate, recurring.NextPaymentDate__c);
    }

    @isTest
    public static void processContactRecurringFailedPaymentSecondAttemptTest() {
        Contact bob = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Bob Furguston'];
        Id StagingRTId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
        insert TestDataFactory.generateRecurringDonation(20, bob.Id, Date.today().addDays(-13), Date.today());

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/recurringpayment/';       
        String xml = getXMLRequest('8', bob.CustomerId__c, bob.OrderNumber__c);
        req.requestBody = Blob.valueof(xml);
        RestContext.request = req; 
        RestContext.response= res;

        THIRD_ATTEMPT_DAY = Utility.getRecurringDonationThirdAttemptDay();

        Test.startTest();
        RestRecurringPaymentGenerator.doPost();
        RestRecurringPaymentGenerator.doPost();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();

        List<DonationStaging__c> stagings = [SELECT Id FROM DonationStaging__c];
        System.assertEquals(2, stagings.size());

        RecurringDonation__c recurring = [SELECT Id, NextPaymentDate__c, PaymentDay__c FROM RecurringDonation__c];

        List<npe01__OppPayment__c> payments = [SELECT Id FROM npe01__OppPayment__c];

        System.assertEquals(2, payments.size());

        Date expectedDate = TODAYS_DATE.month() == TODAYS_DATE.addDays(THIRD_ATTEMPT_DAY).month() ?
            TODAYS_DATE.addDays(THIRD_ATTEMPT_DAY) 
            : Date.newInstance(TODAYS_DATE.year(), TODAYS_DATE.month(), Integer.valueOf(recurring.PaymentDay__c)).addMonths(1);
          
        System.debug('SECOND ATTEMPT: NextPaymentDate= ' + recurring.NextPaymentDate__c);
        System.assertEquals(expectedDate, recurring.NextPaymentDate__c);
    }

    @isTest
    public static void processContactRecurringFailedPaymentThirdAttemptTest() {
        Contact bob = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Bob Furguston'];
        Id StagingRTId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
        insert TestDataFactory.generateRecurringDonation(20, bob.Id, Date.today().addDays(-13), Date.today());
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/recurringpayment/';       
        String xml = getXMLRequest('8', bob.CustomerId__c, bob.OrderNumber__c);
        req.requestBody = Blob.valueof(xml);
        RestContext.request = req; 
        RestContext.response= res;
        
        FOURTH_ATTEMPT_DAY = Utility.getRecurringDonationFourthAttemptDay();

        Test.startTest(); 
        RestRecurringPaymentGenerator.doPost();
        RestRecurringPaymentGenerator.doPost();
        RestRecurringPaymentGenerator.doPost();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();

        RecurringDonation__c recurring = [SELECT Id, NextPaymentDate__c, PaymentDay__c FROM RecurringDonation__c];

        List<npe01__OppPayment__c> payments = [SELECT Id FROM npe01__OppPayment__c];

        System.assertEquals(3, payments.size());

        Date expectedDate = TODAYS_DATE.month() == TODAYS_DATE.addDays(FOURTH_ATTEMPT_DAY).month() ?
            TODAYS_DATE.addDays(FOURTH_ATTEMPT_DAY) 
            : Date.newInstance(TODAYS_DATE.year(), TODAYS_DATE.month(), Integer.valueOf(recurring.PaymentDay__c)).addMonths(1);
        
        System.debug('THIRD ATTEMPT: NextPaymentDate= ' + recurring.NextPaymentDate__c);
        System.assertEquals(expectedDate, recurring.NextPaymentDate__c);
    }

    @isTest
    public static void processContactRecurringFailedPaymentTest() {
        
    }

    private static String getXMLRequest(String paymentType, String customerId, String siteOrderId){
        String RCText = Utility.SUCCESS_PAYMENT_TYPES.contains(paymentType) 
            ? 'Операция завершена успешно'
            : 'Ошибка в проведении операции';
        
        String xml = '';
        xml +='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">';
        xml +='<SOAP-ENV:Header/>';
        xml +='<SOAP-ENV:Body>';
        xml +='<ns2:NotifierRequest xmlns:ns2="http://ws.webpay.by/notifier">';
        xml +='<ns2:BatchTimestamp>1565877873</ns2:BatchTimestamp>';
        xml +='<ns2:CurrencyId>BYN</ns2:CurrencyId>';
        xml +='<ns2:Amount>3</ns2:Amount>';
        xml +='<ns2:PaymentMethod>cc</ns2:PaymentMethod>';
        xml +='<ns2:OrderId>130463</ns2:OrderId>';
        xml +='<ns2:SiteOrderId>'; xml +=siteOrderId; xml+='</ns2:SiteOrderId>';
        xml +='<ns2:TransactionId>831878289</ns2:TransactionId>';
        xml +='<ns2:PaymentType>'; xml +=paymentType; xml+='</ns2:PaymentType>';
        xml +='<ns2:RRN>212912072317</ns2:RRN>';
        xml +='<ns2:WsbSignature>d1c0bbf1531e5912e1cb27826d054074</ns2:WsbSignature>';
        xml +='<ns2:Action>0</ns2:Action>';
        xml +='<ns2:RC>W0001(00)</ns2:RC>';
        xml +='<ns2:Approval>212912</ns2:Approval>';
        xml +='<ns2:CustomerId>'; xml +=customerId; xml+='</ns2:CustomerId>';
        xml +='<ns2:Card>434179xxxxxx0051</ns2:Card>';
        xml +='<ns2:RecurringToken>833390368</ns2:RecurringToken>';
        xml +='<ns2:RCText>'+RCText+'</ns2:RCText>';
        xml +='<ns2:OperationType>recurring_pay</ns2:OperationType></ns2:NotifierRequest>';
        xml +='</SOAP-ENV:Body>';
        xml +='</SOAP-ENV:Envelope>';
        return xml;
    } 
    
}