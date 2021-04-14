@isTest
public class MyProfileControllerTest {
    @isTest
    public static void findRecordsTest() {
        Region__c regionError = new Region__c (name = 'errorRegion');
        insert regionError;
        Region__c region = new Region__c (name = 'testRegion');
        insert region;
        District__c district = new District__c (name = 'testDistrict', Region__c = region.Id);
        insert district;

        List<District__c> districts = MyProfileController.findRecords('test', 'District__c', 'Region__c', regionError.Id);
        System.assert(districts.size() == 0);

        List<District__c> newDistricts = MyProfileController.findRecords('test', 'District__c', 'Region__c', region.Id);
        System.assertNotEquals(newDistricts, null);
        System.assertEquals(newDistricts[0].name, 'testDistrict');
    }

    @isTest
    public static void fetchContactTest() {
        TestDataFactory.createTestData();
        Contact theContact = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'John Smith'];

        Organization__c org = new Organization__c (name = 'testOrg');
        insert org;
        Region__c region = new Region__c (name = 'testRegion');
        insert region;

        theContact.Organization__c = org.id;
        theContact.Region__c = region.id;
        update theContact;

        Map<String, Object> fetchedContact = MyProfileController.fetchContact();

        System.assertNotEquals(fetchedContact, null);
        System.assertEquals(fetchedContact.get('Organization__c'), org.Id);
        System.assertEquals(fetchedContact.get('Region__c'), region.Id);
    }
}