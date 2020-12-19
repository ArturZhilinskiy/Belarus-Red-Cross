public with sharing class ParseService {
    
    // private static DonationStaging__c newStaging; 
    
    // static{
    //     newStaging = new DonationStaging__c(Status__c = Utility.mainSettings.Default_New_Staging_Status__c);
    // }
    

    public static DonationStaging__c parseXML(String strXml){
        DonationStaging__c newStaging = new DonationStaging__c(Status__c = Utility.mainSettings.Default_New_Staging_Status__c);
        newStaging.Xml__c = strXml;
        Dom.Document doc = new Dom.Document();
        doc.load(strXml);
        Dom.XMLNode root = doc.getRootElement();
        walkThrough(root, newStaging);
        return newStaging;
    }
    
    private static void walkThrough(DOM.XMLNode node, DonationStaging__c newStaging) {
        Map<String, String> xmlToStaging = xmlToStaging();
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            String nodeName = node.getName();
            String nodeText = node.getText();
            String stagingField = xmlToStaging.get(nodeName);
            if (String.isNotEmpty(stagingField)){
                buildStaging(stagingField, nodeText, newStaging);
            }

        }
        for (Dom.XMLNode child: node.getChildElements()) {
            walkThrough(child, newStaging);
        }
    }
    
    private static void buildStaging(String field, String value, DonationStaging__c newStaging) {
        Schema.DisplayType typeFieldValue = Utility.getFieldType(Utility.STAGING_API_NAME, field);
        if (typeFieldValue == Schema.DisplayType.Double){
            newStaging.put(field, Decimal.valueOf(value));
        }else{
            newStaging.put(field, value);
        }
    }
    
    private static Map<String, String> xmlToStaging() {
        return new Map<String, String> {
            'BatchTimestamp' => 'BatchTimestamp__c',
            'CurrencyId' => 'CurrencyId__c',
            'Amount' => 'Amount__c',
            'PaymentMethod' => 'PaymentMethod__c',
            'OrderId' => 'OrderId__c',
            'SiteOrderId' => 'SiteOrderId__c',
            'TransactionId' => 'TransactionId__c',
            'PaymentType' => 'PaymentType__c',
            'RRN' => 'RRN__c',
            'WsbSignature' => 'WsbSignature__c',
            'Action' => 'Action__c',
            'RC' => 'RC__c',
            'Approval' => 'Approval__c',
            'Card' => 'Card__c',
            'Cardholder' => 'Cardholder__c',
            'CustomerId' => 'CustomerId__c',
            'RecurringToken' => 'RecurringToken__c',
            'OfferExpDate' => 'OfferExpDate__c',
            'RCText' => 'RCText__c',
            'OperationType' => 'OperationType__c'                
        };
    }
}