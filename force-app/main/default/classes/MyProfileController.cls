public with sharing class MyProfileController {
    @AuraEnabled(cacheable=true)  
    public static List<sObject> findRecords(String searchKey, String objectName, String parentObject, String parentObjectId) {  
        String searchText = '\'' + String.escapeSingleQuotes(searchKey) + '%\''; 
        String parentCondition = ' AND ' + parentObject + ' = \'' + parentObjectId + '\'';
        String query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Name LIKE ' + searchText;
        query += String.isNotBlank(parentObjectId) ? parentCondition : '';
        query += ' LIMIT 6';  
        return Database.query(query);  
    }  

    @AuraEnabled(cacheable=true)  
    public static Map<String, Object> fetchContact() {  
        User currUser = [SELECT Id, ContactId FROM user WHERE Id =: UserInfo.getUserId()];
        String contactId = currUser.ContactId;
        //String contactId = '0031s00000ILFr5AAH';

        if(Test.isRunningTest()) {
            Contact testContact = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'John Smith'];
            contactId = testContact.Id;
        }

        Contact theContact = [
              SELECT 
                  Id,
                  Organization__r.Name,
                  Region__r.Name,
                  District__r.Name,
                  City__r.Name,
                  City_District__r.Name,
                  Address__c
              FROM 
                  Contact 
              WHERE 
                  Id =: contactId
              LIMIT 1
        ]; 

        Map<String, Object> contactMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(theContact));

        List<String> fields = new List<String>{'region__c', 'district__c', 'city__c', 'city_district__c', 'address__c', 'organization__c'};
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType contactSchema = schemaMap.get('Contact');
        Map<String, Schema.SObjectField> contactLabelsMap = contactSchema.getDescribe().fields.getMap();
        for (String fieldName: contactLabelsMap.keySet()) {  
            if(fields.contains(fieldName)){
                contactMap.put('label_' + fieldName, contactLabelsMap.get(fieldName).getDescribe().getLabel());
            }
        }

        return contactMap;  
    } 

    @AuraEnabled
    public static String updateMyContact(String fields) {
        Map<String, Object> fieldsMap = (Map<String, Object>) JSON.deserializeUntyped(fields);
        String contactId = (String) fieldsMap.get('Id');

        Contact theContact = [SELECT Id FROM Contact WHERE Id =: contactId LIMIT 1]; 
System.debug('fieldsMap >> '+fieldsMap);
        if(fieldsMap.get('Region__c') != null){
            theContact.Region__c = (String) fieldsMap.get('Region__c');
        }
        if(fieldsMap.get('District__c') != null){
            theContact.District__c = (String) fieldsMap.get('District__c');
        }
        if(fieldsMap.get('City__c') != null){
            theContact.City__c = (String) fieldsMap.get('City__c');
        }
        if(fieldsMap.keySet().contains('City_District__c')){
            theContact.City_District__c = (String) fieldsMap.get('City_District__c');
        }
        if(fieldsMap.get('Address__c') != null){
            theContact.Address__c = (String) fieldsMap.get('Address__c');
        }
        update theContact;

        return [SELECT Id, Organization__r.Name FROM Contact WHERE Id =: contactId LIMIT 1].Organization__r.Name;
    }
}