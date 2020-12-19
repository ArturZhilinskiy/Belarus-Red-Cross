public with sharing class RestClient {
    
    private static Integer TIMEOUT = 120000; 
    
    public static HttpRequest buildRequest(Map<String,String> headers, String url, String method, String body){
        HttpRequest request = new HttpRequest();
        request.setTimeout(TIMEOUT);  
        if (headers != null) {
            for(String hkey : headers.keySet()){
                request.setHeader(hkey, headers.get(hkey)); 
            }   
        }
        request.setEndpoint(url);
        request.setMethod(method);
        if (body != null && body.length() > 0) {
            request.setBody(body);
        }
        return request;
    }
    
    public static HttpResponse makeRequest(Map<String,String> headers, String url, String method, String body) {
        HttpResponse res;
        HttpRequest req = buildRequest(headers, url, method.toUpperCase(), body);
        res = new Http().send(req);
        return res;
    }
    
    public static void response(Integer statusCode, String xml) {
        RestContext.response.statusCode = statusCode;
        RestContext.response.addHeader('Content-Type', 'text/xml');
        RestContext.response.responseBody = Blob.valueOf(xml);
    }
    
    public static String getXMLResponse(){
        String xml = '';
        xml +='<?xml version="1.0" encoding="UTF-8"?>';
        xml +='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">';
        xml +='<SOAP-ENV:Header/>';
        xml +='<SOAP-ENV:Body>';
        xml +='<ns2:NotifierResponse xmlns:ns2="http://ws.webpay.by/notifier">';
        xml +='<ns2:code>200</ns2:code>';
        xml +='<ns2:codeDescription>HTTP/1.0 200 OK</ns2:codeDescription>';
        xml +='</ns2:NotifierResponse>';
        xml +='</SOAP-ENV:Body>';
        xml +='</SOAP-ENV:Envelope>';
        return xml;
    }
    
}