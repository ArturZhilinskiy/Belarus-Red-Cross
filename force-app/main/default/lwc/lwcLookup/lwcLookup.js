import { LightningElement, track, wire, api } from "lwc";  
import findRecords from "@salesforce/apex/MyProfileController.findRecords";  
import MyProfileNoAddressFoundLabel from '@salesforce/label/c.MyProfileNoAddressFoundLabel';
export default class LwcLookup extends LightningElement {  
  @track recordsList;  
  @track searchKey = "";  
  @api selectedValue;  
  @api selectedRecordId;  
  @api objectApiName;  
  @api parentObject;
  @api parentObjectId;
  @api iconName;  
  @api lookupLabel;  
  @track message;  
    
  onLeave(event) {  
   setTimeout(() => {  
    this.searchKey = "";  
    this.recordsList = null;  
   }, 300);  
  }  
    
  onRecordSelection(event) {  
   this.selectedRecordId = event.target.dataset.key;  
   this.selectedValue = event.target.dataset.name;  
   this.searchKey = "";  
   this.onSeletedRecordUpdate();  
  }  
   
  handleKeyChange(event) {  
   const searchKey = event.target.value;  
   this.searchKey = searchKey;  
   this.getLookupResult();  
  }  
   
  removeRecordOnLookup(event) {  
   this.searchKey = "";  
   this.selectedValue = null;  
   this.selectedRecordId = null;  
   this.recordsList = null;  
   this.onSeletedRecordUpdate();  
 }  
   

  getLookupResult() {  
   findRecords({ searchKey: this.searchKey, objectName : this.objectApiName, parentObject: this.parentObject, parentObjectId : this.parentObjectId })  
    .then((result) => {  
     if (result.length===0) {  
       this.recordsList = [];  
       this.message = MyProfileNoAddressFoundLabel;  
      } else {  
       this.recordsList = result;  
       this.message = "";  
      }  
      this.error = undefined;  
    })  
    .catch((error) => {  
     this.error = error;  
     this.recordsList = undefined;  
    });  
  }  
   
  onSeletedRecordUpdate(){  
   const passEventr = new CustomEvent('valueselected', {  
     detail: { selectedRecordId: this.selectedRecordId, selectedValue: this.selectedValue }  
    });  
    this.dispatchEvent(passEventr);  
  }  
 }