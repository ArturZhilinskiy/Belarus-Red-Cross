import { LightningElement, track, wire } from 'lwc';

import myContact from "@salesforce/apex/MyProfileController.fetchContact"; 
import updateMyContact from "@salesforce/apex/MyProfileController.updateMyContact"; 
import ID_FIELD from '@salesforce/schema/Contact.Id';
import REGION_FIELD from '@salesforce/schema/Contact.Region__c';
import DISTRICT_FIELD from '@salesforce/schema/Contact.District__c';
import CITY_FIELD from '@salesforce/schema/Contact.City__c';
import CITY_DISTRICT_FIELD from '@salesforce/schema/Contact.City_District__c';
import ADDRESS_FIELD from '@salesforce/schema/Contact.Address__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import MyProfileSaveBtnLabel from '@salesforce/label/c.MyProfileSaveBtnLabel';
import EmptyFieldErrorLabel from '@salesforce/label/c.EmptyFieldErrorLabel';
import MyProfileSuccessLabel from '@salesforce/label/c.MyProfileSuccessLabel';

export default class MyProfile extends LightningElement {

    @track contactId;
    @track contactRecord = {};
    @track contactErrors = {};
    @track selectedLoc = {};
    @track parentObj = {};

    hasError = 'slds-has-error';
    saveBtnLabel = MyProfileSaveBtnLabel;

    @wire(myContact)
    fetchedContact({error, data}){
        if(data){
            this.contactId = data.Id;
            this.contactRecord.organizationName = data.Organization__c ? data.Organization__r.Name : null;
            this.contactRecord.organizationLabel = data.label_organization__c;

            this.parentObj[REGION_FIELD.fieldApiName] = data.Region__c;
            this.contactRecord.regionId = data.Region__c;
            this.contactRecord.regionName = data.Region__c ? data.Region__r.Name : null;
            this.contactRecord.regionLabel = data.label_region__c;

            this.parentObj[DISTRICT_FIELD.fieldApiName] = data.District__c;
            this.contactRecord.districtId = data.District__c;
            this.contactRecord.districtName = data.District__c ? data.District__r.Name : null;
            this.contactRecord.districtLabel = data.label_district__c;

            this.parentObj[CITY_FIELD.fieldApiName] = data.City__c;
            this.contactRecord.cityId = data.City__c;
            this.contactRecord.cityName = data.City__c ? data.City__r.Name : null;
            this.contactRecord.cityLabel = data.label_city__c;

            this.parentObj[CITY_DISTRICT_FIELD.fieldApiName] = data.City_District__c;
            this.contactRecord.cityDistrictId = data.City_District__c;
            this.contactRecord.cityDistrictName = data.City_District__c ? data.City_District__r.Name : null;
            this.contactRecord.cityDistrictLabel = data.label_city_district__c;

            this.contactRecord.address = data.Address__c;
            this.contactRecord.addressLabel = data.label_address__c;
        } else if (error) {
            this.error = error;
        }
    }

    updateContact(){
        let updateContact = true;
        const fields = {};
        const errorFields = [];
        const errorMessage = EmptyFieldErrorLabel;

        const street = this.template.querySelector('.address').value;
        if(this.contactRecord.address !== street) {
            fields[ADDRESS_FIELD.fieldApiName] = street;
        }

        for (const key in this.selectedLoc) {
            fields[key] = this.selectedLoc[key];
            if (this.selectedLoc[key] === null && key !== CITY_DISTRICT_FIELD.fieldApiName) {
                errorFields.push(key);
            }
        }

        if (errorFields.length) {
            updateContact = false;

            let self = this;
            errorFields.forEach(function(field) { 
                self.template.querySelector('.lookup_' + field).classList.add(self.hasError);
                self.contactErrors[field] = errorMessage; 
            });
        }

        if(Object.keys(fields).length !== 0 && updateContact){
            fields[ID_FIELD.fieldApiName] = this.contactId;
            console.log('fields',fields);
            updateMyContact({'fields' : JSON.stringify(fields)})
            .then(result => {
                this.contactRecord.organizationName = result;
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: MyProfileSuccessLabel,
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: error.body.message,
                        variant: 'error'
                    })
                );

                let self = this;
                Object.keys(error.body.output.fieldErrors).forEach(function(field) { 
                    error.body.output.fieldErrors[field].forEach(function(msg) { 
                        self.template.querySelector('.lookup_' + msg.field).classList.add(self.hasError);
                        self.contactErrors[msg.field] = msg.message; 
                    })
                });
            });
        }  
    }

    refreshValues(){
        const inputFields = this.template.querySelectorAll('c-lwc-lookup');
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }

    handleRegionSelected(event) {
        if(this.contactRecord.regionId !== event.detail.selectedRecordId) {
            this.selectedLoc[REGION_FIELD.fieldApiName] = event.detail.selectedRecordId;
            this.parentObj[REGION_FIELD.fieldApiName] = event.detail.selectedRecordId;
            if (event.detail.selectedRecordId !== null){
                this.removeDistrict();
                this.removeCity();
                this.removeCityDistrict();
            }
        }
        this.removeErrorClass(REGION_FIELD.fieldApiName);
    }

    handleDistrictSelected(event) {
        if(this.contactRecord.districtId !== event.detail.selectedRecordId) {
            this.selectedLoc[DISTRICT_FIELD.fieldApiName] = event.detail.selectedRecordId;
            this.parentObj[DISTRICT_FIELD.fieldApiName] = event.detail.selectedRecordId;
            if (event.detail.selectedRecordId !== null){
                this.removeCity();
                this.removeCityDistrict();
            }
        }
        this.removeErrorClass(DISTRICT_FIELD.fieldApiName);
    }

    handleCitySelected(event) {
        if(this.contactRecord.cityId !== event.detail.selectedRecordId) {
            this.selectedLoc[CITY_FIELD.fieldApiName] = event.detail.selectedRecordId;
            this.parentObj[CITY_FIELD.fieldApiName] = event.detail.selectedRecordId;
            if (event.detail.selectedRecordId !== null){
                this.removeCityDistrict();
            }
        }
        this.removeErrorClass(CITY_FIELD.fieldApiName);
    }

    handleCityDistrictSelected(event) {
        if(this.contactRecord.cityDistrictId !== event.detail.selectedRecordId) {
            this.selectedLoc[CITY_DISTRICT_FIELD.fieldApiName] = event.detail.selectedRecordId;
            this.parentObj[CITY_DISTRICT_FIELD.fieldApiName] = event.detail.selectedRecordId;
        }
        this.removeErrorClass(CITY_DISTRICT_FIELD.fieldApiName);
    }

    removeDistrict() {
        this.contactRecord.districtId = null;
        this.contactRecord.districtName = null;
        this.selectedLoc[DISTRICT_FIELD.fieldApiName] = null;
        this.parentObj[DISTRICT_FIELD.fieldApiName] = null;
    }

    removeCity() {
        this.contactRecord.cityId = null;
        this.contactRecord.cityName = null;
        this.selectedLoc[CITY_FIELD.fieldApiName] = null;
        this.parentObj[CITY_FIELD.fieldApiName] = null;
    }

    removeCityDistrict() {
        this.contactRecord.cityDistrictId = null;
        this.contactRecord.cityDistrictName = null;
        this.selectedLoc[CITY_DISTRICT_FIELD.fieldApiName] = null;
        this.parentObj[CITY_DISTRICT_FIELD.fieldApiName] = null;
    }

    removeErrorClass(field) {
        this.contactErrors[field] = null;
        this.template.querySelector('.lookup_' + field).classList.remove(this.hasError);
    }

}