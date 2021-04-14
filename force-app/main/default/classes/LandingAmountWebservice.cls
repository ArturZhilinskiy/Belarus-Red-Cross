@RestResource(urlMapping='/landingamount/*')
global class LandingAmountWebservice {
    static final Date FROM_DATE = Date.newinstance(2020, 12, 18);

    @HttpGet
    global static void doGet() {
        String siteorder = RestContext.request.params.get('siteorder');
        if (String.isNotBlank(siteorder)) {
            Object webserviceResponse = getTotalPayments(siteorder);
            if (webserviceResponse != null) sendResponse(webserviceResponse);
            else sendResponse(0);
        } else sendResponse('Incorrect resource query param!');
    }

    /*static Object getTotalPayments(String requestBody) {
        String siteOrder = '%' + requestBody + '%';
        List<AggregateResult> paidOppPayments = [
            SELECT SUM(npe01__Payment_Amount__c)
            FROM npe01__OppPayment__c
            WHERE npe01__Paid__c = true
                AND Staging__c IN (
                        SELECT Id
                        FROM DonationStaging__c
                        WHERE SiteOrderId__c LIKE :siteOrder
                            AND CreatedDate >= :FROM_DATE
                    )
        ];*/

//hotfix by Eugene K.
        static Object getTotalPayments(String requestBody) {
            String siteOrder = '%' + requestBody + '%';
            List<AggregateResult> paidOppPayments = [
                    SELECT SUM(Amount__c)
                    FROM DonationStaging__c
                    WHERE (PaymentType__c = '1' OR PaymentType__c = '4')
                    AND SiteOrderId__c LIKE :siteOrder
                    AND CreatedDate >= :FROM_DATE
            ];


            return paidOppPayments[0].get('expr0');
    }

    static void sendResponse(Object serviceResponse) {
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(String.valueOf(serviceResponse));
    }
}