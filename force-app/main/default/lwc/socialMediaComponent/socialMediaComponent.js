import { LightningElement, wire } from 'lwc';
import fetchMediaData from '@salesforce/apex/CommunityFooterController.fetchFooterData';
import fontsForSocialMedia from '@salesforce/resourceUrl/FontAwesome';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class SocialMediaComponent extends LightningElement {
    mediaData;

    @wire(fetchMediaData)
    eventCampaigns(value) {
        const {data, error} = value;
        if(data) {
            let dataMap = {  
                    Facebook_Link : data.Facebook_Link__c,
                    Instagram_Link : data.Instagram_Link__c,
                    VK_Link : data.VK_Link__c,
                    Telegram_Link : data.Telegram_Link__c,
                    Viber_Link : data.Viber_Link__c
            };
            this.mediaData = JSON.parse(JSON.stringify(dataMap));
            this.error = undefined;

        } else if(error) {
            this.mediaData = [];
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