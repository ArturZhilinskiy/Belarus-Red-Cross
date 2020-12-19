@isTest
private class RestRecurringPaymentGeneratorTest {
    
    @testSetup
    private static void setup() {
        TestDataFactory.createTestData();
    }
    
    @isTest
    public static void doPostSucsessPaymentTest() {
        Contact bob = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Bob Furguston'];
        Id StagingRTId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/recurringpayment/';       
        String xml = getXMLRequest('4', bob.CustomerId__c, bob.OrderNumber__c);
        req.requestBody = Blob.valueof(xml);
        RestContext.request = req; 
        RestContext.response= res;
        Test.startTest();
        RestRecurringPaymentGenerator.doPost();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode, 'RestContext.response.statusCode should be 200');
        System.assertEquals(1, [SELECT COUNT() FROM DonationStaging__c WHERE RecordTypeId =: StagingRTId], 'Donation Staging should be created');
    }

    @isTest
    public static void doPostFailedPaymentTest() {
        Contact bob = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'Bob Furguston'];
        Id StagingRTId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/recurringpayment/';       
        String xml = getXMLRequest('8', bob.CustomerId__c, bob.OrderNumber__c);
        req.requestBody = Blob.valueof(xml);
        RestContext.request = req; 
        RestContext.response= res;
        Test.startTest();
        RestRecurringPaymentGenerator.doPost();
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM DonationStaging__c WHERE RecordTypeId =: StagingRTId], 'Donation Staging should be created');
        DonationStaging__c donationStaging = [SELECT Id ,PaymentMethod__c, PaymentType__c, Card__c, OperationType__c, RCText__c FROM DonationStaging__c WHERE RecordTypeId =: StagingRTId];
        System.debug('SELECTED RECORD: '+donationStaging);
    }
    
    @isTest
    public static void doPostExceptionTest() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/recurringpayment/';       
        RestContext.request = req; 
        RestContext.response= res;
        try {
            Test.startTest();
            RestRecurringPaymentGenerator.doPost();
            Test.stopTest();
        } catch (Exception e) {
            System.assertEquals(400, RestContext.response.statusCode);
        }
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