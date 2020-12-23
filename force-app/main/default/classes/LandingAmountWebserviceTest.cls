@IsTest
private class LandingAmountWebserviceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createTestData();
    }

    @IsTest
    static void testSuccessfulGet() {
        final String SITE_ORDER = 'Epam-COVID19';
        final Decimal PAYMENT_AMOUNT_1 = 30.00;
        final Decimal PAYMENT_AMOUNT_2 = 20.00;
        Account account = [SELECT Id FROM Account LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 2];
        Opportunity opp1 = TestDataFactory.generateOpportunity(account.Id, contacts[0].Id);
        Opportunity opp2 = TestDataFactory.generateOpportunity(account.Id, contacts[1].Id);
        insert new List<Opportunity>{opp1, opp2};
        DonationStaging__c staging1 = TestDataFactory.generateRecuringStaging(null, SITE_ORDER, '111222333', PAYMENT_AMOUNT_1, '4');
        DonationStaging__c staging2 = TestDataFactory.generateRecuringStaging(null, SITE_ORDER, '111222333', PAYMENT_AMOUNT_2, '4');
        insert new List<DonationStaging__c>{staging1, staging2};
        npe01__OppPayment__c payment1 = TestDataFactory.generatePayment(Date.newinstance(2020, 12, 19), true, opp1.Id, contacts[0].Id);
        payment1.Staging__c = staging1.Id;
        payment1.npe01__Payment_Amount__c = staging1.Amount__c;
        npe01__OppPayment__c payment2 = TestDataFactory.generatePayment(Date.newinstance(2020, 12, 18), true, opp2.Id, contacts[1].Id);
        payment2.Staging__c = staging2.Id;
        payment2.npe01__Payment_Amount__c = staging2.Amount__c;
        npe01__OppPayment__c payment3 = TestDataFactory.generatePayment(Date.newinstance(2020, 11, 18), true, opp2.Id, contacts[1].Id);
        payment2.Staging__c = staging2.Id;
        payment2.npe01__Payment_Amount__c = staging2.Amount__c;
        insert new List<npe01__OppPayment__c>{payment1, payment2, payment3};

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = String.valueOf(URL.getSalesforceBaseUrl()) + '/services/apexrest/landingamount';
        RestContext.request.addParameter('siteorder', SITE_ORDER);
        RestContext.request.httpMethod = 'GET';

        Test.startTest();
        LandingAmountWebservice.doGet();
        Test.stopTest();

        System.assertEquals(PAYMENT_AMOUNT_1 + PAYMENT_AMOUNT_2, Decimal.valueOf(RestContext.response.responseBody.toString()));
    }

    @IsTest
    static void testUnsuccessfulGet() {
        final String SITE_ORDER = 'Epam-COVID19';
        final Decimal PAYMENT_AMOUNT = 30.00;
        Account account = [SELECT Id FROM Account LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp1 = TestDataFactory.generateOpportunity(account.Id, contact.Id);
        insert opp1;
        DonationStaging__c staging1 = TestDataFactory.generateRecuringStaging(null, 'TEST', '111222333', PAYMENT_AMOUNT, '4');
        insert staging1;
        npe01__OppPayment__c payment1 = TestDataFactory.generatePayment(Date.today(), true, opp1.Id, contact.Id);
        payment1.Staging__c = staging1.Id;
        payment1.npe01__Payment_Amount__c = staging1.Amount__c;
        insert payment1;

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = String.valueOf(URL.getSalesforceBaseUrl()) + '/services/apexrest/landingamount/';
        RestContext.request.addParameter('siteorder', SITE_ORDER);
        RestContext.request.httpMethod = 'GET';

        Test.startTest();
        LandingAmountWebservice.doGet();
        Test.stopTest();

        System.assertEquals(String.valueOf(0), RestContext.response.responseBody.toString());
    }

    @IsTest
    static void testGetResourseWoQueryParam() {
        final String SITE_ORDER = '';

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = String.valueOf(URL.getSalesforceBaseUrl()) + '/services/apexrest/landingamount';
        RestContext.request.addParameter('siteorder', SITE_ORDER);
        RestContext.request.httpMethod = 'GET';

        Test.startTest();
        LandingAmountWebservice.doGet();
        Test.stopTest();

        System.assertEquals('Incorrect resource query param!', RestContext.response.responseBody.toString());
    }
}