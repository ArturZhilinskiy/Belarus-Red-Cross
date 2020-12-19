public with sharing class WebPayDonationRequest {
    
    private static final String PAYMENT_TYPE_FAILED = '8';

    private static Recurring_Settings__mdt mtd;
    
    static{
        mtd = getCustomMetadata();
    }
    
    public static void sendPaymentRequest(List<RecurringDonation__c> recurrings){

        System.debug('WebPayDonationRequest.sendPaymentRequest();');
        System.debug('Recurrings - ' + recurrings);
        
        try {
            if (recurrings.size() > Limits.getLimitCallouts()){
                throw new LimitException();
            }
            Map<String,String> headers = new Map<String, String>();
            headers.put('Content-Type', 'application/x-www-form-urlencoded');
            headers.put('Accept', 'application/json');
            
            List<Integration_Log__c> logs = new List<Integration_Log__c>();
            
            //List<WebPayDonationResponseWrapper> responses = new List<WebPayDonationResponseWrapper>();

            for (RecurringDonation__c recurring : recurrings){
                String payload = getPayload(recurring);
                System.debug('Payload = ' + payload);
                HttpResponse res = RestClient.makeRequest(headers, mtd.Endpoint__c, 'POST', payload);
            
                System.debug('RESPONSE BODY '+res.getBody());

                WebPayDonationRequest.WebPayDonationResponseWrapper wrappedResponse = 
                    (WebPayDonationRequest.WebPayDonationResponseWrapper) 
                    JSON.deserialize(res.getBody(), WebPayDonationRequest.WebPayDonationResponseWrapper.class);

                // responses.add(wrappedResponse);

                logs.add(
                    Utility.configureIntegrationLog(
                        'WebPay', 
                        Utility.LogLevels.DEBUG,
                        Utility.STAGING_RECORD_TYPE_RECURRING,
                        'WebPayDonationRequest: Processed RecurringDonation Record', 
                        JSON.serialize(recurring)
                    )
                );

                logs.add(
                    Utility.configureIntegrationLog(
                        'WebPay', 
                        Utility.LogLevels.DEBUG,
                        Utility.STAGING_RECORD_TYPE_RECURRING,
                        'WebPayDonationRequest response: '+ wrappedResponse.rc_text, 
                        JSON.serialize(wrappedResponse)
                    )
                );
                System.debug('HttpResponse res = ' + res);
            }
            insert logs;

            //createDonationStagingRecords(responses);
        } catch (LimitException ex) {
            insert Utility.configureIntegrationLog(
                'WebPay', Utility.LogLevels.FATAL,
                Utility.STAGING_RECORD_TYPE_RECURRING,
                'WebPayDonationRequest: LimitCallouts Exception, ' + ex.getMessage(),
                ex.getStackTraceString()
            );
        } catch (Exception ex) {
            insert Utility.configureIntegrationLog(
                'WebPay', Utility.LogLevels.FATAL,
                Utility.STAGING_RECORD_TYPE_RECURRING,
                'WebPayDonationRequest: Exception, ' + ex.getMessage(),
                ex.getStackTraceString()
            );
        }
        
    }

    // private static void createDonationStagingRecords(List<WebPayDonationResponseWrapper> responses) {
    //     List<Integration_Log__c> logs = new List<Integration_Log__c>();
    //     List<DonationStaging__c> newStagings = new List<DonationStaging__c>();
        
    //     for (WebPayDonationResponseWrapper response : responses) {
    //         if (response.payment_type == PAYMENT_TYPE_FAILED) {
    //             DonationStaging__c newStagingFailed = parseResponseIntoDonationStaging(response);
    //             newStagingFailed.RecordTypeId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
    //             newStagingFailed.Status__c = Utility.mainSettings.Default_New_Staging_Status__c;
    //             newStagings.add(newStagingFailed);

    //             logs.add(
    //                 Utility.configureIntegrationLog(
    //                     'WebPay', 
    //                     Utility.LogLevels.DEBUG,
    //                     Utility.STAGING_RECORD_TYPE_RECURRING, 
    //                     'WebPayDonationRequest: '+Datetime.now()+' Created Failed DonationStaging__c', 
    //                     JSON.serialize(newStagingFailed)
    //                 )
    //             );
    //         }
    //     }
        
    //     System.debug('DonationStaging__c newStagings = ' + newStagings);

    //     StagingService.proceedInsertings(newStagings);
        
    //     insert logs;
    // }

    private static DonationStaging__c parseResponseIntoDonationStaging(WebPayDonationResponseWrapper response) {
        return new DonationStaging__c(
            BatchTimestamp__c = response.batch_timestamp,
            CurrencyId__c     = response.currency_id,
            Amount__c         = response.amount,
            PaymentMethod__c  = response.payment_method,
            OrderId__c        = response.order_id,
            SiteOrderId__c    = response.site_order_id,
            TransactionId__c  = response.transaction_id,
            PaymentType__c    = response.payment_type,
            RRN__c            = response.rrn,
            Action__c         = response.action,
            RC__c             = response.rc,
            Approval__c       = response.approval,
            Card__c           = response.card,
            CustomerId__c     = response.customer_id,
            RecurringToken__c = response.recurring_token,
            RCText__c         = response.rc_text,
            OperationType__c  = response.operation_type       
        );
    }
    
    private static String getPayload(RecurringDonation__c recurring) {
        Map<String, String> vals = generatePayload(recurring);   
        String result = '';
        for(String thisKey : vals.keySet()) {
            result += thisKey + '=' + vals.get(thisKey) + '&';
        }
        return result.removeEnd('&');    
    }
    
    private static String sha1Generator(Map<String, String> req){
        String toConvert = req.get('wsb_seed');
        toConvert += req.get('wsb_storeid');
        toConvert += req.get('wsb_customer_id');
        toConvert += req.get('wsb_order_num');
        toConvert += req.get('wsb_test');
        toConvert += req.get('wsb_currency_id');
        toConvert += req.get('wsb_total');
        toConvert += req.get('wsb_operation_type');
        toConvert += req.get('wsb_recurring_token');
        toConvert += mtd.Secret_Key__c;
        String shasign = EncodingUtil.convertToHex(Crypto.generateDigest('SHA1',Blob.valueOf(toConvert)));
        return shasign;
    }
    
    private static Map<String, String> generatePayload(RecurringDonation__c recurring) {
        Map<String, String> req = new Map<String, String>();
        req.put('wsb_version', mtd.Wsb_Version__c);
        req.put('wsb_storeid', mtd.Store_Id__c);
        req.put('wsb_operation_type', mtd.Operation_Type__c);
        req.put('wsb_test', mtd.Test__c);
        req.put('wsb_currency_id', mtd.Currency_Id__c);
        req.put('wsb_seed', mtd.Seed__c);
        req.put('wsb_notify_url', mtd.Notify_Url__c);
        req.put('wsb_recurring_token', recurring.RecurringToken__c);
        req.put('wsb_invoice_item_name[0]', mtd.Invoice_Item_Name__c);
        req.put('wsb_invoice_item_quantity[0]', mtd.Invoice_Item_Quantity__c);
        req.put('wsb_invoice_item_price[0]', String.valueOf(recurring.Amount__c));
        Double total = Double.valueOf(mtd.Invoice_Item_Quantity__c) * Double.valueOf(recurring.Amount__c);
        req.put('wsb_total', String.valueOf(total));
        req.put('wsb_customer_id', recurring.CustomerId__c);
        req.put('wsb_order_num', recurring.OrderNumber__c);
        req.put('wsb_email', recurring.Email__c);
        req.put('wsb_signature', sha1Generator(req));
        return req;
    }
    
    private static Recurring_Settings__mdt getCustomMetadata() {
        return [
            SELECT Currency_Id__c, Endpoint__c, Invoice_Item_Name__c, Invoice_Item_Quantity__c, 
            Notify_Url__c, Operation_Type__c, Secret_Key__c, Seed__c, Store_Id__c, Test__c, Wsb_Version__c
            FROM Recurring_Settings__mdt LIMIT 1
        ];
    }
    
    public class LimitException extends Exception {
        public override String getMessage() {
            return 'Limit Exception. APEX Batch size should be < ' + Limits.getLimitCallouts();
        }
    }
    
    public with sharing class WebPayDonationResponseWrapper {
        public String batch_timestamp;
        public String currency_id;
        public Integer amount;
        public String customer_id;
        public String payment_method;
        public String site_order_id;
        public String operation_type;
        public String order_id;
        public String terminal;
        public String transaction_id;
        public String recurring_token;
        public String payment_type;
        public String rrn;
        public String rc;
        public String rc_text;
        public String action;
        public String approval;
        public String card;
    }
    

}