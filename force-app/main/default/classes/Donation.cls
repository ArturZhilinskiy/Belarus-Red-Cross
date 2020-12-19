public with sharing class Donation {   
    
    public List<DonationStaging__c> oneTime { get; set; }
    public List<DonationStaging__c> initiating { get; set; }
    public List<DonationStaging__c> recurring { get; set; }
    
}