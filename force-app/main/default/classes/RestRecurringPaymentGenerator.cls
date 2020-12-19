@RestResource(urlMapping='/recurringpayment/*')
global class RestRecurringPaymentGenerator {

    @HttpPOST
    global static void doPost() {
        
        System.debug('RestRecurringPaymentGenerator.doPost()');
        try{
            List<Integration_Log__c> logs = new List<Integration_Log__c>();

            String xmlString = RestContext.request.requestBody.toString();
            
            logs.add(
                Utility.configureIntegrationLog(
                    'WebPay', 
                    Utility.LogLevels.DEBUG,
                    Utility.STAGING_RECORD_TYPE_RECURRING,
                    'RestRecurringPaymentGenerator: Request Body',
                    xmlString
                )
            );

            DonationStaging__c newStaging = ParseService.parseXML(xmlString);
            System.debug('DonationStaging__c newStaging = ' + newStaging);
            newStaging.RecordTypeId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
            
            
            //newStaging.PaymentType__c = '8';//FOR TESTING! REMOVE BEFORE DEPLOYING!
            
            
            StagingService.proceedInsertings(new List<DonationStaging__c> {newStaging});

            logs.add(
                Utility.configureIntegrationLog(
                    'WebPay', 
                    Utility.LogLevels.DEBUG,
                    Utility.STAGING_RECORD_TYPE_RECURRING,
                    'RestRecurringPaymentGenerator: Created DonationStaging__c', 
                    JSON.serialize(newStaging)
                )
            );
            
            insert logs;

            System.debug('RestClient.getXMLResponse() = ' + RestClient.getXMLResponse());

            RestClient.response(200, RestClient.getXMLResponse());
            
        }catch(Exception e){
            Integration_Log__c log = Utility.configureIntegrationLog(
                'WebPay', Utility.LogLevels.ERROR,
                Utility.STAGING_RECORD_TYPE_RECURRING,
                'RestRecurringPaymentGenerator: Exception ' + e.getTypeName(),
                e.getMessage()
            );
            insert log;

            System.debug('RestRecurringPaymentGenerator Exception: '+ LoggingLevel.ERROR + e.getTypeName() + ' ' + e.getMessage());
            RestClient.response(400, e.getTypeName() + ' ' + e.getMessage());
        }
    }
    
}