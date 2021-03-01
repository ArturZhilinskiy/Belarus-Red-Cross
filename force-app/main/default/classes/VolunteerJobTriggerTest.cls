@isTest
public class VolunteerJobTriggerTest {
    
    @TestSetup
    private static void makeData() {

        List<SObject> records = new List<SObject>();

        Contact responsiblePerson = new Contact();
        responsiblePerson.FirstName = 'ResponsiblePerson';
        responsiblePerson.LastName = 'Test';
        responsiblePerson.Email = 'test1@gmail.com';
        responsiblePerson.Phone = '+375291234567';
        
        Contact volunteer = new Contact();
        volunteer.FirstName = 'Volunteer';
        volunteer.LastName = 'Test';
        volunteer.Email = 'test2@gmail.com';
        volunteer.Phone = '+375297654321';

        Campaign campaign = new Campaign();
        campaign.Name = 'Test Campaign';
        campaign.IsActive = true;

        Region__c region = new Region__c();
        region.Name = 'Test Region';

        insert region;

        District__c district = new District__c();
        district.Name = 'Test District';
        district.Region__c = region.Id;

        insert district;

        City__c city = new City__c();
        city.Name = 'Test City';
        city.District__c = district.Id;
        
        insert city;

        City_District__c cityDistrict = new City_District__c();
        cityDistrict.Name = 'Test City District';
        cityDistrict.City__c = city.Id;
        
        insert cityDistrict;

        Organization__c organization = new Organization__c();
        organization.Name = 'Test Organization';
        organization.Region__c = region.Id;
        organization.District__c = district.Id;
        organization.City__c = city.Id;
        organization.City_District__c = cityDistrict.Id;
        
        records.add(responsiblePerson);
        records.add(volunteer);
        records.add(campaign);
        records.add(organization);

        insert records;

        VolunteerJobSettings__c volunteerJobSettings = new VolunteerJobSettings__c();
        volunteerJobSettings.SetupOwnerId = UserInfo.getOrganizationId();
        volunteerJobSettings.Participants_Email_Flow__c = 'Volunteer_Job_Send_Email_To_Participants';
        volunteerJobSettings.Responsible_Person_Email_Flow__c = 'Volunteer_Job_Send_Email_With_List_Of_Participants_To_Responsible_Person';
        volunteerJobSettings.Email_Template_With_List_Of_Participants__c = 'Volunteer Job List Of Participants For Responsible Person Email Template';
        volunteerJobSettings.Reminder_Email_Template_For_Volunteer__c = 'Remind Volunteer About The Volunteer Job Template';
        volunteerJobSettings.Unsubscribe_Email_Template_For_RP__c = 'Volunteer Job Unsubscribe Responsible Person Notification Email Template';
        insert volunteerJobSettings;
    }

    @isTest
    private static void beforeInsertTest() {

    }
    
    @isTest
    private static void afterInsertTest() {
        List<GW_Volunteers__Volunteer_Job__c> volunteerJobs = generateVolunteerJobs(3);

        Integer numberOfScheduledJobs = 0;

        Test.startTest();
        insert volunteerJobs;

        List<String> filters = new List<String>();
        
        for (GW_Volunteers__Volunteer_Job__c job : volunteerJobs) {
            filters.add('%' + String.valueOf(job.Id) + '%');
        }
        

        numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :filters];
        Test.stopTest();

        System.assertEquals(2, numberOfScheduledJobs, 'Trigger should schedule 2 Scheduled Apex Jobs');
    }
    
    @isTest
    private static void beforeUpdateTest() {
        List<GW_Volunteers__Volunteer_Job__c> volunteerJobs = generateVolunteerJobs(3);

        insert volunteerJobs;
        
        volunteerJobs[0].GW_Volunteers__Display_on_Website__c = true;
        volunteerJobs[1].GW_Volunteers__Inactive__c = true;

        Test.startTest();

        update volunteerJobs;
    
        Test.stopTest();
        
        List<GW_Volunteers__Volunteer_Job__c> processedRecords = [
            SELECT Id, GW_Volunteers__Inactive__c, GW_Volunteers__Display_on_Website__c 
            FROM GW_Volunteers__Volunteer_Job__c
            WHERE Id IN : volunteerJobs
        ];

        GW_Volunteers__Volunteer_Job__c job1 = new GW_Volunteers__Volunteer_Job__c();
        GW_Volunteers__Volunteer_Job__c job2 = new GW_Volunteers__Volunteer_Job__c();
        GW_Volunteers__Volunteer_Job__c job3 = new GW_Volunteers__Volunteer_Job__c();

        for (GW_Volunteers__Volunteer_Job__c job : processedRecords) {
            if (job.Id == volunteerJobs[0].Id) {
                job1 = job;
            }

            if (job.Id == volunteerJobs[1].Id) {
                job2 = job;
            }

            if (job.Id == volunteerJobs[2].Id) {
                job3 = job;
            }
        }

        System.assertEquals(false, job1.GW_Volunteers__Inactive__c, 'Job1 should be inactive');
        System.assertEquals(false, job2.GW_Volunteers__Display_on_Website__c, 'Job2 should not be displayed on website');
        System.assertEquals(true, job3.GW_Volunteers__Inactive__c, 'Job3 should be inactive');
    }
    
    @isTest
    private static void afterUpdateTest() {

        List<GW_Volunteers__Volunteer_Job__c> volunteerJobs = generateVolunteerJobs(3);
 
        Integer numberOfScheduledJobs = 0;

        Test.startTest();

        insert volunteerJobs;
        volunteerJobs[0].GW_Volunteers__Inactive__c = true;
        update volunteerJobs;

        List<String> filters = new List<String>();
        
        for (GW_Volunteers__Volunteer_Job__c job : volunteerJobs) {
            filters.add('%' + String.valueOf(job.Id) + '%');
        }
        

        numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :filters];
        Test.stopTest();

        System.assertEquals(1, numberOfScheduledJobs, 'Trigger should schedule 1 Rescheduled Apex Job');
    }
    
    @isTest
    private static void beforeDeleteTest() {

        List<GW_Volunteers__Volunteer_Job__c> volunteerJobs = generateVolunteerJobs(3);

        Integer numberOfScheduledJobs = 0;

        Test.startTest();
        insert volunteerJobs;

        delete volunteerJobs;

        List<String> filters = new List<String>();
        
        for (GW_Volunteers__Volunteer_Job__c job : volunteerJobs) {
            filters.add('%' + String.valueOf(job.Id) + '%');
        }
        
        System.debug(filters);

        numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE :filters];
        Test.stopTest();

        System.assertEquals(0, numberOfScheduledJobs, 'Trigger should remove Scheduled Apex Jobs');
    }
    
    @isTest
    private static void afterDeleteTest() {

    }
    
    @isTest
    private static void afterUndeleteTest() {

    }

    private static List<GW_Volunteers__Volunteer_Job__c> generateVolunteerJobs(Integer numberOfJobs) {
        Contact responsiblePerson = new Contact();
        Contact volunteer = new Contact();

        Campaign campaign = [
            SELECT Id 
            FROM Campaign 
            WHERE Name = 'Test Campaign'
            LIMIT 1
        ];

        Organization__c organization = [
            SELECT Id, Region__c, District__c, City__c, City_District__c 
            FROM Organization__c 
            WHERE Name = 'Test Organization' 
            LIMIT 1
        ];

        for (Contact contact : [SELECT Id, FirstName, LastName FROM Contact WHERE FirstName IN ('ResponsiblePerson', 'Volunteer') LIMIT 2]) {
            if (contact.FirstName == 'ResponsiblePerson') {
                responsiblePerson = contact;
            } else {
                volunteer = contact;
            }
        }

        List<GW_Volunteers__Volunteer_Job__c> volunteerJobs = new List<GW_Volunteers__Volunteer_Job__c>();
        
        for (Integer i = 0; i < numberOfJobs; i++) {
            GW_Volunteers__Volunteer_Job__c volunteerJob = new GW_Volunteers__Volunteer_Job__c();
            volunteerJob.Name = 'Test Job '+i;
            volunteerJob.Job_Start__c = Datetime.now().addHours(5);
            volunteerJob.Job_End__c = Datetime.now().addHours(6);
            volunteerJob.Reminder_Time__c = 1;
            volunteerJob.Responsible_Person__c = responsiblePerson.Id;
            volunteerJob.GW_Volunteers__Campaign__c = campaign.Id;
            volunteerJob.GW_Volunteers__Inactive__c = i > 1;
            volunteerJob.GW_Volunteers__Display_on_Website__c = false;
            volunteerJob.GW_Volunteers__Description__c = 'Test Description';
            volunteerJob.Organizer_Comment__c = 'Test Comment';
            volunteerJob.GW_Volunteers__Skills_Needed__c = 'Manual Labor';
            volunteerJob.Organization__c = organization.Id;
            volunteerJob.Region__c = organization.Region__c;
            volunteerJob.District__c = organization.District__c;
            volunteerJob.City__c = organization.City__c;
            volunteerJob.District__c = organization.District__c;
            volunteerJob.City_District__c = organization.City_District__c;
            volunteerJob.Street__c = 'Test Street';

            volunteerJobs.add(volunteerJob);
        }

        return volunteerJobs;
    }
}
