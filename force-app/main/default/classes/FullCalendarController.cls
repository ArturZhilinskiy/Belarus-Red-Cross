public with sharing class FullCalendarController {

    public class EventException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchEvents() {
        List<Map<String, String>> jobsMapList = new List<Map<String, String>>();
        Map<String, String> jobStatusMap = new Map<String, String>();
        Set<String> volunteerSkills = new Set<String>();

        User currUser = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId()];
        String currContactId = currUser.ContactId;
        //String currContactId = '0031s00000ILFr5AAH';

        if(Test.isRunningTest()) {
            Contact testContact = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'John Smith'];
            currContactId = testContact.Id;
        }

        Contact currContact = [
            SELECT 
                Id, 
                Organization__c,
                Region__c,
                City__c,
                District__c,
                City_District__c,
                GW_Volunteers__Volunteer_Skills__c
            FROM 
                Contact 
            WHERE
                Id =: currContactId
        ];

        if (currContact.GW_Volunteers__Volunteer_Skills__c != null) {
            volunteerSkills.addAll(currContact.GW_Volunteers__Volunteer_Skills__c.toLowercase().split(';'));
        }

        List<GW_Volunteers__Volunteer_Hours__c> volunteerHoursList = ([
            SELECT 
                Id,
                GW_Volunteers__Status__c,
                GW_Volunteers__Contact__c,
                GW_Volunteers__Volunteer_Job__c
            FROM
                GW_Volunteers__Volunteer_Hours__c
            WHERE
                GW_Volunteers__Contact__c =: currContact.Id
        ]);

        for (GW_Volunteers__Volunteer_Hours__c h : volunteerHoursList){
            jobStatusMap.put(h.GW_Volunteers__Volunteer_Job__c, h.GW_Volunteers__Status__c);
        }

        List<GW_Volunteers__Volunteer_Job__c> volunteerJobsList = [
            SELECT 
                Id,
                Name,
                Job_Start__c,
                Job_End__c,
                Region__r.Name,
                District__r.Name, 
                City__r.Name,
                City_District__r.Name,
                Street__c,
                Organization__r.Name,
                GW_Volunteers__Skills_Needed__c,
                GW_Volunteers__Description__c
            FROM 
                GW_Volunteers__Volunteer_Job__c 
            WHERE
                GW_Volunteers__Campaign__r.IsActive = true
            AND
                GW_Volunteers__Display_on_Website__c = true
            AND
                Organization__c =: currContact.Organization__c
            AND
                Region__c =: currContact.Region__c
            AND
                City__c =: currContact.City__c
            AND
                District__c =: currContact.District__c
            AND
                City_District__c =: currContact.City_District__c
        ];

        Map<String, String> ladelsMap = new Map<String, String>();
        Map<String, String> skillsPicklistLadelsMap = new Map<String, String>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType jobSchema = schemaMap.get('GW_Volunteers__Volunteer_Job__c');
        Map<String, Schema.SObjectField> jobLabelsMap = jobSchema.getDescribe().fields.getMap();
        for (String fieldName: jobLabelsMap.keySet()) {  
            ladelsMap.put(fieldName, jobLabelsMap.get(fieldName).getDescribe().getLabel() + ': ');
        }
        List<Schema.PicklistEntry> skillsPicklist = jobLabelsMap.get('GW_Volunteers__Skills_Needed__c').getDescribe().getPickListValues();
        for (Schema.PicklistEntry sp : skillsPicklist) {
            skillsPicklistLadelsMap.put(sp.getValue().toLowercase(), sp.getLabel());
         }

        for (GW_Volunteers__Volunteer_Job__c job : volunteerJobsList) {
            String status;
            Boolean haveSkills = false;
            Set<String> skillsNeeded = new Set<String>();

            if (jobStatusMap.containsKey(job.Id)) {
                status = jobStatusMap.get(job.Id);
            }

            if (job.GW_Volunteers__Skills_Needed__c != null) {
                skillsNeeded.addAll(job.GW_Volunteers__Skills_Needed__c.toLowercase().split(';'));
                haveSkills = volunteerSkills.containsAll(skillsNeeded);
            } else {
                haveSkills = true;
            }

            if (haveSkills) {
                String volunteersSkillsNeeded = '';
                for (String sn : skillsNeeded) {
                    volunteersSkillsNeeded += skillsPicklistLadelsMap.get(sn) + '; ';
                }
                
                jobsMapList.add(new Map<String, String>{
                    'id' => job.Id,
                    'name' => job.Name,
                    'start' => string.valueOf(job.Job_Start__c),
                    'end' => string.valueOf(job.Job_End__c),
                    'jobStart' => job.Job_Start__c != null ? ladelsMap.get('job_start__c') + string.valueOf(job.Job_Start__c.format('dd.MM.yyyy HH:mm')) : null,
                    'jobEnd' => job.Job_End__c != null ? ladelsMap.get('job_end__c') + string.valueOf(job.Job_End__c.format('dd.MM.yyyy HH:mm')) : null,
                    'location' => getLocation(job),
                    'region' => job.Region__c != null ? ladelsMap.get('region__c') + job.Region__r.Name : null,
                    'district' => job.District__c != null ? ladelsMap.get('district__c') + job.District__r.Name : null,
                    'city' => job.City__c != null ? ladelsMap.get('city__c') + job.City__r.Name : null,
                    'cityDistrict' => job.City_District__c != null ? ladelsMap.get('city_district__c') + job.City_District__r.Name : null,
                    'street' => job.Street__c != null ? ladelsMap.get('street__c') + job.Street__c : null,
                    'organization' => job.Organization__c != null ? ladelsMap.get('organization__c') + job.Organization__r.Name : null,
                    'description' => job.GW_Volunteers__Description__c != null ? ladelsMap.get('gw_volunteers__description__c') + job.GW_Volunteers__Description__c : null,
                    'skillsNeeded' => job.GW_Volunteers__Skills_Needed__c != null ? ladelsMap.get('gw_volunteers__skills_needed__c') + volunteersSkillsNeeded : null,
                    'status' => status
                });
            }
        }

        return jobsMapList;
    }

    @AuraEnabled(cacheable=true)  
    public static List<GW_Volunteers__Volunteer_Hours__c> findVolunteerHours(String jobId, String status) {  
        String query = 'SELECT Id, GW_Volunteers__Contact__r.Name ';
        query += 'FROM GW_Volunteers__Volunteer_Hours__c ';
        query += 'WHERE GW_Volunteers__Volunteer_Job__c = \'' + jobId + '\' ';
        query += 'AND GW_Volunteers__Status__c = \'' + status + '\' ';
        query += 'LIMIT 100'; 
        return Database.query(query);  
    }

    @AuraEnabled
    public static void confirmCancelJob(String jobData, String jobStatus, String jobNewStatus) {
        User currUser = [SELECT Id, ContactId FROM user WHERE Id =: UserInfo.getUserId()];
        String currContact = currUser.ContactId;
        //String currContact = '0031s00000ILFr5AAH';
        Map<String, Object> jobDatabMap = (Map<String, Object>) JSON.deserializeUntyped(jobData);

        if (Test.isRunningTest()) {
            Contact testContact = [SELECT CustomerId__c, OrderNumber__c FROM Contact WHERE Name = 'John Smith'];
            currContact = testContact.Id;
        }

        GW_Volunteers__Volunteer_Hours__c volunteerHours = getVolunteerHours(currContact, (String) jobDatabMap.get('jobId'));
        if (volunteerHours != null && volunteerHours.GW_Volunteers__Status__c == jobStatus) {
            volunteerHours.GW_Volunteers__Status__c = jobNewStatus;
            update volunteerHours;
        } else {
            GW_Volunteers__Volunteer_Hours__c newVolunteerHours = newVolunteerHours(currContact, jobNewStatus, jobDatabMap);
            insert newVolunteerHours;
        }
    }

    public static String getLocation(GW_Volunteers__Volunteer_Job__c job) {
        String eventLoc = '';
        String separator = ', ';

        // if (job.Region__c != null) {
        //     eventLoc += job.Region__r.Name + separator;
        // }
        if (job.City__c != null) {
            eventLoc += job.City__r.Name + separator;
        }
        // if (job.District__c != null) {
        //     eventLoc += job.District__r.Name + separator;
        // }
        // if (job.City_District__c != null) {
        //     eventLoc += job.City_District__r.Name + separator;
        // }
        if (job.Street__c != null) {
            eventLoc += job.Street__c;
        }
        
        return eventLoc;
    }

    public static GW_Volunteers__Volunteer_Hours__c getVolunteerHours(String currContact, String jobId) {
        GW_Volunteers__Volunteer_Hours__c volunteerHours;
        
        List<GW_Volunteers__Volunteer_Hours__c> volunteerHoursList = ([
            SELECT 
                Id,
                GW_Volunteers__Status__c,
                GW_Volunteers__Contact__c,
                GW_Volunteers__Volunteer_Job__c
            FROM
                GW_Volunteers__Volunteer_Hours__c
            WHERE
                GW_Volunteers__Contact__c =: currContact
            AND 
                GW_Volunteers__Volunteer_Job__c =: jobId
        ]);

        if (!volunteerHoursList.isEmpty()) {
            volunteerHours = volunteerHoursList.get(0);
        }
        
        return volunteerHours;
    }

    public static GW_Volunteers__Volunteer_Hours__c newVolunteerHours(String currContact, String status, Map<String, Object> jobDatabMap) {
       return new GW_Volunteers__Volunteer_Hours__c (
            GW_Volunteers__Volunteer_Job__c = (String) jobDatabMap.get('jobId'),
            GW_Volunteers__Contact__c = currContact,
            GW_Volunteers__Status__c = status,
            GW_Volunteers__Number_of_Volunteers__c = 1,
            GW_Volunteers__Start_Date__c = date.valueOf((String) jobDatabMap.get('jobStart')),
            GW_Volunteers__End_Date__c = date.valueOf((String) jobDatabMap.get('jobEnd'))
        );
    }

}