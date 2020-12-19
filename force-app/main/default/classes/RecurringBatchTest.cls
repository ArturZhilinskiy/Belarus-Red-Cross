@isTest
private class RecurringBatchTest {

    @testSetup
    private static void setup() {
        TestDataFactory.createTestData();
        Account acc = [SELECT Id FROM Account WHERE Name = 'Red Cross' LIMIT 1];
        Contact cont = [SELECT Id FROM Contact WHERE Name = 'John Smith'];
        Opportunity opp = TestDataFactory.generateOpportunity(acc.Id, cont.Id);
        insert opp;   
    }
    
    @isTest
    public static void successfulResponseTest() {
        Contact cont = [SELECT Id FROM Contact WHERE Name = 'John Smith'];
        RecurringDonation__c recurringDonation = TestDataFactory.generateRecurringDonation(10, cont.Id, Date.today().addDays(-1), Date.today());
        insert recurringDonation;
        System.debug('RECURRING DONATION RECORD: '+recurringDonation);
        HTTPMockFactory response = new HTTPMockFactory(200, responseBody('10'), null);

        Test.setMock(HttpCalloutMock.class, response);
        try {
            Test.startTest();
            Database.executeBatch(new RecurringBatch());
            Test.stopTest();
        }catch (Exception e){
            System.assertNotEquals('Limit Exception. APEX Batch size should be < ' + Limits.getLimitCallouts(), e.getMessage());
        }

        Integration_Log__c log = [
            SELECT
                Donation_Type__c, 
                Log__c 
            FROM Integration_Log__c
            WHERE Message__c LIKE 'WebPayDonationRequest response:%'
                AND Donation_Type__c = 'Recurring'
            LIMIT 1
        ];

        WebPayDonationRequest.WebPayDonationResponseWrapper wrappedResponse = 
            (WebPayDonationRequest.WebPayDonationResponseWrapper) 
            JSON.deserialize(log.Log__c, WebPayDonationRequest.WebPayDonationResponseWrapper.class);

        System.assertEquals('10', wrappedResponse.payment_type);
    }

    @isTest
    public static void failedResponseTest() {
        Contact cont = [SELECT Id FROM Contact WHERE Name = 'John Smith'];
        RecurringDonation__c rd = TestDataFactory.generateRecurringDonation(10, cont.Id, System.today(), System.today());
        insert rd;
        HTTPMockFactory response = new HTTPMockFactory(200, responseBody('8'), null);
        Test.setMock(HttpCalloutMock.class, response);
        
        try {
            Test.startTest();
            RecurringBatch rb = new RecurringBatch();
            Database.executeBatch(rb);
            Test.stopTest();
        }catch (Exception e){
            System.assertNotEquals('Limit Exception. APEX Batch size should be < ' + Limits.getLimitCallouts(), e.getMessage());
        }
        Integration_Log__c log = [
            SELECT
                Donation_Type__c, 
                Log__c 
            FROM Integration_Log__c
            WHERE Message__c LIKE 'WebPayDonationRequest response:%'
                AND Donation_Type__c = 'Recurring'
            LIMIT 1
        ];

        WebPayDonationRequest.WebPayDonationResponseWrapper wrappedResponse = 
            (WebPayDonationRequest.WebPayDonationResponseWrapper) 
            JSON.deserialize(log.Log__c, WebPayDonationRequest.WebPayDonationResponseWrapper.class);

        System.assertEquals('8', wrappedResponse.payment_type);
    }
    
    private static String responseBody(String paymentType){
        String json = '';
        json+='{"batch_timestamp": "1565918917",';
        json+='"currency_id": "BYN",';
        json+='"amount": "3",';
        json+='"customer_id": "8",';
        json+='"payment_method": "cc",';
        json+='"site_order_id": "8",';
        json+='"operation_type": "recurring_pay",';
        json+='"order_id": "641430545",';
        json+='"terminal": "99995551",';
        json+='"transaction_id": "246881069",';
        json+='"recurring_token": "246881069",';
        json+='"payment_type": "'+paymentType+'",';
        json+='"rrn": "253956131607",';
        json+='"rc": "W0001(00)",';
        json+='"rc_text": "Successfully completed",';
        json+='"action": "0",';
        json+='"approval": "253956",';
        json+='"card": "434179xxxxxx0051"}';
        return json;
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