public without sharing class VolunteersInvocable {
    @InvocableMethod(
        label = 'Get Volunteers by Ids'
        description = 'Returns Contact records by Ids'
    )
    public static List<Response> getVolunteers(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        Request request = requests[0];
        List<Id> ids = (List<Id>) request.contactsIds;
        List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Id IN :ids];
        Response response = new Response();
        response.volunteers = contacts;
        responses.add(response);

        return responses;
    }

    public class Response {
        @InvocableVariable(
            label = 'Volunteers'
            description = 'Volunteers'
        )
        public List<Contact> volunteers;

    }

    public class Request {
        @InvocableVariable(
            label = 'List of volunteers Ids (List<String>)'
            description = 'Pass list of contacts ids as a List<String>'
            required = true
        )
        public List<String> contactsIds;
    }
}