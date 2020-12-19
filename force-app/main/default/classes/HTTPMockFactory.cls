@isTest
public with sharing class HTTPMockFactory implements HttpCalloutMock {
    private Integer code;
    private String body;
    private Map<String, String> headers;
    
    public HTTPMockFactory(Integer code, String body, Map<String, String> headers) {
        this.code = code;
        this.body = body;
        this.headers = headers;
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(code);
        resp.setBody(body);
        if (headers != null){
            for (String key : headers.keySet()) {
                resp.setHeader(key, headers.get(key));
            }  
        }
        return resp;
    }
}