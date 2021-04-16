@isTest
public class LeadHandlerTest {
    @TestSetup
    static void makeData(){
        TestDataFactory.createTestData();
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

        Region__c region = new Region__c(Name = 'test');
        insert region;

        District__c district = new District__c(Name = 'test', Region__c = region.Id);
        insert district;

        City__c city = new City__c(Name = 'test', District__c = district.Id);
        insert city;

        City_District__c cityDistrict = new City_District__c(Name = 'test', City__c = city.Id);
        insert cityDistrict;

        Organization__c organization = new Organization__c(Name = 'test', City__c = city.Id, District__c = district.Id, City_District__c = cityDistrict.Id, Region__c = region.Id);
        insert organization;

        Campaign campaign = new Campaign();
        campaign.Name = 'test';
        campaign.Code__c = 'Volunteer - Web';
        campaign.Region__c = region.Id;
        campaign.District__c = district.Id;
        campaign.City__c = city.Id;
        campaign.City_District__c = cityDistrict.Id;
        insert campaign;
    }

    @isTest
    public static void onBeforeInsertTest() {
        delete [SELECT Id FROM Lead LIMIT 10000];

        Lead volunteer = new Lead(
            FirstName = 'Test',
            LastName = 'LeadVolunteer',
            Birthday__c = Date.valueOf('1998-12-22'),
            Email = 'testVolunteer2@gmail.com',
            Company = 'VRP',
            LeadSource = 'Volunteer - Web',
            Web2Lead_City__c = 'test',
            Web2Lead_Region__c = 'test',
            Representative_Id__c = '123Test123'
        );

        Lead duplicateVolunteer = new Lead(
            FirstName = 'Test',
            LastName = 'LeadVolunteer',
            Birthday__c = Date.valueOf('1998-12-22'),
            Email = 'testVolunteer2@gmail.com',
            Company = 'VRP',
            LeadSource = 'Volunteer - Web',
            Web2Lead_City__c = 'test',
            Web2Lead_Region__c = 'test'
        );

        Contact contact = new  Contact(LastName = 'Test', Email = 'testVolunteer2@gmail.com');
        insert contact;

        List<Lead> leads = new List<Lead>();
        leads.add(volunteer);
        leads.add(duplicateVolunteer);

        Test.startTest();
        insert leads;
        Test.stopTest();

        List<Lead> createdVolunteers = [SELECT Id FROM Lead WHERE RecordType.Name = 'Volunteer'];
        System.assertEquals(1, createdVolunteers.size());
    }

       
}
