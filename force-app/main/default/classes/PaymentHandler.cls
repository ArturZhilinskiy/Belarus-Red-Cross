public with sharing class PaymentHandler {
    
    private static Map<String, Boolean> actionTypeToRunOnce = new Map<String, Boolean>();
    private static Date TODAYS_DATE = Date.today();

    private static Integer SECOND_ATTEMPT_DAY = Utility.getRecurringDonationSecondAttemptDay();
    private static Integer THIRD_ATTEMPT_DAY = Utility.getRecurringDonationThirdAttemptDay();
    private static Integer FOURTH_ATTEMPT_DAY = Utility.getRecurringDonationFourthAttemptDay();
    
    public static Boolean runOnce(String actionType) {
        Boolean runOnce = actionTypeToRunOnce.get(actionType);
        if (runOnce == null || runOnce == TRUE) {
            actionTypeToRunOnce.put(actionType, FALSE);
            return TRUE;
        }
        return FALSE;
    }
    
    public static void onAfterInsert(Map<Id, npe01__OppPayment__c> newPayments) {
        System.debug('PaymentHandler.onAfterInsert()');
        System.debug('Map<Id, npe01__OppPayment__c> newPayments = ' + newPayments);
        defineNextPaymentDateSucsess(newPayments);
        defineNextPaymentDateFailed(newPayments);
        bindPaymentsToRecurringDonations(newPayments);
        sendEmails(newPayments);
    }
    
    public static void sendEmails(Map<Id, npe01__OppPayment__c> newPayments) {
        Set<Id> contactIds = new Set<Id>();
        for(npe01__OppPayment__c pay: newPayments.values()){
            if(pay.Contact__c != null && pay.npe01__Paid__c == TRUE){
                contactIds.add(pay.Contact__c);
            }
        }
        List<Contact> contacts = [
            SELECT Email, ThanksForPaymentEmailSendingDate__c, InternalType__c, RecordType.Name
            FROM Contact 
            WHERE Id IN: contactIds AND Email != null AND RecordType.Name = 'Donor'
            LIMIT 50000
        ];
        ActivityService.sendPaymentSuccessEmails(contacts);
    }
    
    // method for success payments only
    private static void defineNextPaymentDateSucsess(Map<Id, npe01__OppPayment__c> newPayments) {
        System.debug('defineNextPaymentDateSucsess');
        List<Id> contactIds = getContactIdsWithSuccessPayments(new List<Id>(newPayments.keySet()));
        List<npe01__OppPayment__c> paymentsWithContactId = getSuccessPaymentsWithContactId(new List<Id>(newPayments.keySet()));
        List<RecurringDonation__c> recurrings = RecurringDonationService.getOpenRecurringsByContactIds(contactIds);
        System.debug('defineNextPaymentDateSucsess contactIds:' +contactIds);
        System.debug('defineNextPaymentDateSucsess paymentsWithContactId:' +paymentsWithContactId);
        System.debug('defineNextPaymentDateSucsess recurrings:' +recurrings);

        rescheduleNextPaymentDateSuccess(recurrings, paymentsWithContactId);
        System.debug('defineNextPaymentDateSucsess updated recurrings: ' +recurrings);
        update recurrings;
    }

    private static void rescheduleNextPaymentDateSuccess(List<RecurringDonation__c> recurrings, List<npe01__OppPayment__c> oldPayments) { 
        for(RecurringDonation__c recurring : recurrings){
            for(npe01__OppPayment__c payment : oldPayments){
                if(recurring.Contact__c == payment.npe01__Opportunity__r.ContactId){
                    recurring.NextPaymentDate__c = Date.newInstance(TODAYS_DATE.year(), TODAYS_DATE.month(), Integer.valueOf(recurring.PaymentDay__c)).addMonths(1);
                    if(recurring.Staging__c != null && recurring.Staging__r.BatchTimestamp__c != null){
                        recurring.LastPaymentDate__c = Utility.convertUnixTimestamp(recurring.Staging__r.BatchTimestamp__c);
                    }
                }
            } 
        }
    }


    private static void bindPaymentsToRecurringDonations(Map<Id, npe01__OppPayment__c> newPayments) {
        List<Id> contactIds = getContactIds(newPayments.values());
        List<RecurringDonation__c> recurrings = RecurringDonationService.getOpenRecurringsByContactIds(contactIds);
        System.debug(JSON.serializePretty(newPayments));
        List<npe01__OppPayment__c> processedRecords = new List<npe01__OppPayment__c>();
        for (npe01__OppPayment__c payment : newPayments.values()) {
            npe01__OppPayment__c updatedPayment = payment.clone(true, true, false, false);
            for (RecurringDonation__c recurringDonation : recurrings) {
                if (updatedPayment.Contact__c == recurringDonation.Contact__c) {
                    updatedPayment.Recurring_Donation__c = recurringDonation.Id;
                    processedRecords.add(updatedPayment);
                }
            }
        }
        System.debug('processedRecords: ' + processedRecords);
        update processedRecords;
    }

    private static List<Id> getContactIds(List<npe01__OppPayment__c> newPayments) {
        Set<Id> contactIds = new Set<Id>();
        for(npe01__OppPayment__c payment : newPayments){
            contactIds.add(payment.Contact__c);
        }
        System.debug('PaymentHandler.getContactIds(), contactIds = ' + contactIds);
        return new List<Id>(contactIds);
    }
    
    // method for failed payments only
    private static void defineNextPaymentDateFailed(Map<Id, npe01__OppPayment__c> newPayments) {
        System.debug('defineNextPaymentDateFailed');
        List<Id> contactIds = getContactsWithFailedPayments(new List<Id>(newPayments.keySet()));
        List<npe01__OppPayment__c> oldPayments = getPaymentsByContactIds(contactIds);
        List<RecurringDonation__c> recurrings = RecurringDonationService.getOpenRecurringsByContactIds(contactIds);
        System.debug('defineNextPaymentDateFailed contactIds:' +contactIds);
        System.debug('defineNextPaymentDateFailed oldPayments:' +oldPayments);
        System.debug('defineNextPaymentDateFailed recurrings:' +recurrings);

        rescheduleNextPaymentDateFailed(recurrings, oldPayments);
        System.debug('defineNextPaymentDateFailed updated recurrings: ' +recurrings);
        update recurrings;
    }

    private static void rescheduleNextPaymentDateFailed(List<RecurringDonation__c> recurrings, List<npe01__OppPayment__c> oldPayments) {
        for(RecurringDonation__c recurring : recurrings){
            List<Date> paymentDates = new List<Date>();
            for(npe01__OppPayment__c payment : oldPayments){
                if(recurring.Contact__c == payment.npe01__Opportunity__r.ContactId){
                    paymentDates.add(payment.npe01__Payment_Date__c);
                }
            } 
            System.debug('PaymentDates.size() = ' + paymentDates.size());

            recurring.NextPaymentDate__c = 
                paymentDates.size() == 1 ? 
                    TODAYS_DATE.month() == TODAYS_DATE.addDays(SECOND_ATTEMPT_DAY).month() ? TODAYS_DATE.addDays(SECOND_ATTEMPT_DAY) 
                    : Date.newInstance(TODAYS_DATE.year(), TODAYS_DATE.month(), Integer.valueOf(recurring.PaymentDay__c)).addMonths(1)
                : paymentDates.size() == 2 ?
                    TODAYS_DATE.month() == TODAYS_DATE.addDays(THIRD_ATTEMPT_DAY).month() ? TODAYS_DATE.addDays(THIRD_ATTEMPT_DAY) 
                    : Date.newInstance(TODAYS_DATE.year(), TODAYS_DATE.month(), Integer.valueOf(recurring.PaymentDay__c)).addMonths(1)
                : paymentDates.size() == 3 ?
                    TODAYS_DATE.month() == TODAYS_DATE.addDays(FOURTH_ATTEMPT_DAY).month() ? TODAYS_DATE.addDays(FOURTH_ATTEMPT_DAY) 
                    : Date.newInstance(TODAYS_DATE.year(), TODAYS_DATE.month(), Integer.valueOf(recurring.PaymentDay__c)).addMonths(1)
                : Date.newInstance(TODAYS_DATE.year(), TODAYS_DATE.month(), Integer.valueOf(recurring.PaymentDay__c)).addMonths(1);
        }
    }
    
    private static List<Id> getContactsWithFailedPayments(List<Id> paymentIds) {
        List<Id> contactIds = new List<Id>();
        List<String> types = new List<String>{Utility.STAGING_RECORD_TYPE_INITIATION, Utility.STAGING_RECORD_TYPE_RECURRING};
        List<npe01__OppPayment__c> payments = [
            SELECT Contact__c 
            FROM npe01__OppPayment__c 
            WHERE npe01__Paid__c = FALSE AND Type__c IN: types AND Id IN: paymentIds
        ];
        
        System.debug('PaymentHandler.getContactsWithFailedPayments(), payments = ' + payments);
        for(npe01__OppPayment__c payment : payments){
            contactIds.add(payment.Contact__c);
        }
        System.debug('PaymentHandler.getContactsWithFailedPayments(), contactIds = ' + contactIds);
        return contactIds;
    }
    
    private static List<Id> getContactIdsWithSuccessPayments(List<Id> paymentIds) {
        Set<Id> contactIds = new Set<Id>();
        List<String> types = new List<String>{Utility.STAGING_RECORD_TYPE_INITIATION, Utility.STAGING_RECORD_TYPE_RECURRING};
        List<npe01__OppPayment__c> payments = [
            SELECT Contact__c 
            FROM npe01__OppPayment__c 
            WHERE npe01__Paid__c = TRUE AND Type__c IN: types AND Id IN: paymentIds
        ];
        for(npe01__OppPayment__c payment : payments){
            contactIds.add(payment.Contact__c);
        }
        System.debug('PaymentHandler.getContactIdsWithSuccessPayments(), contactIds = ' + contactIds);
        return new List<Id>(contactIds);
    }

    private static List<npe01__OppPayment__c> getSuccessPaymentsWithContactId(List<Id> newPaymentsId) {
        List<String> types = new List<String>{Utility.STAGING_RECORD_TYPE_INITIATION, Utility.STAGING_RECORD_TYPE_RECURRING};
        return [
            SELECT 
                npe01__Opportunity__r.ContactId, 
                npe01__Paid__c, 
                npe01__Payment_Date__c, 
                Staging__c, 
                Staging__r.PaymentType__c
            FROM npe01__OppPayment__c 
            WHERE Id IN: newPaymentsId 
                AND Type__c =: types
                AND npe01__Paid__c = TRUE
            LIMIT 5000
        ];
    }
    
    private static List<npe01__OppPayment__c> getPaymentsByContactIds(List<Id> contactIds) {   
        List<String> types = new List<String>{Utility.STAGING_RECORD_TYPE_INITIATION, Utility.STAGING_RECORD_TYPE_RECURRING};
        List<npe01__OppPayment__c> payments = [
            SELECT 
                npe01__Opportunity__r.ContactId, 
                npe01__Paid__c, 
                npe01__Payment_Date__c, 
                Staging__c, 
                Staging__r.PaymentType__c
            FROM npe01__OppPayment__c 
            WHERE npe01__Opportunity__r.ContactId IN: contactIds 
                AND npe01__Payment_Date__c >: Date.today().addDays(-16) 
                AND npe01__Payment_Date__c <=: Date.today()
                AND Type__c =: types
                AND npe01__Paid__c = FALSE
            LIMIT 5000
        ];

        List<npe01__OppPayment__c> paymnetsInCurrentMonth = new List<npe01__OppPayment__c>();
        for (npe01__OppPayment__c payment : payments) {
            if (payment.npe01__Payment_Date__c.month() == Date.today().month()) {
                paymnetsInCurrentMonth.add(payment);
            }
        }

        return paymnetsInCurrentMonth;
    }
    
}