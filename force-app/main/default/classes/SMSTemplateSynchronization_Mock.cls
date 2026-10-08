@isTest
global class SMSTemplateSynchronization_Mock implements HttpCalloutMock{
global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
      //  System.assertEquals('https://example.com/example/test', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody('<Sample>');
        res.setStatusCode(200);
        return res;
    }
}