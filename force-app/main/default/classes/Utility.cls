public with sharing class Utility {
    
    public static Account redCrossAccount;
    public static Main_Settings__mdt mainSettings;
    public static RC_Recurring_Donation_Settings__c RECURRING_SETTINGS = RC_Recurring_Donation_Settings__c.getValues('Payment attempt settings');
    
    static {
        mainSettings = getMainSettings();
        List<Account> accounts = [SELECT Id FROM Account WHERE Name =: mainSettings.Default_Account_Name__c];
        redCrossAccount = accounts.isEmpty() ? null : accounts[0];
    }
    
    public enum LogLevels {FATAL, ERROR, WARNING, INFO, DEBUG}
    
    public static final String STAGING_API_NAME = 'DonationStaging__c';  
    public static final String STAGING_RECORD_TYPE_INITIATION = 'Initiation';
    public static final String STAGING_RECORD_TYPE_RECURRING = 'Recurring';
    public static final String STAGING_RECORD_TYPE_ONE_TIME = 'One Time';
    
    public static final String OPP_DONATION_RECORD_TYPE = 'Donation'; 
    public static final String OPP_MEMBERSHIP_RECORD_TYPE = 'Membership';

    public static final String CONTACT_DONOR_RECORD_TYPE = 'Donor';
    public static final String CONTACT_AGENT_RECORD_TYPE = 'Agent';
    public static final String CONTACT_SUPPORTER_RECORD_TYPE = 'Supporter';
    
    public static final String LEAD_SOURCE_DONATION_REDCROSS_BY = 'Donation.redcross.by';
    
    public static final Set<String> SUCCESS_PAYMENT_TYPES = new Set<String> {'1','4','10'};

    public static final String LEAD_VOLUNTEER_RECORD_TYPE_NAME = 'Volunteer';
    public static final String LEAD_DONOR_RECORD_TYPE_NAME = 'Donor';
    public static final String LEAD_DISQUALIFIED_STATUS_NAME = 'Disqualified';
    public static final String LEAD_OPEN_NOT_CONTACTED_STATUS_NAME = 'Open - Not Contacted';

    public static final Id LEAD_VOLUNTEER_RECORT_TYPE_ID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(LEAD_VOLUNTEER_RECORD_TYPE_NAME).getRecordTypeId();
    public static final Id LEAD_DONOR_RECORT_TYPE_ID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(LEAD_DONOR_RECORD_TYPE_NAME).getRecordTypeId();

    public static final String LEAD_RE_APPEAL_EMAIL_TEMPLATE_SETTING_NAME = 'Lead re-appeal';
    public static final String LEAD_NEW_VOLUNTEER_EMAIL_TEMPLATE_SETTING_NAME = 'Lead new volunteer';

    public static final String CONTACT_VOLUNTEER_STATUS_ACTIVE_NAME = 'Active';
    public static final String CONTACT_VOLUNTEER_STATUS_NEW_SIGN_UP_NAME = 'New Sign Up';

    public static final String CONTACT_VOLUNTEER_NEW_SIGN_UP_EMAIL_TEMPLATE_SETTING_NAME = 'Contact volunteer new sign up';

    public static final String CONTACT_VOLUNTEER_WITH_PROTAL_USER_EMAIL_TEMPLATE_SETTING_NAME = 'Contact with portal user';
    public static final String CONTACT_VOLUNTEER_WITHOUT_PROTAL_USER_EMAIL_TEMPLATE_SETTING_NAME = 'Contact without portal user';


    public static final String CUSTOMER_PORTAL_USER_PROFILE_NAME = 'Customer Portal User';



    
    
    private static final String SEPARATOR = ' ';
    
    public static Schema.DisplayType getFieldType(String objectName, String fieldName){
        return Schema.getGlobalDescribe() 
            .get(objectName)
            .getDescribe()
            .fields
            .getMap()
            .get(fieldName)
            .getDescribe()
            .getType();
    }
    
    public static List<String> getObjectFields(String objectName){
        Set<String> fields = new Set<String>();
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values()){
            schema.describefieldresult dfield = sfield.getDescribe();
            fields.add(dfield.getName());
        }
        return new List<String>(fields);
    }
    
    public static Date convertUnixTimestamp(String unixTimestamp){
        Datetime newInstanceGmt = Datetime.newInstanceGmt(1970, 1, 1, 0, 0, 0);
        Datetime convertedDateTime = newInstanceGmt.addSeconds(Integer.valueOf(unixTimestamp));
        return convertedDateTime.date();
    }
    
    public static Id getRecordTypeId(String objectName, String recordTypeLabel){
        return  Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();
    }
    
    public static Map<String, String> transactionTypes() {
        return new Map<String, String> {
            '1' => 'Completed',
            '2' => 'Declined',
            '3' => 'Pending',
            '4' => 'Authorized',
            '5' => 'Refunded',
            '6' => 'System',
            '7' => 'Voided',
            '8' => 'Failed',
            '9' => 'Partial Voided',
            '10' => 'Recurrent'              
        };
    }  
    
    private static Main_Settings__mdt getMainSettings() {
        return [
            SELECT Days_before_card_expiration__c, Default_Account_Name__c, 
            Task_Subject_For_Reactivation_Card__c, Task_Subject_For_Recurring_Deactivation__c, Default_New_Staging_Status__c, 
            Default_Processed_Staging_Status__c, Recurring_Active_Donation_Status__c, Default_New_Card_Status__c,
            Default_Opportunity_Donation_Status__c, Default_Opportunity_Membership_Status__c
            FROM Main_Settings__mdt 
            LIMIT 1
        ];
    }

    public static Integer getRecurringDonationSecondAttemptDay() {
        return Integer.valueOf(RECURRING_SETTINGS.Second_Attempt__c);
    }
    public static Integer getRecurringDonationThirdAttemptDay() {
        return Integer.valueOf(RECURRING_SETTINGS.Third_Attempt__c);
    }
    public static Integer getRecurringDonationFourthAttemptDay() {
        return Integer.valueOf(RECURRING_SETTINGS.Fourth_Attempt__c);
    }

    public static Integration_Log__c configureIntegrationLog(String service, LogLevels level, String donationType, String message, String debugInfo) {
        DateTime now = DateTime.now();
        Integration_Log__c log = new Integration_Log__c(
            Service__c = service,
            Message__c = message,
            Log__c = debugInfo,
            Donation_Type__c = donationType,
            Time__c = Time.newInstance(now.hour(), now.minute(), now.second(), now.millisecond())
        );

        switch on level {
            when DEBUG {
                log.Level__c = 'DEBUG';
            }
            when ERROR {
                log.Level__c = 'ERROR';
            }
            when FATAL {
                log.Level__c = 'FATAL';
            }
            when INFO {
                log.Level__c = 'INFO';
            }
            when WARNING {
                log.Level__c = 'WARNING';
            }
        }

        return log;
    }

}