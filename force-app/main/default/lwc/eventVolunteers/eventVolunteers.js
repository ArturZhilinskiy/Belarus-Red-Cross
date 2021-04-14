import { LightningElement, track, wire, api } from 'lwc';
import findVolunteerHours from '@salesforce/apex/FullCalendarController.findVolunteerHours';
import {refreshApex} from '@salesforce/apex';

import NoVolunteersGoLabel from '@salesforce/label/c.NoVolunteersGoLabel';
import TotalVolunteersLabel from '@salesforce/label/c.TotalVolunteersLabel';

export default class EventVolunteers extends LightningElement {

    @track volunteersList;
    @track volunteersMessage;
    @track totalVolunteers;
    @track totalMessage = TotalVolunteersLabel;

    @api jobId;
    @api status;

    @wire(findVolunteerHours, { jobId: '$jobId', status: '$status' })
    eventVolunteer(value) {
        this.wiredVolunteers = value;
        const {data, error} = value;
        if(data) {
            if (data.length === 0) {
                this.volunteersList = [];
                this.totalVolunteers = undefined;
                this.volunteersMessage = NoVolunteersGoLabel; 
            } else {  
                this.volunteersList = data;
                this.totalVolunteers = data.length;
                this.volunteersMessage = "";
            }
                this.error = undefined;
                refreshApex(this.wiredVolunteers);
        } else if(error) {
            this.error = error;
            this.volunteersList = undefined;
        }
   }
}