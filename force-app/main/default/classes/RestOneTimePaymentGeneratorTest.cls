@isTest
private class RestOneTimePaymentGeneratorTest {
    
    @isTest
    public static void doPostTest() {
        Id StagingRTId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_ONE_TIME);
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/onetimepayment/';       
        String xml =getXMLRequest();
        req.requestBody = Blob.valueof(xml);
        RestContext.request = req; 
        RestContext.response= res;
        Test.startTest();
        RestOneTimePaymentGenerator.doPost();
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, [SELECT COUNT() FROM DonationStaging__c WHERE RecordTypeId =: StagingRTId]);
    }
    
    @isTest
    public static void doPostExceptionTest() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/onetimepayment/';       
        RestContext.request = req; 
        RestContext.response= res;
        try {
            Test.startTest();
            RestOneTimePaymentGenerator.doPost();
            Test.stopTest();
        } catch (Exception e) {
            System.assertEquals(400, RestContext.response.statusCode);
        }
    }    
    
    private static String getXMLRequest(){
        String xml = '';
        xml+='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">';
        xml+='<SOAP-ENV:Header/>';
        xml+='<SOAP-ENV:Body>';
        xml+='<ns2:NotifierRequest xmlns:ns2="http://ws.webpay.by/notifier">';
        xml+='<ns2:BatchTimestamp>1565865193</ns2:BatchTimestamp>';
        xml+='<ns2:CurrencyId>BYN</ns2:CurrencyId>';
        xml+='<ns2:Amount>1</ns2:Amount>';
        xml+='<ns2:PaymentMethod>cc</ns2:PaymentMethod>';
        xml+='<ns2:OrderId>130387</ns2:OrderId>';
        xml+='<ns2:SiteOrderId>ORDER-12345678</ns2:SiteOrderId>';
        xml+='<ns2:TransactionId>838002869</ns2:TransactionId>';
        xml+='<ns2:PaymentType>4</ns2:PaymentType>';
        xml+='<ns2:RRN>200230163486</ns2:RRN>';
        xml+='<ns2:WsbSignature>9d1211bf2f61f93e87cee793de290ae5</ns2:WsbSignature>';
        xml+='<ns2:Action>0</ns2:Action>';
        xml+='<ns2:RC>W0001(00)</ns2:RC>';
        xml+='<ns2:Approval>200230</ns2:Approval>';
        xml+='<ns2:Card>434179xxxxxx0051</ns2:Card>';
        xml+='<ns2:Cardholder>Kate Mihalenok</ns2:Cardholder>';
        xml+='</ns2:NotifierRequest>';
        xml+='</SOAP-ENV:Body>';
        xml+='</SOAP-ENV:Envelope>';
        return xml;
    }
    
}