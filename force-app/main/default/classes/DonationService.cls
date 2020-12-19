public with sharing class DonationService {
    
    /*public static Date getNextPaymentDate(String paymentType, Decimal paymentDay){
        Date now = Date.today();
        Date nextPaymentDate = Date.newInstance(now.year(), now.month(), Integer.valueOf(paymentDay));
        Boolean contains = Utility.SUCCESS_PAYMENT_TYPES.contains(paymentType);
        return contains ? nextPaymentDate.addMonths(1) : now.addDays(1);
    }
    
    public static Date getLastPaymentDate(DonationStaging__c staging){
        Boolean contains = Utility.SUCCESS_PAYMENT_TYPES.contains(staging.PaymentType__c);
        return contains ? Utility.convertUnixTimestamp(staging.BatchTimestamp__c) : null;
    }*/
    
    public static npe01__OppPayment__c generatePayment(DonationStaging__c staging, Id oppId, Id contactId){
        npe01__OppPayment__c payment = new npe01__OppPayment__c();
        payment.npe01__Payment_Amount__c = staging.Amount__c;
        payment.TransactionId__c = staging.TransactionId__c;
        payment.npe01__Payment_Date__c = Test.isRunningTest() ? Date.today() : Utility.convertUnixTimestamp(staging.BatchTimestamp__c);
        payment.Staging__c = staging.Id;
        payment.npe01__Paid__c = Utility.SUCCESS_PAYMENT_TYPES.contains(staging.PaymentType__c) ? TRUE : FALSE;
        payment.npe01__Opportunity__c = oppId;
        payment.Contact__c = contactId;
        payment.PaymentType__c = Utility.transactionTypes().get(staging.PaymentType__c);
        return payment;
    }
    
}