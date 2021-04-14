import { LightningElement, wire } from 'lwc';
import fetchFooterData from '@salesforce/apex/CommunityFooterController.fetchFooterData';
import fontsForSocialMedia from '@salesforce/resourceUrl/FontAwesome';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class CommunityFooter extends LightningElement {

    footerData;

    @wire(fetchFooterData)
    eventCampaigns(value) {
        const {data, error} = value;
        if(data) {
            let footerDataMap = {  
                    BRC_Name : data.BRC_Name__c,
                    Address : data.Address__c,
                    Site : data.Site__c,
                    Site_Name : data.Site__c.split("//")[1],
                    All_BRC_Addresses_Text : data.All_BRC_Addresses_Text__c,
                    All_BRC_Addresses_Link : data.All_BRC_Addresses_Link__c,
                    Portal_QA_Text : data.Portal_QA_Text__c,
                    Portal_QA_Email : data.Portal_QA_Email__c,
                    Portal_QA_Email_Link : 'mailto:' + data.Portal_QA_Email__c,
                    Portal_QA_Phone : data.Portal_QA_Phone__c,
                    Portal_QA_Phone_Link : 'tel:' + data.Portal_QA_Phone__c,
                    Facebook_Link : data.Facebook_Link__c,
                    Instagram_Link : data.Instagram_Link__c,
                    VK_Link : data.VK_Link__c,
                    Telegram_Link : data.Telegram_Link__c,
                    Viber_Link : data.Viber_Link__c
            };

            this.footerData = JSON.parse(JSON.stringify(footerDataMap));
            this.error = undefined;

        } else if(error) {
            this.footerData = [];
            this.error = 'No events are found';
        }
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, fontsForSocialMedia + '/css/all.min.css')
        ]).catch(error => {
             console.log(error);
        });
    }
}