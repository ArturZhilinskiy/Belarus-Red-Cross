@isTest
public with sharing class TestDataFactory {
    
    private static final String STAGING_BATCHTIMESTAMP = '1565877873';
    private static final Decimal STAGING_AMOUNT = 1;
    private static final String STAGING_PAYMENT_TYPE = '10';
    private static final String STAGING_EXP_DATE = '2020-11-30';
    private static final String RECURRING_TOKEN = '920762012';
    
    public static void createTestData() {
        
        RC_Recurring_Donation_Settings__c settings = new RC_Recurring_Donation_Settings__c(
            Name = 'Payment attempt settings',
            Second_Attempt__c = 1.0,
            Third_Attempt__c = 3.0,
            Fourth_Attempt__c = 14.0
        );
        insert settings;
        
        Account redCross = generateAccount('Red Cross', Utility.getRecordTypeId('Account', 'Organization'));
        Account globalAgency = generateAccount('GlobalAgency', Utility.getRecordTypeId('Account', 'Organization'));
        insert new List<Account>{redCross, globalAgency}; 
            
        Lead tabitha = TestDataFactory.generateLead('Tabitha', 'Myers', 'Red Cross', 'tabitha@mail.com', '10', '10', 1); // for Initiation Payment
        Lead jerry = TestDataFactory.generateLead('Jerry', 'Myers', 'Red Cross', 'jerry@mail.com', '20', '20', null); // for OneTime Payment
        insert new List<Lead>{tabitha, jerry};
            
        Contact alex = generateContact('Alex', 'Oakes', redCross.Id, '', '', null); //red cross employee
        Contact bob = TestDataFactory.generateContact('Bob', 'Furguston', redCross.Id, '40', '40', 1); // for Initiation Payment
        bob.Email = 'bob@gmail.com';
        Contact barbara = TestDataFactory.generateContact('Barbara', 'Furguston', redCross.Id, '50', '50', null); // for OneTime Payment
        Contact john = TestDataFactory.generateContact('John', 'Smith', redCross.Id, '60', '60', 1); // for Recurring Payment
        insert new List<Contact>{alex, bob, barbara, john};


        
    }
    
    public static Contact generateContact(String fname, String lname, Id accountId, String customerId, String orderNumber, Integer paymentDay) {
        Contact theContact = new Contact();
        theContact.FirstName = fname;
        theContact.LastName = lname;
        theContact.AccountId = accountId;
        theContact.CustomerId__c = customerId;
        theContact.OrderNumber__c = orderNumber;
        theContact.PaymentDay__c = paymentDay;
        return theContact;
    }
    
    public static RecurringDonation__c generateRecurringDonation(Decimal amount, Id contId, Date last, Date next){
        RecurringDonation__c recurring = new RecurringDonation__c();
        recurring.Amount__c = amount;
        recurring.Contact__c = contId;
        recurring.LastPaymentDate__c = last;
        recurring.NextPaymentDate__c = next;
        recurring.RecurringToken__c = RECURRING_TOKEN;
        recurring.Status__c = 'Active';
        return recurring;
    }
    
    public static Lead generateLead(String fName, String lName, String company, String email, String customerId, String orderNumber, Integer paymentDay) {
        Lead theLead = new Lead();
        theLead.Lastname = lName;
        theLead.Firstname = fName;
        theLead.company = company;
        theLead.Email = email;
        theLead.CustomerId__c = customerId;
        theLead.OrderNumber__c = orderNumber;
        theLead.PaymentDay__c = paymentDay;
        return theLead;
    }
    
    public static Account generateAccount(String name, String recordTypeId) {
        Account theAccount = new Account();
        theAccount.Name = name;
        theAccount.RecordTypeId = recordTypeId;
        return theAccount;
    }
    
    public static npe01__OppPayment__c generatePayment(Date paymentDate, Boolean paid, Id oppId, Id contactId){
        npe01__OppPayment__c payment = new npe01__OppPayment__c();
        payment.npe01__Payment_Date__c = paymentDate;
        payment.npe01__Paid__c = paid;
        payment.npe01__Opportunity__c = oppId;
        payment.Contact__c = contactId;
        return payment;
    }
    
    public static DonationStaging__c generateRecuringStaging(String customerOrderId, String siteOrderId, String transactionId, Decimal amount, String paymentType) {
        DonationStaging__c staging = new DonationStaging__c();
        staging.BatchTimestamp__c = STAGING_BATCHTIMESTAMP;
        staging.CustomerId__c = customerOrderId;
        staging.SiteOrderId__c = siteOrderId;
        staging.TransactionId__c = transactionId;
        staging.Amount__c = amount;
        staging.PaymentType__c = paymentType;
        return staging;
    }
    
    public static DonationStaging__c generateOneTimeStaging(String customerId, String siteOrderId, String transactionId) {
        DonationStaging__c staging = generateDefaultStaging(customerId, siteOrderId, transactionId);
        staging.RecordTypeId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_ONE_TIME);
        return staging;
    } 
    
    public static DonationStaging__c generateInitiationStaging(String customerId, String siteOrderId, String transactionId, String card, String recurringToken) {
        DonationStaging__c staging = generateDefaultStaging(customerId, siteOrderId, transactionId);
        staging.RecordTypeId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_INITIATION);
        staging.Card__c = card;
        staging.RecurringToken__c = recurringToken;
        staging.OfferExpDate__c = STAGING_EXP_DATE;
        return staging;
    }
    
    public static DonationStaging__c generateRecurringStaging(String customerId, String siteOrderId, String transactionId) {
        DonationStaging__c staging = generateDefaultStaging(customerId, siteOrderId, transactionId);
        staging.RecordTypeId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
        return staging;
    }
    public static DonationStaging__c generateFailedRecurringStaging(String customerId, String siteOrderId, String transactionId) {
        DonationStaging__c staging = generateFailedStaging(customerId, siteOrderId, transactionId);
        staging.RecordTypeId = Utility.getRecordTypeId(Utility.STAGING_API_NAME, Utility.STAGING_RECORD_TYPE_RECURRING);
        return staging;
    }
    
    public static Opportunity generateOpportunity(Id accountId, Id contactId) {
        Opportunity theOpp = new Opportunity();
        theOpp.Name = Utility.OPP_MEMBERSHIP_RECORD_TYPE;
        theOpp.StageName = 'Prospecting';
        theOpp.CloseDate = Date.today().addDays(365);
        theOpp.AccountId = accountId;
        theOpp.ContactId = contactId;
        theOpp.npsp__Primary_Contact__c = contactId;
        theOpp.RecordTypeId = Utility.getRecordTypeId('Opportunity', Utility.OPP_MEMBERSHIP_RECORD_TYPE);
        return theOpp;
    }
    
    public static Card__c generateCard(Id contId, Date validThru){
        Card__c card = new Card__c();
        card.ValidThru__c = validThru;
        card.Contact__c = contId;
        return card;
    }

    public static Campaign generateCampaign(String name, Boolean isActive) {
        Campaign campaign = new Campaign (
                Name = name,
                IsActive = isActive
        );
        return campaign;
    }

    public static GW_Volunteers__Volunteer_Job__c generateVolunteerJob(String name, String campaignId, String skills, String description, Map<String, String> loc, Boolean webDisplay) {
        GW_Volunteers__Volunteer_Job__c volunteerJob = new GW_Volunteers__Volunteer_Job__c (
                Name = name,
                GW_Volunteers__Campaign__c = campaignId,
                GW_Volunteers__Display_on_Website__c = webDisplay,
                GW_Volunteers__Skills_Needed__c = skills,
                Job_Start__c = System.now(),
                Job_End__c = System.now().addHours(1),
                Organization__c = loc.get('org'),
                Region__c = loc.get('region'),
                City__c = loc.get('city'),
                District__c = loc.get('district'),
                City_District__c = loc.get('cityDistrict'),
                Street__c = loc.get('street'),
                GW_Volunteers__Description__c = description
        );
        return volunteerJob;
    }

    public static GW_Volunteers__Volunteer_Hours__c generateVolunteerHours(String currContact, String status, String jobId) {
        GW_Volunteers__Volunteer_Hours__c volunteerHours = new GW_Volunteers__Volunteer_Hours__c (
                GW_Volunteers__Volunteer_Job__c = jobId,
                GW_Volunteers__Contact__c = currContact,
                GW_Volunteers__Status__c = status,
                GW_Volunteers__Number_of_Volunteers__c = 1,
                GW_Volunteers__Start_Date__c = Date.today()
        );
        return volunteerHours;
    }
    
    private static DonationStaging__c generateDefaultStaging(String customerId, String siteOrderId, String transactionId) {
        DonationStaging__c staging = new DonationStaging__c();
        staging.CustomerId__c = customerId;
        staging.SiteOrderId__c = siteOrderId;
        staging.TransactionId__c = transactionId;
        staging.Status__c = 'New';
        staging.BatchTimestamp__c = STAGING_BATCHTIMESTAMP;
        staging.Amount__c = STAGING_AMOUNT;
        staging.PaymentType__c = STAGING_PAYMENT_TYPE;
        return staging;
    }     

    private static DonationStaging__c generateFailedStaging(String customerId, String siteOrderId, String transactionId) {
        DonationStaging__c staging = new DonationStaging__c();
        staging.CustomerId__c = customerId;
        staging.SiteOrderId__c = siteOrderId;
        staging.TransactionId__c = transactionId;
        staging.Status__c = 'New';
        staging.BatchTimestamp__c = STAGING_BATCHTIMESTAMP;
        staging.Amount__c = STAGING_AMOUNT;
        staging.PaymentType__c = '3';
        return staging;
    }

}