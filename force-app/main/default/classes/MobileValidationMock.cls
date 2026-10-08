@isTest
public class MobileValidationMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        
        // Check if the request is for the 'validateMobile' endpoint
        if (req.getEndpoint().contains('validateMobile')) {
            res.setStatusCode(200);  // Successful HTTP status code
            res.setBody('{"status": "Success"}');  // Simulated success response body
        } else {
            res.setStatusCode(500);  // Failure status code
            res.setBody('{"error": {"code": "500", "description": "Internal server error"}}');  // Simulated error response body
        }
        
        res.setHeader('Content-Type', 'application/json');  // Set content type to JSON
        return res;  // Return the mock response
    }
}