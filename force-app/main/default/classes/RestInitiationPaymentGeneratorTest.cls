@isTest
private class RestInitiationPaymentGeneratorTest {
    
    @testSetup
    private static void setup() {
        TestDataFactory.createTestData();
    }
    
    @isTest
    public static void doPostSucsessPaymentTest() {
        Contact bob = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Bob Furguston'];
        Id StagingRTId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_INITIATION);

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/initiationpayment/';       
        String xml = getXMLRequest(Utility.transactionTypes().get('Authorized'), bob.CustomerId__c, bob.OrderNumber__c);
        req.requestBody = Blob.valueof(xml);
        RestContext.request = req; 
        RestContext.response= res;
        Test.startTest();
        RestInitiationPaymentGenerator.doPost();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, [SELECT COUNT() FROM DonationStaging__c WHERE RecordTypeId =: StagingRTId]);
    }
    
    @isTest 
    public static void doPostFailurePaymentWithoutPreviousPaymentsTest() {
        Contact bob = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Bob Furguston'];
        Id StagingRTId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_INITIATION);
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/initiationpayment/';       
        String xml = getXMLRequest(Utility.transactionTypes().get('Declined'), bob.CustomerId__c, bob.OrderNumber__c);
        req.requestBody = Blob.valueof(xml);
        RestContext.request = req; 
        RestContext.response= res;
        RestInitiationPaymentGenerator.doPost();
        Test.startTest();
        StagingBatch sch = new StagingBatch();
        Database.executebatch(sch);
        Test.stopTest();
        
        List<RecurringDonation__c> rds = [SELECT NextPaymentDate__c, LastPaymentDate__c FROM RecurringDonation__c];
        Date nextPaymentDate = Date.newInstance(Date.today().year(), Date.today().month(), Integer.valueOf(1));        
        
        System.debug(rds);
        System.assertEquals(200, RestContext.response.statusCode, 'RestContext.response.statusCode should be 200');
        System.assertEquals(1, rds.size(), 'Recurring Donation should be created'); 
        System.assertEquals(Date.today().addDays(+1), rds[0].NextPaymentDate__c, 'Recurring Donation NextPaymentDate should be tommorow');
        //System.assertEquals(nextPaymentDate.addMonths(1), rds[0].NextPaymentDate__c, 'Recurring Donation NextPaymentDate should be tommorow');
        System.assertEquals(null, rds[0].LastPaymentDate__c, 'Recurring Donation LastPaymentDate should be null');
        System.assertEquals(1, [SELECT COUNT() FROM DonationStaging__c WHERE RecordTypeId =: StagingRTId], 'Donation Staging should be created');
        System.assertEquals(1, [SELECT COUNT() FROM npe01__OppPayment__c], 'Payment should be created');


        
    }
    
    @isTest
    public static void doPostExceptionTest() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/initiationpayment/';       
        RestContext.request = req; 
        RestContext.response= res;
        try {
            Test.startTest();
            RestInitiationPaymentGenerator.doPost();
            Test.stopTest();
        } catch (Exception e) {
            System.assertEquals(400, RestContext.response.statusCode);
        }
    }    
    
    private static String getXMLRequest(String paymentType, String customerId, String siteOrderId){
        String xml = '';
        xml+='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">';
        xml+='<SOAP-ENV:Header />';
        xml+='<SOAP-ENV:Body>';
        xml+='<ns2:NotifierRequest xmlns:ns2="http://ws.webpay.by/notifier">';
        xml+='<ns2:BatchTimestamp>1564404446</ns2:BatchTimestamp>';
        xml+='<ns2:CurrencyId>BYN</ns2:CurrencyId>';
        xml+='<ns2:Amount>1</ns2:Amount>';
        xml+='<ns2:PaymentMethod>cc</ns2:PaymentMethod>';
        xml+='<ns2:OrderId>128946</ns2:OrderId>';
        xml +='<ns2:SiteOrderId>'; xml +=siteOrderId; xml+='</ns2:SiteOrderId>';
        xml+='<ns2:TransactionId>920762012</ns2:TransactionId>';
        xml +='<ns2:PaymentType>'; xml +=paymentType; xml+='</ns2:PaymentType>';
        xml+='<ns2:RRN>968036654803</ns2:RRN>';
        xml+='<ns2:WsbSignature>b669428e71ce05d60576490e708d5c58</ns2:WsbSignature>';
        xml+='<ns2:Action>0</ns2:Action>';
        xml+='<ns2:RC>W0001(00)</ns2:RC>';
        xml+='<ns2:Approval>968036</ns2:Approval>';
        xml +='<ns2:CustomerId>'; xml +=customerId; xml+='</ns2:CustomerId>';
        xml+='<ns2:Card>434179xxxxxx0051</ns2:Card>';
        xml+='<ns2:RecurringToken>920762012</ns2:RecurringToken>';
        xml+='<ns2:OfferExpDate>2020-11-30</ns2:OfferExpDate>';
        xml+='<ns2:RCText>Операция завершена успешно</ns2:RCText>';
        xml+='<ns2:OperationType>recurring_bind</ns2:OperationType>';
        xml+='</ns2:NotifierRequest>';
        xml+='</SOAP-ENV:Body>';
        xml+='</SOAP-ENV:Envelope>';
        return xml;
    }
    
}