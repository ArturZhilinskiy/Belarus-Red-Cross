public with sharing class CommunityFooterController {
    @AuraEnabled(cacheable=true)  
    public static BRC_CommunityFooter__mdt fetchFooterData() {  
        BRC_CommunityFooter__mdt communityFooter = new BRC_CommunityFooter__mdt();
        communityFooter = [
            SELECT 
                BRC_Name__c,
                Address__c,
                Site__c,
                All_BRC_Addresses_Text__c,
                All_BRC_Addresses_Link__c,
                Portal_QA_Text__c,
                Portal_QA_Email__c,
                Portal_QA_Phone__c,
                Facebook_Link__c,
                Instagram_Link__c,
                VK_Link__c,
                Telegram_Link__c,
                Viber_Link__c
            FROM
                BRC_CommunityFooter__mdt
            WHERE 
                DeveloperName = 'Community_Footer' 
            LIMIT 1
        ];
        return communityFooter;  
    }
}