import { LightningElement, track, wire } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import FullCalendarJS from '@salesforce/resourceUrl/FullCalendarJS';
import fetchEvents from '@salesforce/apex/FullCalendarController.fetchEvents';
import confirmCancelJob from '@salesforce/apex/FullCalendarController.confirmCancelJob';

import ConfirmJobBtnLabel from '@salesforce/label/c.ConfirmJobBtnLabel';
import CancelJobBtnLabel from '@salesforce/label/c.CancelJobBtnLabel';
import AllVolunteersTabLabel from '@salesforce/label/c.AllVolunteersTabLabel';
import InformationTabLabel from '@salesforce/label/c.InformationTabLabel';

export default class activitiesCalendar extends LightningElement {
    
    fullCalendarJsInitialised = false;
    eventsRendered = false;
    openSpinner = false;
    openModal = false;

    @track btnConfirmVisible = false;
    @track btnCancelVisible = false;
    @track selectedEvent = undefined;
    @track events = [];

    jobId;
    jobStart;
    jobEnd;

    label = {
        ConfirmJobBtnLabel,
        CancelJobBtnLabel,
        AllVolunteersTabLabel,
        InformationTabLabel
    };

    @wire(fetchEvents)
    eventObj({data, error}) {
        if(data) {
            let events = data.map(item => {
                return {  
                    id : item.id,
                    title : item.name,
                    start : item.start,
                    end : item.end,
                    jobStart : item.jobStart,
                    jobEnd : item.jobEnd,
                    loc : item.location,
                    region : item.region,
                    district : item.district,
                    city : item.city,
                    cityDistrict : item.cityDistrict,
                    street : item.street,
                    org : item.organization,
                    skills : item.skillsNeeded,
                    desc : item.description.replace(/(<([^>]+)>)/gi, ""),
                    jobStatus : item.status,
                    color : this.getEventColor(item.status)
                };
            });

            this.events = JSON.parse(JSON.stringify(events));
            this.error = undefined;

            if(! this.eventsRendered){
                const ele = this.template.querySelector("div.fullcalendarjs");
                $(ele).fullCalendar('renderEvents', this.events, true);
                this.eventsRendered = true;
            }
        } else if(error) {
            this.events = [];
            this.error = 'No events are found';
        }
   }

   renderedCallback() {
        if (this.fullCalendarJsInitialised) {
            return;
        }
        this.fullCalendarJsInitialised = true;

        Promise.all([
            loadScript(this, FullCalendarJS + "/FullCalendarJS/jquery.min.js"),
            loadScript(this, FullCalendarJS + "/FullCalendarJS/moment.min.js"),
            loadScript(this, FullCalendarJS + "/FullCalendarJS/fullcalendar.min.js"),
            loadStyle(this, FullCalendarJS + "/FullCalendarJS/fullcalendar.min.css"),
        ])
        .then(() => {
            Promise.all([
                loadScript(this, FullCalendarJS + "/FullCalendarJS/locale-all.js")
              ]).then(() => {
                this.initialiseFullCalendarJs();
            });
        })
        .catch((error) => {
            console.error({
                message: "Error occured on FullCalendarJS",
                error,
            });
        });
   }

    initialiseFullCalendarJs() {
        const ele = this.template.querySelector("div.fullcalendarjs");
        const modal = this.template.querySelector('div.modalclass');

        var self = this;

        $(ele).fullCalendar({
            header: {
                left: "prev,next today",
                center: "title",
                right: "month,agendaWeek,agendaDay,listMonth",
            },
            locale: 'ru',
            defaultDate: new Date(),
            defaultView : 'month',
            navLinks: true,
            eventLimit: true,
            views: {
                month: {
                  eventLimit: 2
                }
            },
            events: this.events,
            eventClick: function(event, jsEvent, view) {
                self.handleBtnShow(event.jobStatus);
                self.selectedEvent = event;
                self.jobId = event.id;
                self.jobStart = event.start;
                self.jobEnd = event.end;
                self.openModal = true;
            },
            eventRender: function(event, element) { 
                element.find('.fc-title').append("<br/>" +  event.loc);
            }
        });
    }

    handleClose(event) {
        this.openModal = false;
    }

    handleConfirm(event) {
        this.openModal = false;
        this.openSpinner = true;
        let jobData = {jobId : this.jobId, jobStart : this.jobStart, jobEnd: this.jobEnd};
        confirmCancelJob({'jobData' : JSON.stringify(jobData), 'jobStatus' : 'Cancelled', 'jobNewStatus' : 'Confirmed'})
        .then( result => {
            this.updateSelectedEvent('Confirmed', '#17a317');
            this.openSpinner = false;
        })
        .catch( error => {
            console.log(error);
            this.openSpinner = false;
        });
    }

    handleCancel(event) {
        this.openModal = false;
        this.openSpinner = true;
        let jobData = {jobId : this.jobId, jobStart : this.jobStart, jobEnd: this.jobEnd};
        confirmCancelJob({'jobData' : JSON.stringify(jobData), 'jobStatus' : 'Confirmed', 'jobNewStatus' : 'Cancelled'})
        .then( result => {
            this.updateSelectedEvent('Cancelled', '#ec0202');
            this.openSpinner = false;   
        })
        .catch( error => {
            console.log(error);
            this.openSpinner = false;
        });
    }

    refreshChild(){
        console.log('111' ,this.template.querySelector('c-event-volunteers'));
        this.template.querySelector('c-event-volunteers').childMethod();
    }

    handleBtnShow(status) {
        if (!status) {
            this.btnConfirmVisible = true;
            this.btnCancelVisible = true;
        } else {
            this.btnConfirmVisible = status === 'Cancelled' ? true : false;
            this.btnCancelVisible = status === 'Confirmed' ? true : false;
        }
    }

    updateSelectedEvent(status, color) {
        this.selectedEvent.jobStatus = status;
        this.selectedEvent.color = color;
        const ele = this.template.querySelector("div.fullcalendarjs");
        $(ele).fullCalendar('updateEvent',  this.selectedEvent);
    }

    getEventColor(status) {
        let eventColor;
        if (status === 'Confirmed') {
            eventColor = '#17a317';
        }
        if (status === 'Cancelled') {
            eventColor = '#ec0202';
        }
        return eventColor;
    }

}