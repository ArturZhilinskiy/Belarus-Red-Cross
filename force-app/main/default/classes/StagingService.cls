public with sharing class StagingService {
    
    private static final String ERROR_MESSAGE = 'Donation Staging must have a record type';
    
    public static Database.QueryLocator getNewStagings() {
        String stagingStatusNew = Utility.mainSettings.Default_New_Staging_Status__c;
        List<String> stagingFields = Utility.getObjectFields(Utility.STAGING_API_NAME);
        String query = 'SELECT RecordType.Name, ' + String.join((Iterable<String>)stagingFields, ',');
        query += ' FROM DonationStaging__c WHERE Status__c =: stagingStatusNew LIMIT 50000';
        return Database.getQueryLocator(query);
    }
    
    public static void proceedInsertings(List<DonationStaging__c> stagings) {
        System.debug('StagingService.proceedInsertings()');
        System.debug('List<DonationStaging__c> stagings = ' + stagings);
        Set<String> transactionIds = new Set<String>();
        for (DonationStaging__c staging: stagings){
            transactionIds.add(staging.TransactionId__c);
        }
        System.debug('Stagings to be inserted - ' + stagings);
        insert stagings;
    }
    
    public static void proceedStagingConversion(List<DonationStaging__c> stagings){
        Donation separated = separateStagings(stagings);
        if(!separated.oneTime.isEmpty()){
            OneTimeDonationService.processOneTimeDonation(separated.oneTime);
        }
        if(!separated.initiating.isEmpty()){
            InitiatingDonationService.processInitiatingDonation(separated.initiating);
        }
        if(!separated.recurring.isEmpty()){
            RecurringDonationService.processRecuringDonation(separated.recurring);
        }
    }
    
    private static Donation separateStagings(List<DonationStaging__c> stagings){
        Donation wrapper = new Donation();
        List<DonationStaging__c> oneTime = new List<DonationStaging__c>();
        List<DonationStaging__c> initiating  = new List<DonationStaging__c>();
        List<DonationStaging__c> recurring  = new List<DonationStaging__c>();
        for (DonationStaging__c st : stagings){
            if(st.RecordType.Name == Utility.STAGING_RECORD_TYPE_RECURRING){
                recurring.add(st);
            } else if(st.RecordType.Name == Utility.STAGING_RECORD_TYPE_INITIATION){
                initiating.add(st);
            }else if (st.RecordType.Name == Utility.STAGING_RECORD_TYPE_ONE_TIME){
                oneTime.add(st);
            }
        }
        wrapper.oneTime = oneTime;
        wrapper.initiating = initiating;
        wrapper.recurring = recurring;
        return wrapper;
    } 
    
}