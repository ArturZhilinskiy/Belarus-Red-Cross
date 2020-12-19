@RestResource(urlMapping='/initiationpayment/*')
global class RestInitiationPaymentGenerator {
    
    @HttpPOST
    global static void doPost() {
        try{
            List<Integration_Log__c> logs = new List<Integration_Log__c>();

            String xmlString = RestContext.request.requestBody.toString();

            logs.add(
                Utility.configureIntegrationLog(
                    'WebPay', 
                    Utility.LogLevels.DEBUG,
                    Utility.STAGING_RECORD_TYPE_INITIATION,
                    'RestInitiationPaymentGenerator: Request Body',
                    xmlString
                )
            );

            DonationStaging__c newStaging = ParseService.parseXML(xmlString);
            newStaging.RecordTypeId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_INITIATION);
            StagingService.proceedInsertings(new List<DonationStaging__c> {newStaging}); 

            logs.add(
                Utility.configureIntegrationLog(
                    'WebPay', 
                    Utility.LogLevels.DEBUG,
                    Utility.STAGING_RECORD_TYPE_INITIATION,
                    'RestInitiationPaymentGenerator: Created DonationStaging__c', 
                    JSON.serialize(newStaging)
                )
            );

            RestClient.response(200, RestClient.getXMLResponse());

            insert logs;

           // StagingBatch sb = new StagingBatch(); //added, on prod it is been called with Scheduled Jobs, need to remove before deployment
          //  Database.executeBatch(sb, 200); //added, on prod it is been called with Scheduled Jobs, need to remove before deployment

        }catch(Exception e){
            Integration_Log__c log = Utility.configureIntegrationLog(
                'WebPay', Utility.LogLevels.ERROR,
                Utility.STAGING_RECORD_TYPE_INITIATION,
                'RestInitiationPaymentGenerator: Exception: '+e.getTypeName(),
                e.getMessage()
            );
            insert log;

            System.debug(LoggingLevel.ERROR + e.getTypeName() + ' ' + e.getMessage());
            RestClient.response(400, e.getTypeName() + ' ' + e.getMessage());
        }
    }
    
}