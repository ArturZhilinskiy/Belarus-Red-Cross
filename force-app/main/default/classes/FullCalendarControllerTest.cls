@isTest
public class FullCalendarControllerTest {

    @testSetup
    private static void setup() {
        TestDataFactory.createTestData();

       

        Contact theContact = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'John Smith'];
        
        Contact responsiblePerson = new Contact(LastName = 'Zhilinskiy', Email = 'test@gmail.com.com');
        insert responsiblePerson;

        Campaign campaign = TestDataFactory.generateCampaign('testCampaign', true);
        insert campaign;

        Region__c region = new Region__c (name = 'testRegion');
        insert region;
        District__c district = new District__c (name = 'testDistrict', Region__c = region.Id);
        insert district;
        City__c city = new City__c (name = 'testCity', 	District__c = district.Id);
        insert city;
        City_District__c cityDistrict = new City_District__c (name = 'testCityDistrict', City__c = city.Id);
        insert cityDistrict;
        Organization__c org = new Organization__c (name = 'testOrg', Responsible_Person__c = responsiblePerson.Id);
        insert org;

        theContact.Organization__c = org.id;
        theContact.Region__c = region.id;
        theContact.City__c = city.id;
        theContact.District__c = district.id;
        theContact.City_District__c = cityDistrict.id;
        theContact.GW_Volunteers__Volunteer_Skills__c = 'testSkill';
        theContact.Email = 'my@mail.com';
        update theContact;

        Map<String, String> locMap = new Map<String, String> {
                'org' => org.Id,
                'region' => region.Id,
                'city' => city.Id,
                'district' => district.Id,
                'cityDistrict' => cityDistrict.Id,
                'street' => 'main street 25'
        };

       

        GW_Volunteers__Volunteer_Job__c volunteerJob = TestDataFactory.generateVolunteerJob('testJob', campaign.Id, '', 'desc', locMap, true);
        volunteerJob.Responsible_Person__c = responsiblePerson.Id;
        insert volunteerJob;



        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        User u2 = new User(
            Alias = 'newUser', 
            Email='newuser@testorg.com',
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='newnewonehundredpercentnewuser@testorg.com'
        );

        System.runAs(u2) {

            EmailTemplate template = new EmailTemplate();
            template.Name = 'testEmailTemplate';
            template.Subject = 'testTemplateSubject';
            template.isActive = true;
            template.DeveloperName = 'testEmailTemplate';
            template.TemplateType = 'text';
            template.HtmlValue = 'Test MF test';
            template.FolderId = UserInfo.getUserId();

            insert template;


            VolunteerJobSettings__c customSetting = new VolunteerJobSettings__c();
            customSetting.Unsubscribe_Email_Template_For_RP__c = template.Name;
            customSetting.SetupOwnerId = UserInfo.getOrganizationId();
            customSetting.Email_Template_With_List_Of_Participants__c = template.Name;
            customSetting.Participants_Email_Flow__c = template.Name;
            customSetting.Reminder_Email_Template_For_Volunteer__c = template.Name;
            customSetting.Responsible_Person_Email_Flow__c = template.Name;
            insert customSetting;
        }
    }

    @isTest
    public static void fetchEventsTest() {
        Contact theContact = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'John Smith'];
        GW_Volunteers__Volunteer_Job__c volunteerJob = [SELECT Id, GW_Volunteers__Skills_Needed__c FROM GW_Volunteers__Volunteer_Job__c WHERE Name = 'testJob'];

        GW_Volunteers__Volunteer_Hours__c volunteerHours = TestDataFactory.generateVolunteerHours(theContact.Id, 'Prospect', volunteerJob.Id);
        insert volunteerHours;

        System.assertNotEquals(FullCalendarController.fetchEvents(), null);

        volunteerJob.GW_Volunteers__Skills_Needed__c = 'testSkill';
        update volunteerJob;

        System.assertNotEquals(FullCalendarController.fetchEvents(), null);
    }

    @isTest
    public static void confirmCancelJobTest() {
        GW_Volunteers__Volunteer_Job__c volunteerJob = [SELECT Id FROM GW_Volunteers__Volunteer_Job__c WHERE Name = 'testJob'];

        String jobData = '{"jobId":"'+volunteerJob.Id+'","jobStart":"'+System.now()+'","jobEnd":"'+System.now().addHours(1)+'"}';

        FullCalendarController.confirmCancelJob(jobData, 'Cancelled', 'Confirmed');
        List<GW_Volunteers__Volunteer_Hours__c> volunteerHours = [SELECT Id, GW_Volunteers__Status__c FROM GW_Volunteers__Volunteer_Hours__c];

        System.assertNotEquals(volunteerHours, null);
        System.assertEquals(volunteerHours[0].GW_Volunteers__Status__c, 'Confirmed');

        FullCalendarController.confirmCancelJob(jobData, 'Confirmed', 'Cancelled');
        GW_Volunteers__Volunteer_Hours__c volunteerHours1 = [SELECT Id, GW_Volunteers__Status__c FROM GW_Volunteers__Volunteer_Hours__c WHERE Id =: volunteerHours[0].Id];

        System.assertEquals(volunteerHours1.GW_Volunteers__Status__c, 'Cancelled');
    }

    @isTest
    public static void findVolunteerHoursTest() {
        Contact theContact = [SELECT Id, Name FROM Contact WHERE Name = 'John Smith'];
        GW_Volunteers__Volunteer_Job__c volunteerJob = [SELECT Id, GW_Volunteers__Skills_Needed__c FROM GW_Volunteers__Volunteer_Job__c WHERE Name = 'testJob'];

        GW_Volunteers__Volunteer_Hours__c volunteerHours = TestDataFactory.generateVolunteerHours(theContact.Id, 'Confirmed', volunteerJob.Id);
        insert volunteerHours;

        List<GW_Volunteers__Volunteer_Hours__c> volunteerHoursList = FullCalendarController.findVolunteerHours(volunteerJob.Id, 'Confirmed');
        System.assertNotEquals(volunteerHoursList, null);
        System.assertEquals(volunteerHoursList[0].GW_Volunteers__Contact__r.Name, theContact.Name);
    }
}