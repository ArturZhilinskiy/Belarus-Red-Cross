@isTest
public class LeadHandlerTest {
    @TestSetup
    static void makeData(){
        List<Lead> leads = new List<Lead>();
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'LeadVolunteer',
            Birthday__c = Date.valueOf('1998-12-22'),
            Email = 'testVolunteer1@gmail.com',
            Company = 'VRP',
            LeadSource = 'Volunteer - Web'
        );
        leads.add(lead);

        Lead leadDonor1 = new Lead(
            FirstName = 'Test',
            LastName = 'LeadDonor',
            Birthday__c = Date.valueOf('1998-12-22'),
            Email = 'testDonor1@gmail.com',
            Company = 'VRP',
            LeadSource = 'F2F'
        );
        leads.add(leadDonor1);

        Lead leadDonor2 = new Lead(
            FirstName = 'Test',
            LastName = 'LeadDonor',
            Birthday__c = Date.valueOf('1998-12-22'),
            Email = 'testDonor2@gmail.com',
            Company = 'VRP',
            LeadSource = 'ElkaCamp'
        );
        leads.add(leadDonor2);

        Lead leadDonor3 = new Lead(
            FirstName = 'Test',
            LastName = 'LeadDonor',
            Birthday__c = Date.valueOf('1998-12-22'),
            Email = 'testDonor3@gmail.com',
            Company = 'VRP',
            LeadSource = 'CovidVRP'
        );
        leads.add(leadDonor3);

        Lead leadDonor4 = new Lead(
            FirstName = 'Test',
            LastName = 'LeadDonor',
            Birthday__c = Date.valueOf('1998-12-22'),
            Email = 'testDonor4@gmail.com',
            Company = 'VRP',
            LeadSource = 'covid'
        );
        leads.add(leadDonor4);

        insert leads;
    }

    @isTest
    public static void onBeforeInsertTest() {

    }

    @isTest
    private static void mapFieldsTest() {
        
    }

    @isTest
    private static void defineLeadRecordTypeTest() {
        List<Lead_Setting__mdt> leadSettings = [
            SELECT Lead_Source__c, Lead_Record_Type__c
            FROM Lead_Setting__mdt
        ];

        System.assertEquals(false, leadSettings.isEmpty()); 

        Test.startTest();
        List<Lead> leads = new List<Lead> {
            new Lead(
                FirstName = 'Test',
                LastName = 'LeadVolunteer',
                Birthday__c = Date.valueOf('1998-12-22'),
                Email = 'testVolunteer2@gmail.com',
                Company = 'VRP',
                LeadSource = 'Volunteer - Web'
            ), 

            new Lead(
                FirstName = 'Test',
                LastName = 'LeadDonor',
                Birthday__c = Date.valueOf('1998-12-22'),
                Email = 'testVolunteer3@gmail.com',
                Company = 'VRP',
                LeadSource = 'covid'
            )
        };
        insert leads;
        Test.stopTest();

        List<Lead> records = [
            SELECT Id, RecordType.Name 
            FROM Lead 
            WHERE RecordType.Name =: Utility.LEAD_VOLUNTEER_RECORD_TYPE_NAME
                OR RecordType.Name =: Utility.LEAD_DONOR_RECORD_TYPE_NAME
            LIMIT 10000
        ];

        List<Lead> volunteers = new List<Lead>();
        List<Lead> donors = new List<Lead>();
        for (Lead record : records) {

        }

        System.assertEquals(7, records.size());

    }

    @isTest
    private static void isVolunteerTest() {
        
    }

    @isTest
    private static void defineCityWithDistrictAndRegionTest() {

    }

    @isTest
    private static void defineLeadLocationTest() {
        
    }

    @isTest
    private static void getVoluntersTest() {
        
    }
    
    @isTest
    private static void processDuplicatesTest() {
        
    }

    @isTest
    private static void collectLeadByEmailTest() {
        
    } 

    @isTest
    private static void findExistingLeadsTest() {
        
    }

    @isTest
    private static void getLeadsToUpdateTest() {
        
    }

    @isTest
    private static void markRecordsAsDuplicateTest() {
        
    }
    
    @isTest
    private static void findExisitingContactsTest() {
        
    }

    @isTest
    private static void getContactsToUpdateTest() {
        
    }

    @isTest
    private static void getContactsToPortalUserCheckTest() {
        
    }

    @isTest
    private static void getContactsWithPortalUserTest() {
        
    }

    @isTest
    private static void getPortalUsersTest() {
        
    }

    @isTest
    private static void updateLeadsTest() {
        
    }

    @isTest
    private static void updateContactsTest() {
        
    }

    @isTest
    private static void defineLeadAgentTest() {
        
    }

    @isTest
    private static void getAgentsTest() {
        
    }

    @isTest
    private static void defineAgentTest() {
        
    }

    @isTest
    private static void generateAgentTest() {
        
    }

    @isTest
    public static void onAfterInsertTest() {
        
    }

    @isTest
    private static void sendEmailMessageTest() {
        
    }

    @isTest
    private static void sendEmailsTest() {

    }
       
}
